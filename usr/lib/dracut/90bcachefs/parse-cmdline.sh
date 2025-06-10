#!/bin/sh

if [ "${fstype}" != bcachefs ]; then
    return 0
fi

rootok=1
