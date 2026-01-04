package kea

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
)

type Client struct {
	BaseURL    string
	HTTPClient *http.Client
}

func request[Req, Resp any](ctx context.Context, c *Client, endpoint string, req Request[Req]) (Response[Resp], error) {
	reqURL := c.BaseURL + endpoint

	data, err := json.Marshal(req)
	if err != nil {
		return Response[Resp]{}, fmt.Errorf("failed creating request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, reqURL, bytes.NewReader(data))
	if err != nil {
		return Response[Resp]{}, fmt.Errorf("failed creating request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := c.HTTPClient.Do(httpReq)
	if err != nil {
		return Response[Resp]{}, fmt.Errorf("failed request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode > 299 {
		body, _ := io.ReadAll(resp.Body)
		return Response[Resp]{}, fmt.Errorf("unexpected response status: %s: %s", resp.Status, body)
	}

	var responses []Response[Resp]
	dec := json.NewDecoder(resp.Body)
	if err := dec.Decode(&responses); err != nil {
		return Response[Resp]{}, fmt.Errorf("failed reading response: %w", err)
	}
	if dec.More() {
		return Response[Resp]{}, errors.New("failed reading response: invalid trailing data")
	}

	if len(responses) != 1 {
		return Response[Resp]{}, fmt.Errorf("unexpected response length: %d", len(responses))
	}

	return responses[0], nil
}

// DHCPv4 methods

func (c *Client) AddReservation4(ctx context.Context, reservation Reservation4) error {
	resp, err := request[ReservationAddArgs[Reservation4], struct{}](ctx, c, "/dhcp4/", Request[ReservationAddArgs[Reservation4]]{
		Command:   "reservation-add",
		Arguments: ReservationAddArgs[Reservation4]{Reservation: reservation},
	})
	if err != nil {
		return err
	}
	if resp.Result != 0 {
		return fmt.Errorf("reservation-add failed: %s", resp.Text)
	}
	return nil
}

func (c *Client) GetReservation4(ctx context.Context, subnetID int, hwAddress string) (Reservation4, error) {
	resp, err := request[ReservationGetDelArgs, Reservation4](ctx, c, "/dhcp4/", Request[ReservationGetDelArgs]{
		Command: "reservation-get",
		Arguments: ReservationGetDelArgs{
			SubnetID:       subnetID,
			IdentifierType: "hw-address",
			Identifier:     hwAddress,
		},
	})
	if err != nil {
		return Reservation4{}, err
	}
	if resp.Result != 0 {
		return Reservation4{}, fmt.Errorf("reservation-get failed: %s", resp.Text)
	}
	return resp.Arguments, nil
}

func (c *Client) UpdateReservation4(ctx context.Context, reservation Reservation4) error {
	resp, err := request[ReservationAddArgs[Reservation4], struct{}](ctx, c, "/dhcp4/", Request[ReservationAddArgs[Reservation4]]{
		Command:   "reservation-update",
		Arguments: ReservationAddArgs[Reservation4]{Reservation: reservation},
	})
	if err != nil {
		return err
	}
	if resp.Result != 0 {
		return fmt.Errorf("reservation-add failed: %s", resp.Text)
	}
	return nil
}

func (c *Client) DelReservation4(ctx context.Context, subnetID int, hwAddress string) error {
	resp, err := request[ReservationGetDelArgs, struct{}](ctx, c, "/dhcp4/", Request[ReservationGetDelArgs]{
		Command: "reservation-del",
		Arguments: ReservationGetDelArgs{
			SubnetID:       subnetID,
			IdentifierType: "hw-address",
			Identifier:     hwAddress,
		},
	})
	if err != nil {
		return err
	}
	if resp.Result != 0 && resp.Result != 3 {
		return fmt.Errorf("reservation-del failed: %s", resp.Text)
	}
	return nil
}

// DHCPv6 methods

func (c *Client) AddReservation6(ctx context.Context, reservation Reservation6) error {
	resp, err := request[ReservationAddArgs[Reservation6], struct{}](ctx, c, "/dhcp6/", Request[ReservationAddArgs[Reservation6]]{
		Command:   "reservation-add",
		Arguments: ReservationAddArgs[Reservation6]{Reservation: reservation},
	})
	if err != nil {
		return err
	}
	if resp.Result != 0 {
		return fmt.Errorf("reservation-add failed: %s", resp.Text)
	}
	return nil
}

func (c *Client) GetReservation6(ctx context.Context, subnetID int, hwAddress string) (Reservation6, error) {
	resp, err := request[ReservationGetDelArgs, Reservation6](ctx, c, "/dhcp6/", Request[ReservationGetDelArgs]{
		Command: "reservation-get",
		Arguments: ReservationGetDelArgs{
			SubnetID:       subnetID,
			IdentifierType: "hw-address",
			Identifier:     hwAddress,
		},
	})
	if err != nil {
		return Reservation6{}, err
	}
	if resp.Result != 0 {
		return Reservation6{}, fmt.Errorf("reservation-get failed: %s", resp.Text)
	}
	return resp.Arguments, nil
}

func (c *Client) UpdateReservation6(ctx context.Context, reservation Reservation6) error {
	resp, err := request[ReservationAddArgs[Reservation6], struct{}](ctx, c, "/dhcp6/", Request[ReservationAddArgs[Reservation6]]{
		Command:   "reservation-update",
		Arguments: ReservationAddArgs[Reservation6]{Reservation: reservation},
	})
	if err != nil {
		return err
	}
	if resp.Result != 0 {
		return fmt.Errorf("reservation-add failed: %s", resp.Text)
	}
	return nil
}

func (c *Client) DelReservation6(ctx context.Context, subnetID int, hwAddress string) error {
	resp, err := request[ReservationGetDelArgs, struct{}](ctx, c, "/dhcp6/", Request[ReservationGetDelArgs]{
		Command: "reservation-del",
		Arguments: ReservationGetDelArgs{
			SubnetID:       subnetID,
			IdentifierType: "hw-address",
			Identifier:     hwAddress,
		},
	})
	if err != nil {
		return err
	}
	if resp.Result != 0 && resp.Result != 3 {
		return fmt.Errorf("reservation-del failed: %s", resp.Text)
	}
	return nil
}
