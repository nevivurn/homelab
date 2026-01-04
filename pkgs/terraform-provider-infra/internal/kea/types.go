package kea

type Request[A any] struct {
	Command   string `json:"command"`
	Arguments A      `json:"arguments"`
}

type Response[A any] struct {
	Result    int    `json:"result"`
	Text      string `json:"text"`
	Arguments A      `json:"arguments,omitempty"`
}

type Reservation interface {
	Reservation4 | Reservation6
}

type ReservationAddArgs[R Reservation] struct {
	Reservation R `json:"reservation"`
}

type ReservationGetDelArgs struct {
	SubnetID       int    `json:"subnet-id"`
	IdentifierType string `json:"identifier-type"`
	Identifier     string `json:"identifier"`
}

type Reservation4 struct {
	SubnetID  int    `json:"subnet-id"`
	HWAddress string `json:"hw-address"`
	IPAddress string `json:"ip-address"`
	Hostname  string `json:"hostname,omitempty"`
}

type Reservation6 struct {
	SubnetID    int      `json:"subnet-id"`
	HWAddress   string   `json:"hw-address"`
	IPAddresses []string `json:"ip-addresses"`
	Hostname    string   `json:"hostname,omitempty"`
}
