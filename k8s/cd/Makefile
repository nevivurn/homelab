CLUSTERS := capi c20

.PHONY: all
all: generate

.PHONY: generate
generate: $(CLUSTERS)
	cd homelab-cd; nix run

.PHONY: clean
clean:
	rm -rf homelab-cd/manifests

.PHONY: $(CLUSTERS)
$(CLUSTERS): clean
	helmfile template --include-crds -e $@ --output-dir $$(pwd)/homelab-cd/manifests/$@ --output-dir-template '{{ .OutputDir }}/{{ .Release.Name }}'
