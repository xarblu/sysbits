#!/bin/sh

# shellcheck disable=SC1091 # file comes from dracut
command -v getarg > /dev/null || . /lib/dracut-lib.sh

# shellcheck disable=SC2154 # var comes from dracut
case "${fstype}" in
    bcachefs) ;;
    auto)
        warn "unlock-bcachefs: rootfstype unset or auto. Will try to unlock anyways."
        ;;
    *) return 0 ;;
esac

# shellcheck disable=SC2154 # var comes from dracut
dev="${root#block:}"

if bch_out="$(bcachefs unlock -c "${dev}" 2>&1)"; then
    systemd-ask-password "Unlock ${dev}:" | bcachefs unlock "${dev}"
else
    info "unlock-bcachefs: ${bch_out}"
fi

unset dev bch_out
