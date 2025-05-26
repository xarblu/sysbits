# root directory to install to
DESTDIR ?= /

# USE flags, yes or no
BETAS ?= no
CLANG ?= no
DESKTOP ?= no
DESKTOP_EXTRA ?= no
LAPTOP_EXTRA ?= no
SERVER ?= no

install: $(PATCHES) $(REPOS_CONF)
	# Profile / Environment
	install -m755 -d $(DESTDIR)/etc/profile.d
	install -m644 -t $(DESTDIR)/etc/profile.d \
		etc/profile.d/*

	# Portage and Friends
	install -Dm644 -t $(DESTDIR)/etc/portage/env \
		etc/portage/env/*

	install -Dm644 -t $(DESTDIR)/etc/portage/package.accept_keywords \
		etc/portage/package.accept_keywords/00-sysbits
ifeq ($(BETAS),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.accept_keywords \
		etc/portage/package.accept_keywords/10-openjdk \
		etc/portage/package.accept_keywords/20-llvm \
		etc/portage/package.accept_keywords/50-kde-plasma-6.3.90 \
		etc/portage/package.accept_keywords/60-kernel-rcs
endif
ifeq ($(SERVER),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.accept_keywords \
		etc/portage/package.accept_keywords/05-server
endif

	install -Dm644 -t $(DESTDIR)/etc/portage/package.env \
		etc/portage/package.env/15-general-fixes
ifeq ($(CLANG),yes)
	install -m644 -t $(DESTDIR)/etc/portage/package.env \
		etc/portage/package.env/10-llvm-fixes
endif
ifeq ($(SERVER),yes)
	install -m644 -t $(DESTDIR)/etc/portage/package.env \
		etc/portage/package.env/05-server
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
		etc/portage/package.unmask/06-kde-plasma-6.4
endif

	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/10-alternatives
ifeq ($(DESKTOP),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/00-global-common \
		etc/portage/package.use/20-toolchain \
		etc/portage/package.use/30-32bit \
		etc/portage/package.use/40-python-targets \
		etc/portage/package.use/50-llvm-slots \
		etc/portage/package.use/60-no-X \
		etc/portage/package.use/90-other-common
endif
ifeq ($(DESKTOP_EXTRA),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/01-global-desktop \
		etc/portage/package.use/91-other-desktop
endif
ifeq ($(LAPTOP_EXTRA),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/01-global-laptop \
		etc/portage/package.use/91-other-laptop
endif
ifeq ($(SERVER),yes)
	install -Dm644 -t $(DESTDIR)/etc/portage/package.use \
		etc/portage/package.use/00-global-server \
		etc/portage/package.use/90-other-server
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
	install -Dm644 -T etc/portage/make.conf\#desktop \
		$(DESTDIR)/etc/portage/make.conf
endif
ifeq ($(SERVER),yes)
	install -Dm644 -T etc/portage/make.conf\#server \
		$(DESTDIR)/etc/portage/make.conf
endif

	install -Dm644 -t $(DESTDIR)/usr/share/sysbits/portage \
		usr/share/sysbits/portage/bashrc-utils.sh

	install -Dm644 -t $(DESTDIR)/etc/eixrc \
		etc/eixrc/*

	install -Dm644 -t $(DESTDIR)/usr/lib/systemd/system \
		usr/lib/systemd/system/*

# extra targets for "recursive" installs
PATCHES := $(patsubst %.patch,$(DESTDIR)/%.patch,$(wildcard etc/portage/patches/*/*/*.patch))
install-patches: $(PATCHES)
$(DESTDIR)/etc/portage/patches/%.patch: etc/portage/patches/%.patch
	install -Dm644 -t "$(dir $@)" "$<"

.PHONY: install
