#!/bin/sh

check() {
    require_binaries bcachefs || return 1

    return 0
}

depends() {
    return 0
}

cmdline() {
    # Hack for slow machines
    # see https://github.com/dracutdevs/dracut/issues/658
    printf " rd.driver.pre=bcachefs"
}

install() {
    inst_multiple bcachefs mount.bcachefs fsck.bcachefs

    inst_hook cmdline 90 "${moddir}/parse-cmdline.sh"
    inst_hook pre-mount 90 "${moddir}/unlock.sh"
}

installkernel() {
    instmods bcachefs
}
