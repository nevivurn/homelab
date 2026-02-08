all: generated_hosts.yaml

generated_hosts.yaml: hosts.yaml hosts.local.yaml
	yq eval-all '. as $$item ireduce ({}; . * $$item)' $^ | ./generate-hosts.py > $@
