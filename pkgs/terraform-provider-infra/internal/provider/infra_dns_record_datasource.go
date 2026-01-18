package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/nevivurn/homelab/pkgs/terraform-provider-infra/internal/pdns"
)

type InfraDNSRecordDataSource struct {
	pc *pdns.Client
}

type InfraDNSRecordDataSourceModel struct {
	Zone    types.String `tfsdk:"zone"`
	Name    types.String `tfsdk:"name"`
	Type    types.String `tfsdk:"type"`
	TTL     types.Int32  `tfsdk:"ttl"`
	Records types.Set    `tfsdk:"records"`
}

var _ datasource.DataSourceWithConfigure = (*InfraDNSRecordDataSource)(nil)

func (d *InfraDNSRecordDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_dns_record"
}

func (d *InfraDNSRecordDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema.Attributes = map[string]schema.Attribute{
		"zone":    schema.StringAttribute{Required: true},
		"name":    schema.StringAttribute{Required: true},
		"type":    schema.StringAttribute{Required: true},
		"ttl":     schema.Int32Attribute{Computed: true},
		"records": schema.SetAttribute{Computed: true, ElementType: types.StringType},
	}
}

func (d *InfraDNSRecordDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	cfg, ok := req.ProviderData.(InfraProviderConfig)
	if !ok {
		resp.Diagnostics.AddError("invalid config type", fmt.Sprintf("invalid config type, %T", req.ProviderData))
		return
	}

	d.pc = &pdns.Client{
		BaseURL:    cfg.url + "/pdns",
		HTTPClient: cfg.c,
	}
}

func (d *InfraDNSRecordDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data InfraDNSRecordDataSourceModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	rrset, err := d.pc.GetRecord(ctx, data.Zone.ValueString(), data.Name.ValueString(), data.Type.ValueString())
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
	data.Records = records
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func NewInfraDNSRecordDataSource() datasource.DataSource {
	return &InfraDNSRecordDataSource{}
}
