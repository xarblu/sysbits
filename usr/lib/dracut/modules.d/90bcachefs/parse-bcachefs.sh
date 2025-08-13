#!/bin/sh

# shellcheck disable=SC1091 # file comes from dracut
command -v getarg > /dev/null || . /lib/dracut-lib.sh

# shellcheck disable=SC2154 # var comes from dracut
case "${fstype}" in
    bcachefs) ;;
    auto) ;;
    *) return 0 ;;
esac

# TODO: should this also be set for auto or just bcachefs?
# shellcheck disable=SC2034 # var set for dracut
rootok=1
