.PHONY: all
all: generate

.PHONY: clean
clean:
	rm -rf result fetched

.PHONY: generate
generate: result fetched/rtr01.home.nevi.network fetched/rtr02.home.nevi.network

.PHONY: result
result:
	nix build .#vyos-configs

fetched/%:
	mkdir -p fetched
	./scripts/fetch-config.sh $* > $@
