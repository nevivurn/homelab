.PHONY: all
all: install.yaml

.PHONY: clean
clean:
	rm -f install.yaml

schematic/schematic.id: schematic/schematic.yaml
	curl -fsSL https://factory.talos.dev/schematics --data-binary @$^ | jq -r .id > $@

install.yaml: schematic/schematic.id
	export ID=$$(<$^); \
	export VERSION=$(TALOS_VERSION); \
	yq -n '.machine.install.disk = "/dev/vda" | .machine.install.image = "factory.talos.dev/installer-secureboot/\(env(ID)):\(env(VERSION))"' \
		> $@
