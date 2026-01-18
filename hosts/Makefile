.PHONY: all
all: generate

.PHONY: generate
generate: hosts.zone

.PHONY: hosts.zone
hosts.zone:
	ln -sf $$(nix build .#hosts --no-link --print-out-paths)/hosts.zone .
