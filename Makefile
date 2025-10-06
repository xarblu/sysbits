# root directory to install to
DESTDIR ?= /

# USE flags, yes or no
BETAS ?= no
CLANG ?= no
DESKTOP ?= no
DESKTOP_EXTRA ?= no
LAPTOP_EXTRA ?= no
STEAMDECK_EXTRA ?= no
SERVER ?= no
BINPKG_CLIENT_LLVM ?= no
BINPKG_BUILD_HOST ?= no

install: $(PATCHES)
	install -Dm644 -t $(DESTDIR)/etc/dracut.conf.d \
		etc/dracut.conf.d/00-defaults.conf \
		etc/dracut.conf.d/10-compress.conf

	# Kernel Config Specs
	install -Dm644 -t $(DESTDIR)/etc/kernel/config.d \
		etc/kernel/config.d/00-systemd.config \
		etc/kernel/config.d/03-zram.config \
		etc/kernel/config.d/04-no-vm.config \
		etc/kernel/config.d/06-compress.config \
		etc/kernel/config.d/07-uki.config

	# Locales
	install -Dm644 -t $(DESTDIR)/etc \
		etc/locale.conf \
		etc/locale.gen

	# Profile / Environment
	install -Dm644 -t $(DESTDIR)/etc/profile.d \
		etc/profile.d/respect-xdg-dirs.sh
ifeq ($(DESKTOP),yes)
	install -Dm644 -t $(DESTDIR)/etc/profile.d \
		etc/profile.d/desktop-misc.sh \
		etc/profile.d/kde-xcursors.sh \
		etc/profile.d/makemkv-libmmdb.sh \
		etc/profile.d/plasma-preload.sh \
		etc/profile.d/vulkan-video.sh
endif

	# Portage and Friends
ifeq ($(BINPKG_CLIENT_LLVM),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/binrepos.conf \
		etc/portage/binrepos.conf/fetchcommand.conf \
		etc/portage/binrepos.conf/binpkgs-llvm.conf
endif

	install -Dm644 -t $(DESTDIR)/etc/portage/env \
		etc/portage/env/*

	install -Dm644 -t $(DESTDIR)/etc/portage/package.accept_keywords \
		etc/portage/package.accept_keywords/00-sysbits \
		etc/portage/package.accept_keywords/90-misc
ifeq ($(BETAS),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.accept_keywords \
		etc/portage/package.accept_keywords/10-openjdk \
		etc/portage/package.accept_keywords/20-llvm \
		etc/portage/package.accept_keywords/40-ffmpeg \
		etc/portage/package.accept_keywords/50-qt \
		etc/portage/package.accept_keywords/60-kernel-rcs
endif
ifeq ($(SERVER),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.accept_keywords \
		etc/portage/package.accept_keywords/05-server
endif

	install -Dm644 -t $(DESTDIR)/etc/portage/package.env \
		etc/portage/package.env/05-build-options \
		etc/portage/package.env/15-general-fixes
ifeq ($(CLANG),yes)
	install -m644 -t $(DESTDIR)/etc/portage/package.env \
		etc/portage/package.env/10-llvm-fixes
endif
ifeq ($(BINPKG_BUILD_HOST),yes)
	install -m644 -t $(DESTDIR)/etc/portage/package.env \
		etc/portage/package.env/20-binpkg-builder
endif

	install -Dm644 -t $(DESTDIR)/etc/portage/package.mask \
		etc/portage/package.mask/00-versions \
		etc/portage/package.mask/01-repos

	install -Dm644 -t $(DESTDIR)/etc/portage/package.unmask \
		etc/portage/package.unmask/01-repos
ifeq ($(BETAS),yes)
	install -m644 -t $(DESTDIR)/etc/portage/package.unmask \
		etc/portage/package.unmask/02-qt6 \
		etc/portage/package.unmask/05-mesa \
		etc/portage/package.unmask/06-kde-plasma-6.5
endif

	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/10-alternatives
ifeq ($(DESKTOP),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/00-desktop-global \
		etc/portage/package.use/20-desktop-toolchain \
		etc/portage/package.use/30-desktop-32bit \
		etc/portage/package.use/40-desktop-python-targets \
		etc/portage/package.use/50-desktop-llvm-slots \
		etc/portage/package.use/60-desktop-no-X \
		etc/portage/package.use/90-desktop-other
endif
ifeq ($(DESKTOP_EXTRA),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/01-desktop_extra-global \
		etc/portage/package.use/91-desktop_extra-other
endif
ifeq ($(LAPTOP_EXTRA),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/01-laptop_extra-global \
		etc/portage/package.use/91-laptop_extra-other
endif
ifeq ($(STEAMDECK_EXTRA),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/01-steamdeck_extra-global \
		etc/portage/package.use/91-steamdeck_extra-other
endif
ifeq ($(SERVER),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/00-server-global \
		etc/portage/package.use/90-server-other
endif

	$(MAKE) install-patches

	install -Dm755 -t $(DESTDIR)/etc/portage/postsync.d \
		etc/portage/postsync.d/*

ifeq ($(DESKTOP),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/profile/package.use.mask \
		etc/portage/profile/package.use.mask/features
endif
ifeq ($(BETAS),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/profile/package.use.mask \
		etc/portage/profile/package.use.mask/llvm-slots
endif

	install -Dm644 -t $(DESTDIR)/etc/portage/repos.conf \
		etc/portage/repos.conf/gentoo.conf
ifeq ($(DESKTOP),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/repos.conf \
		etc/portage/repos.conf/desktop.conf
endif
ifeq ($(SERVER),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/repos.conf \
		etc/portage/repos.conf/server.conf
endif
		
	install -Dm644 -t $(DESTDIR)/etc/portage/sets \
		etc/portage/sets/*
		
	install -Dm644 -t $(DESTDIR)/etc/portage \
		etc/portage/bashrc

ifeq ($(DESKTOP),yes)
ifeq ($(BINPKG_CLIENT_LLVM),yes)
	install -Dm644 -T etc/portage/make.conf.desktop.binpkgs \
		$(DESTDIR)/etc/portage/make.conf
else
	install -Dm644 -T etc/portage/make.conf.desktop \
		$(DESTDIR)/etc/portage/make.conf
endif
endif
ifeq ($(SERVER),yes)
	install -Dm644 -T etc/portage/make.conf.server \
		$(DESTDIR)/etc/portage/make.conf
endif

	install -Dm644 -t $(DESTDIR)/etc/portage \
		etc/portage/mirrors

	install -Dm644 -t $(DESTDIR)/etc/eixrc \
		etc/eixrc/02-theming \
		etc/eixrc/10-cache-methods

ifeq ($(DESKTOP),yes)
	install -Dm644 -t $(DESTDIR)/etc/sddm.conf.d \
		etc/sddm.conf.d/10-wayland.conf
endif

ifeq ($(STEAMDECK_EXTRA),yes)
	install -Dm644 -t $(DESTDIR)/etc/pam.d \
		etc/pam.d/kde \
		etc/pam.d/sddm
endif

	install -Dm644 -t $(DESTDIR)/etc/sudoers.d \
		etc/sudoers.d/00-defaults

	install -Dm644 -t $(DESTDIR)/etc/sysctl.d \
		etc/sysctl.d/55-bbr.conf \
		etc/sysctl.d/55-fq_pie.conf \
		etc/sysctl.d/60-route_cache.conf

	install -Dm644 -t $(DESTDIR)/etc/systemd \
		etc/systemd/zram-generator.conf

# if this doesn't cause issues make it unconditional
ifeq ($(DESKTOP),yes)
	install -Dm644 -t $(DESTDIR)/etc/udev/rules.d \
		etc/udev/rules.d/60-ioschedulers.rules
endif

	install -Dm644 -t $(DESTDIR)/usr/lib/dracut/modules.d/90bcachefs \
		usr/lib/dracut/modules.d/90bcachefs/module-setup.sh

	install -Dm755 -t $(DESTDIR)/usr/lib/dracut/modules.d/90bcachefs \
		usr/lib/dracut/modules.d/90bcachefs/parse-bcachefs.sh \
		usr/lib/dracut/modules.d/90bcachefs/unlock-bcachefs.sh

	install -Dm644 -t $(DESTDIR)/usr/lib/systemd/system \
		usr/lib/systemd/system/*

	install -Dm644 -t $(DESTDIR)/usr/share/sysbits/portage \
		usr/share/sysbits/portage/bashrc-utils.sh \
		usr/share/sysbits/portage/ninja_prettifier.pl

# extra targets for "recursive" installs
PATCHES := $(patsubst %.patch,$(DESTDIR)/%.patch,$(wildcard etc/portage/patches/*/*/*.patch))
install-patches: $(PATCHES)
$(DESTDIR)/etc/portage/patches/%.patch: etc/portage/patches/%.patch
	install -Dm644 -t "$(dir $@)" "$<"

.PHONY: install
