.PHONY: all
all: generate

.PHONY: generate
generate: hosts.zone

.PHONY: hosts.zone
hosts.zone:
	nix build .#hosts -o hosts.zone
