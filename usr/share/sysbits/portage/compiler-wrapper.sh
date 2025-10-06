#!/usr/bin/env bash

# Intended as a launcher for compilers via <LANG>_COMPILER_LAUNCHER
# https://cmake.org/cmake/help/latest/prop_tgt/LANG_COMPILER_LAUNCHER.html#prop_tgt:%3CLANG%3E_COMPILER_LAUNCHER

function main() {
    local lang="${1}"

    # shellcheck disable=SC2016
    case "${lang}" in
        '$(CC)') echo CC ;;
        '$(CXX)') echo CXX ;;
    esac

    exec "${@}"
}
main "${@}"

