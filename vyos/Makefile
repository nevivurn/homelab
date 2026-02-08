.PHONY: all
all: generate

.PHONY: clean
clean:
	rm -rf result fetched

.PHONY: generate
generate: result fetched/rtr01.rtr.nevi.network fetched/rtr02.rtr.nevi.network

.PHONY: result
result:
	nix build .#vyos-configs

fetched/%:
	mkdir -p fetched
	./scripts/fetch-config.sh $* > $@
