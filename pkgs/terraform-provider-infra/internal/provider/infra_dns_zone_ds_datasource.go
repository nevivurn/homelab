package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"

	"github.com/nevivurn/homelab/pkgs/terraform-provider-infra/internal/pdns"
)

type InfraDNSZoneDSDataSource struct {
	pc *pdns.Client
}

type InfraDNSZoneDSDataSourceModel struct {
	Zone types.String `tfsdk:"zone"`
	DS   types.List   `tfsdk:"ds"`
}

var _ datasource.DataSourceWithConfigure = (*InfraDNSZoneDSDataSource)(nil)

func (d *InfraDNSZoneDSDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_dns_zone_ds"
}

func (d *InfraDNSZoneDSDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema.Attributes = map[string]schema.Attribute{
		"zone": schema.StringAttribute{Required: true},
		"ds":   schema.ListAttribute{Computed: true, ElementType: types.StringType},
	}
}

func (d *InfraDNSZoneDSDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
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

func (d *InfraDNSZoneDSDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data InfraDNSZoneDSDataSourceModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	cryptokeys, err := d.pc.GetCryptokeys(ctx, data.Zone.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed reading cryptokeys", err.Error())
		return
	}

	var dsRecords []string
	for _, ck := range cryptokeys {
		dsRecords = append(dsRecords, ck.DS...)
	}

	ds, diag := types.ListValueFrom(ctx, types.StringType, dsRecords)
	resp.Diagnostics.Append(diag...)
	if resp.Diagnostics.HasError() {
		return
	}

	data.DS = ds
	resp.Diagnostics.Append(resp.State.Set(ctx, &data)...)
}

func NewInfraDNSZoneDSDataSource() datasource.DataSource {
	return &InfraDNSZoneDSDataSource{}
}
