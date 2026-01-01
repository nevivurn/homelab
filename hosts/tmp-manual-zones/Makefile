.PHONY: all
all:
	mkdir -p hosts
	./generate.py hosts.yaml

.PHONY: lint
lint:
	flake8 --ignore E501 .
	mypy --strict .

.PHONY: clean
clean:
	rm -rf hosts
