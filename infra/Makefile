.PHONY: all
all: generate

.PHONY: plan
plan:
	tofu plan -out tfplan

.PHONY: apply
apply:
	tofu apply tfplan

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
