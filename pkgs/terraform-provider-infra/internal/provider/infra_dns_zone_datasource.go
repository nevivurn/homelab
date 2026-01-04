package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/nevivurn/homelab/pkgs/terraform-provider-infra/internal/pdns"
)

type InfraDNSZoneDataSource struct {
	pc *pdns.Client
}

type InfraDNSZoneDataSourceModel struct {
	Name        types.String `tfsdk:"name"`
	DNSSEC      types.Bool   `tfsdk:"dnssec"`
	NSEC3PARAM  types.String `tfsdk:"nsec3param"`
	NSEC3Narrow types.Bool   `tfsdk:"nsec3narrow"`
}

var _ datasource.DataSourceWithConfigure = (*InfraDNSZoneDataSource)(nil)

func (d *InfraDNSZoneDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_dns_zone"
}

func (d *InfraDNSZoneDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema.Attributes = map[string]schema.Attribute{
		"name":        schema.StringAttribute{Required: true},
		"dnssec":      schema.BoolAttribute{Computed: true},
		"nsec3param":  schema.StringAttribute{Computed: true},
		"nsec3narrow": schema.BoolAttribute{Computed: true},
	}
}

func (d *InfraDNSZoneDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	cfg, ok := req.ProviderData.(InfraProviderConfig)
	if !ok {
		resp.Diagnostics.AddError("invalid config type", fmt.Sprintf("invalid config type, %T %#v", req.ProviderData, req.ProviderData))
		return
	}

	d.pc = &pdns.Client{
		BaseURL:    cfg.url + "/pdns",
		HTTPClient: cfg.c,
	}
}

func (d *InfraDNSZoneDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data InfraDNSZoneDataSourceModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	zone, err := d.pc.GetZone(ctx, data.Name.ValueString())
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

func NewInfraDNSZoneDataSource() datasource.DataSource {
	return &InfraDNSZoneDataSource{}
}
