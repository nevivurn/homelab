.PHONY: all
all: result

.PHONY: clean
clean:
	rm -f result

.PHONY: result
result:
	nix build .#vyos-configs
