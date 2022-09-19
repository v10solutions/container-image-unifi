#
# Container Image UniFi
#

.PHONY: vol-create
vol-create:
	$(BIN_DOCKER) volume create "unifi"

.PHONY: vol-rm
vol-rm:
	$(BIN_DOCKER) volume rm "unifi"
