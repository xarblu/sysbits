# misc utility functions for portage's bashrc
# meant to be sourced in global scope in /etc/portage/bashrc
#
# example bashrc:
#
# source /usr/share/sysbits/portage/bashrc-utils.sh
#
# # do some extra setup
# function pre_pkg_setup() {
#        # setup environment
#        brc_build_env_setup
#
#        # print flags
#        brc_build_info
# }

# helper to check is a config variable is truthy
# default value can be provided, if not empty -> false
function brc_truthy() {
    if (( ${#} < 1 )) || (( ${#} > 2 )); then
        die "Usage: ${FUNCNAME[0]} VARIABLE [default]"
    fi

    local variable="${1}"
    local default="${2:-false}"

    local value
    # scary eval but brc_truthy should only be used internally
    eval "value=\"\${${variable}:-${default}}\""

    case "${value,,}" in
        1|true|yes|y) return 0 ;;
        0|false|no|n) return 1 ;;
        *) ewarn "Unknown value for ${variable}: ${value}" ;;
    esac
}


# print the current build environment
function brc_build_info() {
    einfo "=== Portage Info ==="
    einfo "Version: $(ebuild --version)"
    einfo "FEATURES: ${FEATURES}"
    einfo "=== Compiler Info ==="
    einfo "CC: $(${CC} --version | head -1)"
    einfo "CXX: $(${CXX} --version | head -1)"
    einfo "CPP: $(${CPP} --version | head -1)"
    einfo "RUSTC: $(rustc --version | head -1)"
    einfo "LD: $(${LD} --version | head -1)"
    einfo "CFLAGS: ${CFLAGS}"
    einfo "CXXFLAGS: ${CXXFLAGS}"
    einfo "OBJCFLAGS: ${OBJCFLAGS}"
    einfo "OBJCXXFLAGS: ${OBJCXXFLAGS}"
    einfo "FCFLAGS: ${FCFLAGS}"
    einfo "F77FLAGS: ${F77FLAGS}"
    einfo "RUSTFLAGS: ${RUSTFLAGS}"
    einfo "LDFLAGS: ${LDFLAGS}"
    einfo "=== Build Tools Info ==="
    einfo "MAKEOPTS: ${MAKEOPTS}"
}

# mangle *FLAGS
# by default appends flags unless --reset is given
# in which case old flags are cleared and replaced
# $1 - flag family (c/cxx/objc/objcxx/fc/f77/rust/ld)
#      there also are shorthands for
#        c-common - {,obj}c{,xx}
#        f-common - f{c,77}
#        common   - both of the above
#      and pseudo families llvm, gnu (defined as LLVM_FAMILIES, GNU_FAMILIES)
# $2+ - flags
function brc_mangle_flags() {
    local reset='false'
    local family
    local -a flags
    while (( ${#} > 0 )); do
        case "${1}" in
            --reset) reset=true ;;
            *)
                # break after first positional argument
                family="${1}"
                shift
                flags+=( "${@}" )
                break
                ;;
        esac
        shift
    done

    if (( ${#flags[@]} == 0 )); then
        die "Usage: ${FUNCNAME[0]} [--reset] family flags..."
    fi

    local reset_arg
    if [[ "${reset}" == true ]]; then
        reset_arg="--reset"
    fi

    local flagvar
    case "${family}" in
        c) flagvar=CFLAGS ;;
        cxx) flagvar=CXXFLAGS ;;
        objc) flagvar=OBJCFLAGS ;;
        objcxx) flagvar=OBJCXXFLAGS ;;
        fc) flagvar=FCFLAGS ;;
        f77) flagvar=F77FLAGS ;;
        rust) flagvar=RUSTFLAGS ;;
        ld) flagvar=LDFLAGS ;;
        c-common)
            "${FUNCNAME[0]}" ${reset_arg} c "${flags[@]}"
            "${FUNCNAME[0]}" ${reset_arg} cxx "${flags[@]}"
            "${FUNCNAME[0]}" ${reset_arg} objc "${flags[@]}"
            "${FUNCNAME[0]}" ${reset_arg} objcxx "${flags[@]}"
            return
            ;;
        f-common)
            "${FUNCNAME[0]}" ${reset_arg} fc "${flags[@]}"
            "${FUNCNAME[0]}" ${reset_arg} f77 "${flags[@]}"
            return
            ;;
        common)
            "${FUNCNAME[0]}" ${reset_arg} c-common "${flags[@]}"
            "${FUNCNAME[0]}" ${reset_arg} f-common "${flags[@]}"
            return
            ;;
        llvm)
            for family in ${LLVM_FAMILIES}; do
                "${FUNCNAME[0]}" ${reset_arg} "${family}" "${flags[@]}"
            done
            return
            ;;
        gnu)
            for family in ${GNU_FAMILIES}; do
                "${FUNCNAME[0]}" ${reset_arg} "${family}" "${flags[@]}"
            done
            return
            ;;
        *) die "${FUNCNAME[0]}: invalid flag family: ${family}" ;;
    esac

    if [[ -z "${flagvar}" ]]; then
        die "flagvar is unset"
    fi

    if [[ "${reset}" == true ]]; then
        eval "${flagvar}=\"${flags[*]}\""
    else
        eval "${flagvar}+=\" ${flags[*]}\""
        eval "${flagvar}=\"\${${flagvar}# }\""
    fi
}

# match CC and prepend its path in PATH
# - useful if clang is requested via CC
#   but build scripts use generic CHOST-cc
# - fixes full LLVM toolchain to clang's version
#   i.e. CC=clang-19 will auto-select ld.lld-19
# - doesn't do anything if CC is not clang
#   or a specific path
function brc_prepend_llvm_path() {
    # nop if non-clang
    case "${CC}" in
        *clang*) ;;
        */*)
            einfo "CC (${CC}) looks like a specific path - leaving PATH alone"
            return
            ;;
        *)
            einfo "CC (${CC}) not clang - leaving PATH alone"
            return
            ;;
    esac

    einfo "Prepending ${CC}s directory in PATH..."

    # grab CCs PATH
    local ccpath
    ccpath="$(type -p "${CC}")"
    ccpath="${ccpath%/*}"
    if [[ -z "${ccpath}" ]]; then
        ewarn "Could not resolve ${CC} - leaving PATH as is"
    fi

    # create new path
    local -a oldpath
    local dir newpath
    IFS=':' read -ra oldpath <<<"${PATH}"
    newpath+="${ccpath}"
    for dir in "${oldpath[@]}"; do
        if [[ "${dir}" == "${ccpath}" ]]; then
            continue
        fi
        newpath+=":${dir}"
    done

    einfo "Old: ${PATH}"
    einfo "New: ${newpath}"
    export PATH="${newpath}"
}

# setup build environment
# base *FLAGS are set in make.conf and expanded here
# configuration options (true/false):
# ENABLE_MOLD (default false):
#   - use mold linker for linking
# ENABLE_LTO (default false):
#   - enable link time optimization
# ENABLE_ICF (default false):
#   - enable identical code folding (requires LLVM toolchain)
# ENABLE_MIMALLOC (default false):
#   - LD_PRELOAD libmimalloc.so
# ENABLE_POLLY (default false):
#   - enable LLVM polly
# ENABLE_SCCACHE (default false):
#   - enable sccache for C/C++/Rust
# BUILD_EYECANDY (default true):
#   - enable eyecandy for the build progress like colour, progress bars etc
# BUILD_VERBOSE (default false):
#   - enable verbose builds (default in vanilla portage)
function brc_build_env_setup() {
    # explicitly set defaults if not set
    # these come from toolchain-funcs.eclass
    : "${CC:=gcc}"
    : "${CXX:=g++}"
    : "${CPP:="${CC} -E"}"
    : "${LD:=ld}"

    # auto detect compiler families
    LLVM_FAMILIES=""
    GNU_FAMILIES=""
    # CC -> c, objc
    case "${CC##*/}" in
        *clang*) LLVM_FAMILIES+=" c objc ";;
        *gcc*) GNU_FAMILIES+=" c objc ";;
        *) ewarn "Unknown CC: ${CC}";;
    esac
    # CXX -> cxx, objcxx
    case "${CXX##*/}" in
        *clang++*) LLVM_FAMILIES+=" cxx objcxx ";;
        *g++*) GNU_FAMILIES+=" cxx objcxx ";;
        *) ewarn "Unknown CXX: ${CXX}";;
    esac
    # for now fc and f77 will always be GNU
    GNU_FAMILIES+=" fc f77 "

    # set rust linker to CC since the default-linker was changed to ${CHOST}-cc
    # which links to gcc... https://bugs.gentoo.org/951740
    # handled by cargo.eclass in most cases but useful in case it isn't used
    brc_mangle_flags rust "-C linker=${CC}"

    # prepend CC in PATH if we use clang so llvm-core/clang-toolchain-symlinks[native-symlinks]
    # actually does something
    brc_prepend_llvm_path

    # BUILD_DEBUG essentially overrides the entire environment
    if brc_truthy BUILD_DEBUG; then
        COMMON_FLAGS="-Og -ggdb3 -pipe"
        # shellcheck disable=SC2034
        ENABLE_LTO=false
        # shellcheck disable=SC2034
        ENABLE_ICF=false
        # shellcheck disable=SC2034
        ENABLE_POLLY=false
    fi

    # apply common flags
    # XXX: --reset here to clear Gentoo's defaults
    # for e.g. CFLAGS
    if [[ -n "${COMMON_FLAGS}" ]]; then
        brc_mangle_flags --reset common "${COMMON_FLAGS}"
    fi

    # toggle ld.mold
    if brc_truthy ENABLE_MOLD; then
        export LD="ld.mold"
        brc_mangle_flags ld "-fuse-ld=mold"
        brc_mangle_flags rust "-C link-arg=-fuse-ld=mold"
    fi
    unset ENABLE_MOLD

    # toggle lto flags
    if brc_truthy ENABLE_LTO; then
        brc_mangle_flags llvm "-flto=thin"
        brc_mangle_flags gnu "-flto=auto"
        brc_mangle_flags rust "-C embed-bitcode=yes -C lto=thin"
        case "${LD##*/}" in
            ld.lld)
                brc_mangle_flags ld "-flto=thin"
                brc_mangle_flags rust "-C linker-plugin-lto"
                ;;
            ld.mold)
                brc_mangle_flags ld "-flto=thin"
                brc_mangle_flags rust "-C linker-plugin-lto=/usr/${CHOST}/binutils-bin/lib/bfd-plugins/LLVMgold.so"
                ;;
            ld.bfd|ld.gold)
                brc_mangle_flags ld "-flto=auto"
                brc_mangle_flags rust "-C linker-plugin-lto=/usr/${CHOST}/binutils-bin/lib/bfd-plugins/LLVMgold.so"
                ;;
            *)
                ewarn "Unknown LD: ${LD}"
                ;;
        esac
    fi
    unset ENABLE_LTO

    # toggle icf for supported linkers
    if brc_truthy ENABLE_ICF; then
        case "${LD##*/}" in
            ld.lld|ld.mold)
                brc_mangle_flags ld "-Wl,--icf=safe"
                brc_mangle_flags rust "-C link-arg=-Wl,--icf=safe"
                ;;
            ld.bfd|ld.gold) ;;
            *)
                ewarn "Unknown LD: ${LD}"
                ;;
        esac
    fi
    unset ENABLE_ICF

    # toggle preloading of libmimalloc.so
    if [[ "${ENABLE_MIMALLOC:-false}" == true ]]; then
        if has_version dev-libs/mimalloc; then
            export LD_PRELOAD="${LD_PRELOAD:+${LD_PRELOAD}:}libmimalloc.so"
        else
            ewarn "ENABLE_MIMALLOC is set but dev-libs/mimalloc isn't installed - ignoring"
        fi
    fi
    unset ENABLE_MIMALLOC

    # toggle polly flags
    if brc_truthy ENABLE_POLLY; then
        # plugin should be loaded via llvm-core/clang-runtime[polly]
        # default flags from https://github.com/CachyOS/kernel-patches/blob/master/6.16/misc/0001-clang-polly.patch
        brc_mangle_flags llvm "-mllvm -polly"
        brc_mangle_flags llvm "-mllvm -polly-ast-use-context"
        brc_mangle_flags llvm "-mllvm -polly-invariant-load-hoisting"
        brc_mangle_flags llvm "-mllvm -polly-loopfusion-greedy"
        brc_mangle_flags llvm "-mllvm -polly-run-inliner"
        brc_mangle_flags llvm "-mllvm -polly-vectorizer=stripmine"
        brc_mangle_flags llvm "-mllvm -polly-run-dce"
    fi
    unset ENABLE_POLLY

    # if OVERRIDE_*FLAGS are set always apply those
    [[ -n "${OVERRIDE_COMMON_FLAGS}" ]] && brc_mangle_flags --reset common "${OVERRIDE_CFLAGS}"
    [[ -n "${OVERRIDE_CFLAGS}" ]] && brc_mangle_flags --reset c "${OVERRIDE_CFLAGS}"
    [[ -n "${OVERRIDE_CXXFLAGS}" ]] && brc_mangle_flags --reset cxx "${OVERRIDE_CXXFLAGS}"
    [[ -n "${OVERRIDE_OBJCFLAGS}" ]] && brc_mangle_flags --reset objc "${OVERRIDE_OBJCFLAGS}"
    [[ -n "${OVERRIDE_OBJCXXFLAGS}" ]] && brc_mangle_flags --reset objcxx "${OVERRIDE_OBJCXXFLAGS}"
    [[ -n "${OVERRIDE_FCFLAGS}" ]] && brc_mangle_flags --reset fc "${OVERRIDE_FCFLAGS}"
    [[ -n "${OVERRIDE_F77FLAGS}" ]] && F77brc_mangle_flags --reset f77 "${OVERRIDE_F77FLAGS}"
    [[ -n "${OVERRIDE_RUSTFLAGS}" ]] && brc_mangle_flags --reset rust "${OVERRIDE_RUSTFLAGS}"
    [[ -n "${OVERRIDE_LDFLAGS}" ]] && brc_mangle_flags --reset ld "${OVERRIDE_LDFLAGS}"

    # if EXTRA_*FLAGS are set append those - even after OVERRIDE_*FLAGS
    [[ -n "${EXTRA_COMMON_FLAGS}" ]] && brc_mangle_flags common "${EXTRA_COMMON_FLAGS}"
    [[ -n "${EXTRA_CFLAGS}" ]] && brc_mangle_flags c "${EXTRA_CFLAGS}"
    [[ -n "${EXTRA_CXXFLAGS}" ]] && brc_mangle_flags cxx "${EXTRA_CXXFLAGS}"
    [[ -n "${EXTRA_OBJCFLAGS}" ]] && brc_mangle_flags objc "${EXTRA_OBJCFLAGS}"
    [[ -n "${EXTRA_OBJCXXFLAGS}" ]] && brc_mangle_flags objcxxj "${EXTRA_OBJCXXFLAGS}"
    [[ -n "${EXTRA_FCFLAGS}" ]] && brc_mangle_flags fc "${EXTRA_FCFLAGS}"
    [[ -n "${EXTRA_F77FLAGS}" ]] && brc_mangle_flags f77 "${EXTRA_F77FLAGS}"
    [[ -n "${EXTRA_RUSTFLAGS}" ]] && brc_mangle_flags rust "${EXTRA_RUSTFLAGS}"
    [[ -n "${EXTRA_LDFLAGS}" ]] && brc_mangle_flags ld "${EXTRA_LDFLAGS}"


    # gcc workaround for bug #915389
    # (power/efficiency cores have different cache values)
    if [[ "${CATEGORY}/${PN}" == sys-devel/gcc ]]; then
        if command -v resolve-march-native >/dev/null; then
            einfo "Resolving -march=native to work around bug #915389..."
            local march_native
            case "${CC}" in
                *clang*) march_native="$(resolve-march-native --clang "${CC}")";;
                *gcc*) march_native="$(resolve-march-native --gcc "${CC}")";;
            esac
            CFLAGS="${CFLAGS//-march=native/"${march_native}"}"
            CXXFLAGS="${CXXFLAGS//-march=native/"${march_native}"}"
            OBJCFLAGS="${OBJCFLAGS//-march=native/"${march_native}"}"
            OBJCXXFLAGS="${OBJCXXFLAGS//-march=native/"${march_native}"}"
            FCFLAGS="${FCFLAGS//-march=native/"${march_native}"}"
            F77FLAGS="${F77FLAGS//-march=native/"${march_native}"}"
            LDFLAGS="${LDFLAGS//-march=native/"${march_native}"}"
        else
            ewarn "app-misc/resolve-march-native is needed to resolve -march=native"
        fi
    fi

    # re-export *FLAGS
    export CFLAGS CXXFLAGS OBJCFLAGS OBJCXXFLAGS FCFLAGS F77FLAGS RUSTFLAGS LDFLAGS

    # setup PATH for sccache if requested
    if brc_truthy ENABLE_SCCACHE; then
        if command -v sccache >/dev/null; then
            local sccache_wraps="/usr/lib/sccache/bin"
            export PATH="${sccache_wraps}:${PATH}"
            export RUSTC_WRAPPER="sccache"

            # some defaults for sccache
            # https://github.com/mozilla/sccache/blob/main/docs/Configuration.md
            : "${SCCACHE_IDLE_TIMEOUT:="10"}"
            : "${SCCACHE_MAX_FRAME_LENGTH:="104857600"}"
            : "${SCCACHE_DIR:="/var/cache/sccache"}"
            : "${SCCACHE_CACHE_SIZE:="75G"}"
            : "${SCCACHE_DIRECT:="true"}"

            export SCCACHE_IDLE_TIMEOUT SCCACHE_MAX_FRAME_LENGTH SCCACHE_DIR SCCACHE_CACHE_SIZE SCCACHE_DIRECT
        else
            ewarn "Could not find sccache binary in PATH"
        fi
    fi
    unset ENABLE_SCCACHE

    # setup makeopts and optionally limit
    : "${MAKEOPTS:="-j$(nproc)"}"
    if [[ -n "${MAX_MAKE_JOBS}" ]]; then
        local make_jobs="${MAKEOPTS}"
        make_jobs="${make_jobs##*-j}"
        make_jobs="${make_jobs##*--jobs}"
        make_jobs="${make_jobs%% *}"
        make_jobs="${make_jobs// /}"
        MAX_MAKE_JOBS="${MAX_MAKE_JOBS// /}"
        if (( make_jobs > MAX_MAKE_JOBS )); then
            MAKEOPTS="${MAKEOPTS//"-j${make_jobs}"/"-j${MAX_MAKE_JOBS}"}"
        fi
    fi
    export MAKEOPTS

    # build system eyecandy (e.g. colours)
    if brc_truthy BUILD_EYECANDY true; then
        # common make/ninja
        export CLICOLOR_FORCE="1"
        # cmake
        export CMAKE_MAKEFILE_GENERATOR="${CMAKE_MAKEFILE_GENERATOR:-ninja}"
        export CMAKE_WARN_UNUSED_CLI="OFF"
        export CMAKE_COLOR_DIAGNOSTICS="ON"
        local compiler_wrapper="${BASH_SOURCE[0]%/*}/compiler-wrapper.sh"
        if [[ -f "${compiler_wrapper}" ]]; then
            export CMAKE_C_COMPILER_LAUNCHER="${compiler_wrapper}"
            export CMAKE_CXX_COMPILER_LAUNCHER="${compiler_wrapper}"
        fi
        # cargo
        export CARGO_TERM_COLOR="always"
        export CARGO_TERM_PROGRESS_WHEN="always"
        export CARGO_TERM_PROGRESS_WIDTH="${COLUMNS:-80}"
    fi
    unset BUILD_EYECANDY

    # build system verbosity
    if ! brc_truthy BUILD_VERBOSE; then
        # cmake
        export CMAKE_VERBOSE="OFF"
        # ninja
        export NINJA_VERBOSE="OFF"
        # meson
        export MESON_VERBOSE="OFF"
        # cargo
        export CARGO_TERM_QUIET="false"
        export CARGO_TERM_VERBOSE="false"
        # kbuild when using kernel-build.eclass
        if [[ -n "${_KERNEL_BUILD_ECLASS}" ]]; then
            export EXTRA_EMAKE="${EXTRA_EMAKE} V=0"
        fi
    fi
    unset BUILD_VERBOSE
}

