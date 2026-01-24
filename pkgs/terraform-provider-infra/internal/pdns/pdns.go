package pdns

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sync"
)

type Client struct {
	BaseURL    string
	HTTPClient *http.Client
}

// pdns is not quite concurrency-safe, just globally lock everything.
var mu sync.Mutex

func request(ctx context.Context, c *Client, method, path string, query url.Values, reqBody any) (*http.Response, error) {
	if method != http.MethodGet {
		mu.Lock()
		defer mu.Unlock()
	}

	reqURL, err := url.JoinPath(c.BaseURL, APIPrefix, path)
	if err != nil {
		return nil, fmt.Errorf("failed creating request: %w", err)
	}
	if q := query.Encode(); q != "" {
		reqURL += "?" + q
	}

	var body io.Reader
	if reqBody != nil {
		data, err := json.Marshal(reqBody)
		if err != nil {
			return nil, fmt.Errorf("failed creating request: %w", err)
		}
		body = bytes.NewReader(data)
	}

	req, err := http.NewRequestWithContext(ctx, method, reqURL, body)
	if err != nil {
		return nil, fmt.Errorf("failed creating request: %w", err)
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed request: %w", err)
	}

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		body, _ := io.ReadAll(resp.Body)
		_ = resp.Body.Close()
		return nil, fmt.Errorf("unexpected response status: %s: %s", resp.Status, body)
	}

	return resp, nil
}

func requestEmpty(ctx context.Context, c *Client, method, path string, query url.Values, reqBody any) error {
	resp, err := request(ctx, c, method, path, query, reqBody)
	if err != nil {
		return err
	}
	_ = resp.Body.Close()
	return nil
}

func requestDecode[T any](ctx context.Context, c *Client, method, path string, query url.Values, reqBody any) (T, error) {
	var val T

	resp, err := request(ctx, c, method, path, query, reqBody)
	if err != nil {
		return val, err
	}

	dec := json.NewDecoder(resp.Body)
	if err := dec.Decode(&val); err != nil {
		return val, fmt.Errorf("failed reading request: %w", err)
	}
	if dec.More() {
		return val, errors.New("failed reading request: invalid trailing data")
	}

	return val, nil
}

func (c *Client) CreateZone(ctx context.Context, zoneName Zone) error {
	zoneName.Kind = "Native"
	_, err := requestDecode[Zone](ctx, c, http.MethodPost, "zones", nil, zoneName)
	return err
}

func (c *Client) GetZone(ctx context.Context, zoneName string) (Zone, error) {
	return requestDecode[Zone](ctx, c, http.MethodGet, fmt.Sprintf("zones/%s", zoneName), nil, nil)
}

func (c *Client) UpdateZone(ctx context.Context, zoneName Zone) error {
	return requestEmpty(ctx, c, http.MethodPut, fmt.Sprintf("zones/%s", zoneName.Name), nil, zoneName)
}

func (c *Client) DeleteZone(ctx context.Context, zoneName string) error {
	return requestEmpty(ctx, c, http.MethodDelete, fmt.Sprintf("zones/%s", zoneName), nil, nil)
}

func (c *Client) CreateRecord(ctx context.Context, zoneName string, rec RRSet) error {
	rec.ChangeType = ChangeReplace
	return requestEmpty(ctx, c, http.MethodPatch, fmt.Sprintf("zones/%s", zoneName), nil, Zone{RRSets: []RRSet{rec}})
}

func (c *Client) GetRecord(ctx context.Context, zoneName, name, typ string) (RRSet, error) {
	q := url.Values{}
	q.Add("rrset_name", name)
	q.Add("rrset_type", typ)
	zone, err := requestDecode[Zone](ctx, c, http.MethodGet, fmt.Sprintf("zones/%s", zoneName), q, nil)
	if err != nil {
		return RRSet{}, err
	}

	if len(zone.RRSets) != 1 {
		return RRSet{}, errors.New("rrset not found")
	}

	return zone.RRSets[0], nil
}

func (c *Client) UpdateRecord(ctx context.Context, zone string, rec RRSet) error {
	return c.CreateRecord(ctx, zone, rec)
}

func (c *Client) DeleteRecord(ctx context.Context, zoneName, name, typ string) error {
	return requestEmpty(ctx, c, http.MethodPatch, fmt.Sprintf("zones/%s", zoneName), nil, Zone{RRSets: []RRSet{{
		Name:       name,
		Type:       typ,
		ChangeType: ChangeDelete,
	}}})
}

func (c *Client) GetCryptokeys(ctx context.Context, zoneName string) ([]Cryptokey, error) {
	return requestDecode[[]Cryptokey](ctx, c, http.MethodGet, fmt.Sprintf("zones/%s/cryptokeys", zoneName), nil, nil)
}
