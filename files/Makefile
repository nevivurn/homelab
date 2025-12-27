.PHONY: hosts.zone
hosts.zone:
	cp $$(nix build .#hosts --no-link --print-out-paths)/hosts.zone .
	chmod 0644 $@
