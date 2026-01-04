package provider

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/int32planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/nevivurn/homelab/pkgs/terraform-provider-infra/internal/kea"
)

type InfraDHCP6ReservationResource struct {
	kc *kea.Client
}

type InfraDHCP6ReservationResourceModel struct {
	SubnetID  types.Int32  `tfsdk:"subnet_id"`
	HWAddress types.String `tfsdk:"hw_address"`
	IPAddress types.String `tfsdk:"ip_address"`
	Hostname  types.String `tfsdk:"hostname"`
}

var (
	_ resource.ResourceWithConfigure   = (*InfraDHCP6ReservationResource)(nil)
	_ resource.ResourceWithImportState = (*InfraDHCP6ReservationResource)(nil)
)

func (r *InfraDHCP6ReservationResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_dhcp6_reservation"
}

func (r *InfraDHCP6ReservationResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema.Attributes = map[string]schema.Attribute{
		"subnet_id": schema.Int32Attribute{
			Required:      true,
			PlanModifiers: []planmodifier.Int32{int32planmodifier.RequiresReplace()},
		},
		"hw_address": schema.StringAttribute{
			Required:      true,
			PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()},
		},
		"ip_address": schema.StringAttribute{Required: true},
		"hostname":   schema.StringAttribute{Optional: true},
	}
}

func (r *InfraDHCP6ReservationResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	cfg, ok := req.ProviderData.(InfraProviderConfig)
	if !ok {
		resp.Diagnostics.AddError("invalid config type", fmt.Sprintf("invalid config type, %T", req.ProviderData))
		return
	}

	r.kc = &kea.Client{
		BaseURL:    cfg.url + "/kea",
		HTTPClient: cfg.c,
	}
}

func (r *InfraDHCP6ReservationResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data InfraDHCP6ReservationResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	reservation := kea.Reservation6{
		SubnetID:    int(data.SubnetID.ValueInt32()),
		HWAddress:   data.HWAddress.ValueString(),
		IPAddresses: []string{data.IPAddress.ValueString()},
		Hostname:    data.Hostname.ValueString(),
	}

	err := r.kc.AddReservation6(ctx, reservation)
	if err != nil {
		resp.Diagnostics.AddError("failed creating reservation", err.Error())
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDHCP6ReservationResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data InfraDHCP6ReservationResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	reservation, err := r.kc.GetReservation6(ctx, int(data.SubnetID.ValueInt32()), data.HWAddress.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed reading reservation", err.Error())
		return
	}

	data.SubnetID = types.Int32Value(int32(reservation.SubnetID))
	data.HWAddress = types.StringValue(reservation.HWAddress)
	if len(reservation.IPAddresses) > 0 {
		data.IPAddress = types.StringValue(reservation.IPAddresses[0])
	}
	if reservation.Hostname != "" {
		data.Hostname = types.StringValue(reservation.Hostname)
	} else {
		data.Hostname = types.StringNull()
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDHCP6ReservationResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var data InfraDHCP6ReservationResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	reservation := kea.Reservation6{
		SubnetID:    int(data.SubnetID.ValueInt32()),
		HWAddress:   data.HWAddress.ValueString(),
		IPAddresses: []string{data.IPAddress.ValueString()},
		Hostname:    data.Hostname.ValueString(),
	}

	err := r.kc.UpdateReservation6(ctx, reservation)
	if err != nil {
		resp.Diagnostics.AddError("failed updating reservation", err.Error())
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDHCP6ReservationResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data InfraDHCP6ReservationResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.kc.DelReservation6(ctx, int(data.SubnetID.ValueInt32()), data.HWAddress.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed deleting reservation", err.Error())
	}
}

func (r *InfraDHCP6ReservationResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	parts := strings.Split(req.ID, "/")
	if len(parts) != 2 {
		resp.Diagnostics.AddError("bad import identifier", "expect format SUBNET_ID/HW_ADDRESS")
		return
	}

	subnetID, err := strconv.ParseInt(parts[0], 10, 32)
	if err != nil {
		resp.Diagnostics.AddError("bad import identifier", "subnet_id must be an integer")
		return
	}
	hwAddress := parts[1]

	reservation, err := r.kc.GetReservation6(ctx, int(subnetID), hwAddress)
	if err != nil {
		resp.Diagnostics.AddError("failed reading reservation", err.Error())
		return
	}

	var data InfraDHCP6ReservationResourceModel
	data.SubnetID = types.Int32Value(int32(reservation.SubnetID))
	data.HWAddress = types.StringValue(reservation.HWAddress)
	if len(reservation.IPAddresses) > 0 {
		data.IPAddress = types.StringValue(reservation.IPAddresses[0])
	}
	if reservation.Hostname != "" {
		data.Hostname = types.StringValue(reservation.Hostname)
	} else {
		data.Hostname = types.StringNull()
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func NewInfraDHCP6ReservationResource() resource.Resource {
	return &InfraDHCP6ReservationResource{}
}
