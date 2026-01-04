package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/nevivurn/homelab/pkgs/terraform-provider-infra/internal/pdns"
)

type InfraDNSZoneResource struct {
	pc *pdns.Client
}

type InfraDNSZoneResourceModel struct {
	Name        types.String `tfsdk:"name"`
	DNSSEC      types.Bool   `tfsdk:"dnssec"`
	NSEC3PARAM  types.String `tfsdk:"nsec3param"`
	NSEC3Narrow types.Bool   `tfsdk:"nsec3narrow"`
}

var (
	_ resource.ResourceWithConfigure   = (*InfraDNSZoneResource)(nil)
	_ resource.ResourceWithImportState = (*InfraDNSZoneResource)(nil)
)

func (r *InfraDNSZoneResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_dns_zone"
}

func (r *InfraDNSZoneResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema.Attributes = map[string]schema.Attribute{
		"name": schema.StringAttribute{
			Required:      true,
			PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()},
		},
		"dnssec":      schema.BoolAttribute{Required: true},
		"nsec3param":  schema.StringAttribute{Optional: true},
		"nsec3narrow": schema.BoolAttribute{Required: true},
	}
}

func (r *InfraDNSZoneResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	cfg, ok := req.ProviderData.(InfraProviderConfig)
	if !ok {
		resp.Diagnostics.AddError("invalid config type", fmt.Sprintf("invalid config type, %T %#v", req.ProviderData, req.ProviderData))
		return
	}

	r.pc = &pdns.Client{
		BaseURL:    cfg.url + "/pdns",
		HTTPClient: cfg.c,
	}
}

func (r *InfraDNSZoneResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data InfraDNSZoneResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	zone := pdns.Zone{
		Name:        data.Name.ValueString(),
		DNSSEC:      data.DNSSEC.ValueBool(),
		NSEC3PARAM:  data.NSEC3PARAM.ValueString(),
		NSEC3Narrow: data.NSEC3Narrow.ValueBool(),
	}

	err := r.pc.CreateZone(ctx, zone)
	if err != nil {
		resp.Diagnostics.AddError("failed creating zone", err.Error())
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDNSZoneResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data InfraDNSZoneResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	zone, err := r.pc.GetZone(ctx, data.Name.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed reading zone", err.Error())
		return
	}

	data.Name = types.StringValue(zone.Name)
	data.DNSSEC = types.BoolValue(zone.DNSSEC)
	data.NSEC3PARAM = types.StringValue(zone.NSEC3PARAM)
	data.NSEC3Narrow = types.BoolValue(zone.NSEC3Narrow)
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDNSZoneResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var data InfraDNSZoneResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	zone := pdns.Zone{
		Name:        data.Name.ValueString(),
		DNSSEC:      data.DNSSEC.ValueBool(),
		NSEC3PARAM:  data.NSEC3PARAM.ValueString(),
		NSEC3Narrow: data.NSEC3Narrow.ValueBool(),
	}

	err := r.pc.UpdateZone(ctx, zone)
	if err != nil {
		resp.Diagnostics.AddError("failed updating zone", err.Error())
		return
	}
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDNSZoneResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data InfraDNSZoneResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.pc.DeleteZone(ctx, data.Name.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed deleting zone", err.Error())
	}
}

func (r *InfraDNSZoneResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	zoneName := req.ID

	zone, err := r.pc.GetZone(ctx, zoneName)
	if err != nil {
		resp.Diagnostics.AddError("failed reading zone", err.Error())
		return
	}

	var data InfraDNSZoneResourceModel
	data.Name = types.StringValue(zone.Name)
	data.DNSSEC = types.BoolValue(zone.DNSSEC)
	data.NSEC3PARAM = types.StringValue(zone.NSEC3PARAM)
	data.NSEC3Narrow = types.BoolValue(zone.NSEC3Narrow)
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func NewInfraDNSZoneResource() resource.Resource {
	return &InfraDNSZoneResource{}
}
