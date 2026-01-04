package provider

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"net/http"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type InfraProvider struct {
}

type InfraProviderConfig struct {
	url string
	c   *http.Client
}

func (p *InfraProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "infra"
}

func (p *InfraProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema.Attributes = map[string]schema.Attribute{
		"url":     schema.StringAttribute{Required: true},
		"ca_crt":  schema.StringAttribute{Required: true},
		"tls_crt": schema.StringAttribute{Required: true},
		"tls_key": schema.StringAttribute{Required: true},
	}
}

func (p *InfraProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	type infraProviderModel struct {
		URL    types.String `tfsdk:"url"`
		CACrt  types.String `tfsdk:"ca_crt"`
		TLSCrt types.String `tfsdk:"tls_crt"`
		TLSKey types.String `tfsdk:"tls_key"`
	}
	var data infraProviderModel

	resp.Diagnostics.Append(req.Config.Get(ctx, &data)...)
	if resp.Diagnostics.HasError() {
		return
	}

	caCrtData, err := os.ReadFile(data.CACrt.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed init tls", err.Error())
		return
	}

	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(caCrtData) {
		resp.Diagnostics.AddError("failed init tls", "failed adding to pool")
		return
	}

	tlsCert, err := tls.LoadX509KeyPair(data.TLSCrt.ValueString(), data.TLSKey.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("failed init tls", err.Error())
		return
	}

	cfg := InfraProviderConfig{
		url: data.URL.ValueString(),
		c: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{
					RootCAs:      pool,
					Certificates: []tls.Certificate{tlsCert},
				},
			},
		},
	}

	resp.ResourceData = cfg
	resp.DataSourceData = cfg
}

func (p *InfraProvider) DataSources(context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewInfraDNSRecordDataSource,
		NewInfraDNSZoneDataSource,
		NewInfraDNSZoneDSDataSource,
	}
}

func (p *InfraProvider) Resources(context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewInfraDNSRecordResource,
		NewInfraDNSZoneResource,
		NewInfraDHCP4ReservationResource,
		NewInfraDHCP6ReservationResource,
	}
}

func New() provider.Provider {
	return &InfraProvider{}
}
