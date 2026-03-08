kustomizations := $(wildcard */kustomization.yaml)
targets := $(kustomizations:kustomization.yaml=build.yaml)

.PHONY: build
build: $(targets)

.PHONY: clean
clean:
	rm -f */secrets.yaml */build.yaml

%/build.yaml: %/secrets.yaml
	kustomize build $(dir $@) > $@

%/secrets.yaml:
	sops decrypt pve-auth.sops.yaml | yq '.metadata.name |= "$*-pve-auth"' > $@
