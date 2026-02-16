all: generated_hosts.yaml client.key

generated_hosts.yaml: hosts.yaml hosts.local.yaml
	yq eval-all '. as $$item ireduce ({}; . * $$item)' $^ | ./generate-hosts.py > $@

hosts.local.yaml: hosts.local.sops.yaml
	sops decrypt $< > $@

client.key: ../../ansible/pki/caddy/client-certs/client.sops.key
	sops decrypt $< > $@
