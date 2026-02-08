export TALOS_VERSION ?= v1.12.3
CLUSTER_NAME ?= k8s1
CLUSTER_ENDPOINT ?= https://k8s1.k8s.nevi.network
TALOS_ENDPOINT ?= k8s1-masters.k8s.nevi.network
TALOS_NODE ?= 10.64.30.11

PREFIX := _out
CONFIG_SECRETS := $(PREFIX)/secrets.yaml
CONFIG_CONTROLPLANE := $(PREFIX)/controlplane.yaml
CONFIG_WORKER := $(PREFIX)/worker.yaml
CONFIG_TALOSCONFIG := $(PREFIX)/talosconfig
CONFIG_KUBECONFIG := $(PREFIX)/kubeconfig
CONFIG_GEN_CONFIG := $(CONFIG_CONTROLPLANE) $(CONFIG_WORKER) $(CONFIG_TALOSCONFIG)
CONFIG_GEN := $(CONFIG_GEN_CONFIG) $(CONFIG_KUBECONFIG)
CONFIG_ALL := $(CONFIG_SECRETS) $(CONFIG_GEN)

PATCHES := $(wildcard patches/*.yaml)

.PHONY: all
all: patches $(CONFIG_ALL)

.PHONY: patches
patches:
	make -C $@

$(CONFIG_SECRETS):
	talosctl gen secrets -o $@

$(CONFIG_GEN_CONFIG)&: $(CONFIG_SECRETS) $(PATCHES)
	talosctl gen config $(CLUSTER_NAME) $(CLUSTER_ENDPOINT) \
		-o $(PREFIX) \
		--talos-version $(TALOS_VERSION) \
		--with-secrets $(CONFIG_SECRETS) \
		$$(printf -- '--config-patch @%q ' patches/*.yaml)
	talosctl config endpoint --talosconfig $(CONFIG_TALOSCONFIG) $(TALOS_ENDPOINT)

$(CONFIG_KUBECONFIG): $(CONFIG_TALOSCONFIG)
	talosctl kubeconfig --talosconfig $^ -n $(TALOS_NODE) $@

.PHONY: clean
clean:
	rm -f $(CONFIG_GEN)
	$(MAKE) -C patches clean
