.PHONY: all
all: files/infra_zones.json

.PHONY: ../infra/outputs.json
../infra/outputs.json:
	$(MAKE) -C ../infra outputs.json

files/infra_zones.json: ../infra/outputs.json
	jq '.fwd_root_ds.value | with_entries(.key |= rtrimstr("."))' $< > $@
