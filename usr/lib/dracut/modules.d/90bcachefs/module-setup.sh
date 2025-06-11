#!/bin/sh

check() {
    require_binaries bcachefs || return 1

    return 0
}

depends() {
    echo crypt
}

cmdline() {
    # Hack for slow machines
    # see https://github.com/dracutdevs/dracut/issues/658
    printf " rd.driver.pre=bcachefs"
}

install() {
    inst_multiple bcachefs mount.bcachefs fsck.bcachefs

    inst_hook cmdline 90 "${moddir}/parse-bcachefs.sh"
    inst_hook pre-mount 90 "${moddir}/unlock-bcachefs.sh"
}

installkernel() {
    instmods bcachefs
}
