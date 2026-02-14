.PHONY: all
all: diff

.PHONY: clean
clean:
	rm -rf fetched diff

.PHONY: lint
lint:
	flake8 scripts/
	mypy scripts/

# VyOS config management
VYOS_ROUTERS := rtr01 rtr02
VYOS_DOMAIN := rtr.nevi.network

fetched/%:
	mkdir -p fetched
	./scripts/fetch-config.sh $* > $@

.PHONY: fetch
fetch: $(foreach r,$(VYOS_ROUTERS),fetched/$(r).$(VYOS_DOMAIN))

.PHONY: diff
diff: $(foreach r,$(VYOS_ROUTERS),diff/$(r).txt)

diff/%.txt: fetched/%.$(VYOS_DOMAIN) ../../vyos/result/%.txt ignore-paths.txt
	mkdir -p diff
	python3 scripts/diff.py $^ > $@
