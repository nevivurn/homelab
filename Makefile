.PHONY: lint
lint: lint-ansible lint-infra lint-pkgs lint-nix

.PHONY: lint-ansible
lint-ansible:
	$(MAKE) -C ansible lint

.PHONY: lint-infra
lint-infra:
	$(MAKE) -C infra lint

.PHONY: lint-pkgs
lint-pkgs:
	$(MAKE) -C pkgs lint

.PHONY: lint-nix
lint-nix:
	nix fmt -- --ci
