all: generated_hosts.yaml

generated_hosts.yaml: hosts.yaml
	./generate-hosts.py $< > $@
