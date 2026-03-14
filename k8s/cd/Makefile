CLUSTERS := capi c20 c30

.PHONY: all
all: clean generate

.PHONY: generate
generate: $(CLUSTERS)

.PHONY: clean
clean:
	rm -rf homelab-cd/manifests

.PHONY: $(CLUSTERS)
$(CLUSTERS):
	helmfile template -e $@ --output-dir $$(pwd)/homelab-cd/manifests/$@ --output-dir-template '{{ .OutputDir }}/{{ .Release.Name }}'
