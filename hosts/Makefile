.PHONY: all
all: generate

.PHONY: generate
generate: hosts.zone private.zone

.PHONY: hosts.zone
hosts.zone:
	nix build .#hosts -o hosts.zone

private.zone: private.zone.sops
	sops decrypt $^ > $@
