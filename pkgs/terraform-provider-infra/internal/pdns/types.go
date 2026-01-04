package pdns

// ref: https://doc.powerdns.com/authoritative/http-api/zone.html#objects

const APIPrefix = "api/v1/servers/localhost"

type Zone struct {
	Name   string  `json:"name"`
	Kind   string  `json:"kind,omitempty"`
	RRSets []RRSet `json:"rrsets,omitempty"`

	DNSSEC      bool   `json:"dnssec"`
	NSEC3PARAM  string `json:"nsec3param,omitempty"`
	NSEC3Narrow bool   `json:"nsec3narrow"`
}

type RRSet struct {
	Name       string     `json:"name"`
	Type       string     `json:"type"`
	TTL        int        `json:"ttl"`
	ChangeType ChangeType `json:"changetype"`
	Records    []Record   `json:"records"`
}

type ChangeType string

const (
	ChangeDelete  ChangeType = "DELETE"
	ChangeReplace ChangeType = "REPLACE"
)

type Record struct {
	Content string `json:"content"`
}

type Cryptokey struct {
	DS []string `json:"ds"`
}
