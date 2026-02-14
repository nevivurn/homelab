.PHONY: all
all: generate

.PHONY: lint
lint:
	tofu fmt -check
	tofu validate

.PHONY: generate
generate:
	$(MAKE) -C data

.PHONY: outputs.json
outputs.json:
	tofu output -json > $@
