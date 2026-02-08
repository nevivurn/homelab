.PHONY: all
all: generate

.PHONY: clean
clean:
	rm -rf results fetched

.PHONY: generate
generate: results fetched/rtr01.rtr.nevi.network fetched/rtr02.rtr.nevi.network

.PHONY: results
results:
	nix build .#vyos-configs

fetched/%:
	mkdir -p fetched
	./scripts/fetch-config.sh $* > $@
