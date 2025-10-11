.PHONY: all
all: firewall.txt

.PHONY: lint
lint:
	flake8 --ignore E501 .
	mypy --strict .

.PHONY: clean
clean:
	rm -f *.txt

%.txt: %.yaml
	./generate.py $^ > $@
