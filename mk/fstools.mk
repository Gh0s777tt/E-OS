# Configuration file for redox-installer, Cookbook and RedoxFS FUSE

fstools: $(FSTOOLS_TAG) $(FSTOOLS)

GOING_TO_PODMAN_AGAIN?=0

# The host tools are built from RECIPE sources, but $(FSTOOLS) is a DIRECTORY target whose
# only prerequisites were order-only. Make therefore treats it as up to date the moment the
# directory exists, so an edit to recipes/core/installer/source never rebuilt the binary that
# writes every image.
#
# Measured, not assumed: after editing installer.rs, `make build/fstools.tag` printed
# "'build/fstools.tag' is up to date", the follow-up build compiled only redox_cookbook, and
# build/fstools/bin/redox_installer kept its Jul 5 timestamp. Every "verified" installer change
# since then would have been verified against a stale binary.
#
# The sources are fetched, not tracked, so on a host that has never fetched them this expands
# to nothing and the behaviour is exactly what it was. Inside the build container -- the only
# place `make` actually runs -- it is the real dependency list.
FSTOOLS_RECIPE_SRC := $(shell find recipes/core/installer/source recipes/core/redoxfs/source \
    \( -name '*.rs' -o -name 'Cargo.toml' -o -name 'Cargo.lock' \) 2>/dev/null)

# These tools run inside Podman if it is used, or on the host if Podman is not used
$(FSTOOLS): $(FSTOOLS_RECIPE_SRC) | prefix $(CONTAINER_TAG) $(FSTOOLS_TAG)
ifeq ($(PODMAN_BUILD),1)
ifeq ($(FSTOOLS_IN_PODMAN),1)
	$(PODMAN_RUN) make $@
else
	$(MAKE) $@ PODMAN_BUILD=0 SKIP_CHECK_TOOLS=1 GOING_TO_PODMAN_AGAIN=1
endif
else
	rm -rf $@ $@.partial
	mkdir -p $@.partial
	ln -s ../../recipes $@.partial/recipes
	$(MAKE) fstools_fetch PODMAN_BUILD=$(GOING_TO_PODMAN_AGAIN)

	# Compile installer and redoxfs for host (may be outside of podman container)
	cd $@.partial && \
		export CARGO_TARGET_DIR=../$@-target && \
		$(HOST_CARGO) install --root . --path recipes/core/installer/source --locked $(INSTALLER_FEATURES) && \
		$(HOST_CARGO) install --root . --path recipes/core/redoxfs/source --locked $(REDOXFS_FEATURES)

	mv $@.partial $@
	touch $@
endif

fstools_fetch: $(FSTOOLS_TAG) FORCE
ifeq ($(PODMAN_BUILD),1)
	$(PODMAN_RUN) make $@
else
	$(REPO_BIN) fetch host:installer host:redoxfs
endif

CARGO_OFFLINE_FLAG=
ifeq ($(REPO_OFFLINE),1)
CARGO_OFFLINE_FLAG=--offline
endif

# The host tools -- repo, repo_builder, cookbook_redoxer -- are what cook and package the OS.
# This target used to depend on $(CONTAINER_TAG) alone, and with PODMAN_BUILD=0 (the mode every real
# build runs in) that variable is EMPTY, so the target had ZERO prerequisites: once build/fstools.tag
# existed, make never rebuilt the tools again no matter what changed in src/.
#
# Measured consequence: a full build on 2026-08-30 ran against a repo_builder binary from the
# previous day while the source in the same tree already emitted the index `serial` field. The build
# went green and the published index simply did not carry it. Nothing warned.
#
# Listing the sources fixes the cause. cargo still decides whether a rebuild is needed, so an
# unchanged tree costs one no-op cargo invocation.
COOKBOOK_HOST_SRC := $(shell find src -name '*.rs' 2>/dev/null)

$(FSTOOLS_TAG): Cargo.toml Cargo.lock $(COOKBOOK_HOST_SRC) $(CONTAINER_TAG)
ifeq ($(PODMAN_BUILD),1)
	$(PODMAN_RUN) make $@
else
	$(HOST_CARGO) build --manifest-path Cargo.toml --release --locked $(CARGO_OFFLINE_FLAG)
	mkdir -p $(@D)
	touch $@
endif

fstools_clean: FORCE
	rm -rf target
	rm -rf $(FSTOOLS)
	rm -rf $(FSTOOLS)-target
	rm -f $(FSTOOLS_TAG)
