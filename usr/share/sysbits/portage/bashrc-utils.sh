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

# print the current build environment
function brc_build_info() {
	einfo "=== Portage Info ==="
	einfo "Version: $(ebuild --version)"
	einfo "FEATURES: ${FEATURES}"
	einfo "=== Compiler Info ==="
	einfo "CC: $(${CC} --version | head -1)"
	einfo "CXX: $(${CXX} --version | head -1)"
	einfo "CPP: $(${CPP} --version | head -1)"
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

# append to existing *FLAGS
# $1 - flag family (c/cxx/objc/objcxx/fc/f77/rust/ld)
#      there also are shorthands for c-common, f-common
#      and pseudo families llvm, gnu (defined as LLVM_FAMILIES, GNU_FAMILIES)
# $2+ - flags
function brc_append_flags() {
    if (( ${#} != 2 )); then
		die "brc_append_flags: expected 2 args"
	fi
    local family="${1}"
    local flags="${2}"
	case "${family}" in
		c) CFLAGS="${CFLAGS} ${flags}" ;;
		cxx) CXXFLAGS="${CXXFLAGS} ${flags}" ;;
		objc) OBJCFLAGS="${OBJCFLAGS} ${flags}" ;;
		objcxx) OBJCXXFLAGS="${OBJCXXFLAGS} ${flags}" ;;
		fc) FCFLAGS="${FCFLAGS} ${flags}" ;;
		f77) F77FLAGS="${F77FLAGS} ${flags}" ;;
		rust) RUSTFLAGS="${RUSTFLAGS} ${flags}" ;;
		ld) LDFLAGS="${LDFLAGS} ${flags}" ;;
		c-common)
			CFLAGS="${CFLAGS} ${flags}"
			CXXFLAGS="${CXXFLAGS} ${flags}"
			OBJCFLAGS="${OBJCFLAGS} ${flags}"
			OBJCXXFLAGS="${OBJCXXFLAGS} ${flags}"
			;;
		f-common)
			FCFLAGS="${FCFLAGS} ${flags}"
			F77FLAGS="${F77FLAGS} ${flags}"
			;;
		llvm) 
			for family in ${LLVM_FAMILIES}; do
				brc_append_flags "${family}" "${flags}"
			done
			;;
		gnu) 
			for family in ${GNU_FAMILIES}; do
				brc_append_flags "${family}" "${flags}"
			done
			;;
		*) die "brc_append_flags: invalid flag family: ${family}" ;;
	esac
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
    local ccpath="$(dirname "$(type -p "${CC}")")"
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
#   - link libmimalloc.so by default
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
    brc_append_flags rust "-C linker=${CC}"

    # prepend CC in PATH if we use clang so llvm-core/clang-toolchain-symlinks[native-symlinks]
    # actually does something
    brc_prepend_llvm_path

	# toggle ld.mold
	if "${ENABLE_MOLD:-false}"; then
		export LD="ld.mold"
		brc_append_flags ld "-fuse-ld=mold"
		brc_append_flags rust "-C link-arg=-fuse-ld=mold"
	fi
    unset ENABLE_MOLD

	# toggle lto flags
	if "${ENABLE_LTO:-false}"; then
		brc_append_flags llvm "-flto=thin"
		brc_append_flags gnu "-flto=auto"
		brc_append_flags rust "-C embed-bitcode=yes -C lto=thin"
		case "${LD##*/}" in
			ld.lld)
				brc_append_flags ld "-flto=thin"
				brc_append_flags rust "-C linker-plugin-lto"
				;;
			ld.mold)
				brc_append_flags ld "-flto=thin"
				brc_append_flags rust "-C linker-plugin-lto=/usr/${CHOST}/binutils-bin/lib/bfd-plugins/LLVMgold.so"
				;;
			ld.bfd|ld.gold)
				brc_append_flags ld "-flto=auto"
				brc_append_flags rust "-C linker-plugin-lto=/usr/${CHOST}/binutils-bin/lib/bfd-plugins/LLVMgold.so"
				;;
			*)
				ewarn "Unknown LD: ${LD}"
				;;
		esac
	fi
    unset ENABLE_LTO

	# toggle icf for supported linkers
	if "${ENABLE_ICF:-false}"; then
		case "${LD##*/}" in
			ld.lld|ld.mold)
				brc_append_flags ld "-Wl,--icf=safe"
				brc_append_flags rust "-C link-arg=-Wl,--icf=safe"
				;;
			ld.bfd|ld.gold) ;;
			*)
				ewarn "Unknown LD: ${LD}"
				;;
		esac
	fi
    unset ENABLE_ICF

	# toggle icf for supported linkers
	if "${ENABLE_MIMALLOC:-false}"; then
        if has_version dev-libs/mimalloc; then
            brc_append_flags ld "-lmimalloc"
            brc_append_flags rust "-C link-arg=-lmimalloc"
        else
            ewarn "ENABLE_MIMALLOC is set but dev-libs/mimalloc isn't installed - ignoring"
        fi
	fi
    unset ENABLE_MIMALLOC

    # toggle polly flags
    if "${ENABLE_POLLY:-false}"; then
        # plugin should be loaded via llvm-core/clang-runtime[polly]
        # default flags from https://github.com/CachyOS/kernel-patches/blob/master/6.16/misc/0001-clang-polly.patch
        brc_append_flags llvm "-mllvm -polly"
        brc_append_flags llvm "-mllvm -polly-ast-use-context"
        brc_append_flags llvm "-mllvm -polly-invariant-load-hoisting"
        brc_append_flags llvm "-mllvm -polly-loopfusion-greedy"
        brc_append_flags llvm "-mllvm -polly-run-inliner"
        brc_append_flags llvm "-mllvm -polly-vectorizer=stripmine"
        brc_append_flags llvm "-mllvm -polly-run-dce"
    fi
    unset ENABLE_POLLY

	# if EXTRA_*FLAGS are set append those
	[[ -n "${EXTRA_CFLAGS}" ]] && brc_append_flags c "${EXTRA_CFLAGS}"
	[[ -n "${EXTRA_CXXFLAGS}" ]] && brc_append_flags cxx "${EXTRA_CXXFLAGS}"
	[[ -n "${EXTRA_OBJCFLAGS}" ]] && brc_append_flags objc "${EXTRA_OBJCFLAGS}"
	[[ -n "${EXTRA_OBJCXXFLAGS}" ]] && brc_append_flags objcxxj "${EXTRA_OBJCXXFLAGS}"
	[[ -n "${EXTRA_FCFLAGS}" ]] && brc_append_flags fc "${EXTRA_FCFLAGS}"
	[[ -n "${EXTRA_F77FLAGS}" ]] && brc_append_flags f77 "${EXTRA_F77FLAGS}"
	[[ -n "${EXTRA_RUSTFLAGS}" ]] && brc_append_flags rust "${EXTRA_RUSTFLAGS}"
	[[ -n "${EXTRA_LDFLAGS}" ]] && brc_append_flags ld "${EXTRA_LDFLAGS}"

	# if OVERRIDE_*FLAGS are set always use those plus EXTRA_*FLAGS in case they are set
	[[ -n "${OVERRIDE_CFLAGS}" ]] && CFLAGS="${OVERRIDE_CFLAGS} ${EXTRA_CFLAGS}"
	[[ -n "${OVERRIDE_CXXFLAGS}" ]] && CXXFLAGS="${OVERRIDE_CXXFLAGS} ${EXTRA_CFLAGS}"
	[[ -n "${OVERRIDE_OBJCFLAGS}" ]] && OBJCFLAGS="${OVERRIDE_OBJCFLAGS} ${EXTRA_CFLAGS}"
	[[ -n "${OVERRIDE_OBJCXXFLAGS}" ]] && OBJCXXFLAGS="${OVERRIDE_OBJCXXFLAGS} ${EXTRA_CFLAGS}"
	[[ -n "${OVERRIDE_FCFLAGS}" ]] && FCFLAGS="${OVERRIDE_FCFLAGS} ${EXTRA_CFLAGS}"
	[[ -n "${OVERRIDE_F77FLAGS}" ]] && F77FLAGS="${OVERRIDE_F77FLAGS} ${EXTRA_CFLAGS}"
	[[ -n "${OVERRIDE_RUSTFLAGS}" ]] && RUSTFLAGS="${OVERRIDE_RUSTFLAGS} ${EXTRA_CFLAGS}"
	[[ -n "${OVERRIDE_LDFLAGS}" ]] && LDFLAGS="${OVERRIDE_LDFLAGS} ${EXTRA_CFLAGS}"

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
	if "${ENABLE_SCCACHE:-false}"; then
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
	if "${BUILD_EYECANDY:-true}"; then
		# common make/ninja
		export CLICOLOR_FORCE="1"
		# cmake
		export CMAKE_MAKEFILE_GENERATOR="${CMAKE_MAKEFILE_GENERATOR:-ninja}"
		export CMAKE_WARN_UNUSED_CLI="OFF"
		export CMAKE_COLOR_DIAGNOSTICS="ON"
		# cargo
		export CARGO_TERM_COLOR="always"
		export CARGO_TERM_PROGRESS_WHEN="always"
		export CARGO_TERM_PROGRESS_WIDTH="80"
	fi
    unset BUILD_EYECANDY

	# build system verbosity
	if ! "${BUILD_VERBOSE:-false}"; then
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

