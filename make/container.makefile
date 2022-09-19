#
# Container Image UniFi
#

.PHONY: container-run-linux
container-run-linux:
	$(BIN_DOCKER) container create \
		--platform "$(PROJ_PLATFORM_OS)/$(PROJ_PLATFORM_ARCH)" \
		--name "unifi" \
		-h "unifi" \
		-u "480" \
		-w "/opt/unifi" \
		--entrypoint "java" \
		--net "$(NET_NAME)" \
		-p "3478":"3478"/"udp" \
		-p "6789":"6789" \
		-p "8080":"8080" \
		-p "8443":"8443" \
		-p "8880":"8880" \
		-p "8843":"8843" \
		--health-start-period "10s" \
		--health-interval "10s" \
		--health-timeout "8s" \
		--health-retries "3" \
		--health-cmd "unifi-healthcheck \"8443\" \"8\"" \
		-v "unifi":"/opt/unifi/data" \
		"$(IMG_REG_URL)/$(IMG_REPO):$(IMG_TAG_PFX)-$(PROJ_PLATFORM_OS)-$(PROJ_PLATFORM_ARCH)" \
		-jar "lib/ace.jar" "start"
	$(BIN_FIND) "bin" -mindepth "1" -type "f" -iname "*" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "unifi":"/opt/unifi"
	$(BIN_FIND) "data" -mindepth "1" -type "f" -iname "*" ! -iname "keystore" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "unifi":"/opt/unifi"
	$(BIN_FIND) "data" -mindepth "1" -type "f" -iname "keystore" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "480" --group "480" --mode "600" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "unifi":"/opt/unifi"
	$(BIN_DOCKER) container start -a "unifi"

.PHONY: container-run
container-run:
	$(MAKE) "container-run-$(PROJ_PLATFORM_OS)"

.PHONY: container-rm
container-rm:
	$(BIN_DOCKER) container rm -f "unifi"
