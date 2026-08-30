# Configuration file with the commands configuration of the Redox image

$(BUILD)/harddrive.img: $(FSTOOLS) $(REPO_TAG)
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	mkdir -p $(BUILD)
	-$(FUMOUNT) $(MOUNT_DIR) || true
	-$(FUMOUNT) /tmp/redox_installer || true
	rm -rf $@  $@.partial $(MOUNT_DIR)
	FILESYSTEM_SIZE=$(FILESYSTEM_SIZE) && \
	if [ -z "$$FILESYSTEM_SIZE" ] ; then \
	FILESYSTEM_SIZE=$(shell $(INSTALLER) --filesystem-size -c $(FILESYSTEM_CONFIG)); \
	fi && \
	truncate -s "$$FILESYSTEM_SIZE"m $@.partial
	umask 002 && $(INSTALLER) $(INSTALLER_OPTS) -c $(FILESYSTEM_CONFIG) $@.partial
	mv $@.partial $@
endif

$(INSTALLER_MEDIUM): $(FSTOOLS) $(REPO_TAG) redox.ipxe
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	mkdir -p $(BUILD)
	rm -rf $@  $@.partial
	-$(FUMOUNT) /tmp/redox_installer || true
	FILESYSTEM_SIZE=$(FILESYSTEM_SIZE) && \
	if [ -z "$$FILESYSTEM_SIZE" ] ; then \
	FILESYSTEM_SIZE=$(shell $(INSTALLER) --filesystem-size -c $(FILESYSTEM_CONFIG)); \
	fi && \
	truncate -s "$$FILESYSTEM_SIZE"m $@.partial
	umask 002 && $(INSTALLER) $(INSTALLER_OPTS) -c $(FILESYSTEM_CONFIG) --write-bootloader="$(BUILD)/bootloader-live.efi" --live $@.partial
	mv $@.partial $@
	# redox.ipxe is a template: the medium carries the version in its name, and a static
	# file cannot interpolate it. Substituting here keeps network boot working after R-611a
	# instead of serving a filename that no longer exists.
	sed "s/@INSTALLER_MEDIUM_NAME@/$(INSTALLER_MEDIUM_NAME)/" redox.ipxe > $(BUILD)/redox.ipxe
	grep -q "$(INSTALLER_MEDIUM_NAME)" $(BUILD)/redox.ipxe
endif

$(BUILD)/filesystem.img: $(FSTOOLS) $(REPO_TAG)
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	mkdir -p $(BUILD)
	-$(FUMOUNT) $(MOUNT_DIR) || true
	rm -rf $@  $@.partial $(MOUNT_DIR)
	-$(FUMOUNT) /tmp/redox_installer || true
	FILESYSTEM_SIZE=$(FILESYSTEM_SIZE) && \
	if [ -z "$$FILESYSTEM_SIZE" ] ; then \
	FILESYSTEM_SIZE=$(shell $(INSTALLER) --filesystem-size -c $(FILESYSTEM_CONFIG)); \
	fi && \
	truncate -s "$$FILESYSTEM_SIZE"m $@.partial
	$(REDOXFS_MKFS) $(REDOXFS_MKFS_FLAGS) $@.partial
	mkdir -p $(MOUNT_DIR)
	$(REDOXFS) $@.partial $(MOUNT_DIR)
	sleep 1
	pgrep redoxfs
	umask 002 && $(INSTALLER) $(INSTALLER_OPTS) -c $(FILESYSTEM_CONFIG) $(MOUNT_DIR)
	sync
	-$(FUMOUNT) $(MOUNT_DIR) || true
	rm -rf $(MOUNT_DIR)
	mv $@.partial $@
endif

mount: $(FSTOOLS) FORCE
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	@mkdir -p $(MOUNT_DIR)
	$(REDOXFS) $(BUILD)/harddrive.img $(MOUNT_DIR)
	@sleep 2
	@echo "\033[1;36;49mharddrive.img mounted ($$(pgrep redoxfs))\033[0m"
endif

mount_extra: $(FSTOOLS) FORCE
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	@mkdir -p $(MOUNT_DIR)
	$(REDOXFS) $(BUILD)/extra.img $(MOUNT_DIR)
	@sleep 2
	@echo "\033[1;36;49mextra.img mounted ($$(pgrep redoxfs))\033[0m"
endif

mount_live: $(FSTOOLS) FORCE
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	@mkdir -p $(MOUNT_DIR)
	$(REDOXFS) $(INSTALLER_MEDIUM) $(MOUNT_DIR)
	@sleep 2
	@echo "\033[1;36;49m$(INSTALLER_MEDIUM_NAME) mounted ($$(pgrep redoxfs))\033[0m"
endif

unmount: FORCE
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	@sync
ifneq ($(wildcard $(MOUNT_DIR)),)
	$(FUMOUNT) $(MOUNT_DIR)
	@rm -rf $(MOUNT_DIR)
	@echo "\033[1;36;49mFilesystem unmounted\033[0m"
else
	@echo "\033[1;36;49mDisk is not mounted\033[0m"
endif
	@-$(FUMOUNT) /tmp/redox_installer 2>/dev/null || true
endif
