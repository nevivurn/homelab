.PHONY: all
all: generate

.PHONY: clean
clean:
	$(MAKE) -C vyos clean

.PHONY: lint
lint:
	ansible-lint -s
	$(MAKE) -C vyos lint

.PHONY: generate
generate: files/infra_zones.json vyos-diff

.PHONY: ../infra/outputs.json
../infra/outputs.json:
	$(MAKE) -C ../infra outputs.json

files/infra_zones.json: ../infra/outputs.json
	jq '.fwd_root_ds.value | with_entries(.key |= rtrimstr("."))' $< > $@

.PHONY: vyos-fetch
vyos-fetch:
	$(MAKE) -C vyos fetch

.PHONY: vyos-diff
vyos-diff:
	$(MAKE) -C vyos diff
