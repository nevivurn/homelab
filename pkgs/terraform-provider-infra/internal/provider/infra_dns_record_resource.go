package provider

import (
	"context"
	"fmt"
	"strings"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/nevivurn/homelab/pkgs/terraform-provider-infra/internal/pdns"
)

type InfraDNSRecordResource struct {
	pc *pdns.Client
}

type InfraDNSRecordResourceModel struct {
	Zone    types.String `tfsdk:"zone"`
	Name    types.String `tfsdk:"name"`
	Type    types.String `tfsdk:"type"`
	TTL     types.Int32  `tfsdk:"ttl"`
	Records types.Set    `tfsdk:"records"`
}

var (
	_ resource.ResourceWithConfigure   = (*InfraDNSRecordResource)(nil)
	_ resource.ResourceWithImportState = (*InfraDNSRecordResource)(nil)
)

func (r *InfraDNSRecordResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_dns_record"
}

func (r *InfraDNSRecordResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema.Attributes = map[string]schema.Attribute{
		"zone": schema.StringAttribute{
			Required:      true,
			PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()},
		},
		"name": schema.StringAttribute{
			Required:      true,
			PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()},
		},
		"type": schema.StringAttribute{
			Required:      true,
			PlanModifiers: []planmodifier.String{stringplanmodifier.RequiresReplace()},
		},
		"ttl":     schema.Int32Attribute{Required: true},
		"records": schema.SetAttribute{Required: true, ElementType: types.StringType},
	}
}

func (r *InfraDNSRecordResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	cfg, ok := req.ProviderData.(InfraProviderConfig)
	if !ok {
		resp.Diagnostics.AddError("invalid config type", fmt.Sprintf("invalid config type, %T", req.ProviderData))
		return
	}

	r.pc = &pdns.Client{
		BaseURL:    cfg.url + "/pdns",
		HTTPClient: cfg.c,
	}
}

func (r *InfraDNSRecordResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var data InfraDNSRecordResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	records := make([]types.String, 0, len(data.Records.Elements()))
	data.Records.ElementsAs(ctx, &records, false)
	recordVals := make([]pdns.Record, len(records))
	for i, v := range records {
		recordVals[i] = pdns.Record{Content: v.ValueString()}
	}

	err := r.pc.CreateRecord(ctx, data.Zone.ValueString(), pdns.RRSet{
		Name:    data.Name.ValueString(),
		Type:    data.Type.ValueString(),
		TTL:     int(data.TTL.ValueInt32()),
		Records: recordVals,
	})
	if err != nil {
		resp.Diagnostics.AddError("failed creating record", err.Error())
		return
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDNSRecordResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var data InfraDNSRecordResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	rrset, err := r.pc.GetRecord(ctx, data.Zone.ValueString(), data.Name.ValueString(), data.Type.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed reading record", err.Error())
		return
	}

	data.Name = types.StringValue(rrset.Name)
	data.Type = types.StringValue(rrset.Type)
	data.TTL = types.Int32Value(int32(rrset.TTL))

	recordVals := make([]string, len(rrset.Records))
	for i, v := range rrset.Records {
		recordVals[i] = v.Content
	}
	records, diag := types.SetValueFrom(ctx, types.StringType, recordVals)
	resp.Diagnostics.Append(diag...)
	if resp.Diagnostics.HasError() {
		return
	}

	data.Records = records
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDNSRecordResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var data InfraDNSRecordResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	records := make([]types.String, 0, len(data.Records.Elements()))
	data.Records.ElementsAs(ctx, &records, false)
	recordVals := make([]pdns.Record, len(records))
	for i, v := range records {
		recordVals[i] = pdns.Record{Content: v.ValueString()}
	}

	err := r.pc.UpdateRecord(ctx, data.Zone.ValueString(), pdns.RRSet{
		Name:    data.Name.ValueString(),
		Type:    data.Type.ValueString(),
		TTL:     int(data.TTL.ValueInt32()),
		Records: recordVals,
	})
	if err != nil {
		resp.Diagnostics.AddError("failed updating record", err.Error())
		return
	}
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func (r *InfraDNSRecordResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var data InfraDNSRecordResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.pc.DeleteRecord(ctx, data.Zone.ValueString(), data.Name.ValueString(), data.Type.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed deleting record", err.Error())
	}
}

func (r *InfraDNSRecordResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
	parts := strings.Split(req.ID, "/")
	if len(parts) != 3 {
		resp.Diagnostics.AddError("bad import identifier", "expect format ZONE/NAME/TYPE")
		return
	}

	zone, name, typ := parts[0], parts[1], parts[2]

	rrset, err := r.pc.GetRecord(ctx, zone, name, typ)
	if err != nil {
		resp.Diagnostics.AddError("failed reading record", err.Error())
		return
	}

	var data InfraDNSRecordResourceModel
	data.Zone = types.StringValue(zone)
	data.Name = types.StringValue(rrset.Name)
	data.Type = types.StringValue(rrset.Type)
	data.TTL = types.Int32Value(int32(rrset.TTL))

	recordVals := make([]string, len(rrset.Records))
	for i, v := range rrset.Records {
		recordVals[i] = v.Content
	}
	records, diag := types.SetValueFrom(ctx, types.StringType, recordVals)
	resp.Diagnostics.Append(diag...)
	if resp.Diagnostics.HasError() {
		return
	}

	data.Records = records
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func NewInfraDNSRecordResource() resource.Resource {
	return &InfraDNSRecordResource{}
}
