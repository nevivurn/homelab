all: hosts.json

hosts.json: hosts.yaml generate-hosts.py
	./generate-hosts.py $< > $@
