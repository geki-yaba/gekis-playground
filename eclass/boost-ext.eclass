# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Original Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Build external boost libraries
#

inherit boost-utils

EXPORT_FUNCTIONS pkg_setup src_prepare src_configure src_compile src_install

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE="debug doc static test +threads"

RDEPEND="dev-libs/boost[threads?]"
DEPEND="${RDEPEND}
	dev-libs/boost-headers
	dev-util/boost-build"

boost-ext_pkg_setup() {
	# use regular expression to read last job count or default to 1 :D
	boost_jobs="$(sed -r -e "s:.*[-]{1,2}j(obs)?[ =]?([0-9]*).*:\2:" <<< "${MAKEOPTS}")"
	boost_jobs="-j${boost_jobs:=1}"
}

boost-ext_src_prepare() {
	local boost_slot="$(boost-utils_get_slot)"

	cp /usr/share/boost-${boost_slot}/boostcpp.jam "${S}" \
		|| die "boostcpp.jam not found! remerge dev-libs/boost"

	cp /usr/share/boost-${boost_slot}/Jamroot "${S}" \
		|| die "Jamroot not found! remerge dev-libs/boost"

	_boost_execute "_boost_root" || die "root configuration not written"
}

boost-ext_src_configure() {
	# -fno-strict-aliasing: prevent invalid code
	append-flags -fno-strict-aliasing

	# we need to add the prefix, and in two cases this exceeds, so prepare
	# for the largest possible space allocation
	[[ ${CHOST} == *-darwin* ]] && append-ldflags -Wl,-headerpad_max_install_names

	# bug 298489
	if use ppc || use ppc64 ; then
		[[ $(gcc-version) > 4.3 ]] && append-flags -mno-altivec
	fi

	_boost_execute "_boost_config default" || die "configuration file not written"
}

boost-ext_src_compile() {
	local boost_slot="$(boost-utils_get_slot)"
	local boost_jam="bjam-${boost_slot}"

	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	local cmd="${boost_jam} ${boost_jobs} -q -d+1 gentoorelease"
	cmd+=" threading=${threading} ${link_opts} runtime-link=shared ${options}"
	_boost_execute "${cmd}" || die "build failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "build failed for options: ${options}"
	fi
}

boost-ext_src_install() {
	local boost_slot="$(boost-utils_get_slot)"
	local boost_version="$(boost-utils_get_version)"
	local boost_jam="bjam-${boost_slot}"

	local options="$(_boost_options)"
	local library_targets="$(_boost_library_targets)"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	local cmd="${boost_jam} -q -d+1 gentoorelease threading=${threading}"
	cmd+=" ${link_opts} runtime-link=shared --includedir=${ED}/usr/include"
	cmd+=" --libdir=${ED}/usr/$(get_libdir) ${options} install"
	_boost_execute "${cmd}" || die "install failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "install failed for options: ${options}"
	fi

	cd "${ED}/usr/$(get_libdir)" || die

	# debug version
	local libver="${boost_version/_0}"
	local dbgver="${libver}-debug"

	# subdirectory with unversioned symlinks
	local path="/usr/$(get_libdir)/boost-${boost_slot}"

	dodir ${path}
	for f in $(ls -1 ${library_targets} | grep -v debug) ; do
		ln -s ../${f} "${ED}"/${path}/${f/-${libver}} || die
	done

	if use debug ; then
		path+="-debug"

		dodir ${path}
		for f in $(ls -1 ${library_targets} | grep debug) ; do
			ln -s ../${f} "${ED}"/${path}/${f/-${dbgver}} || die
		done
	fi
}

_boost_root() {
	local boost_slot="$(boost-utils_get_slot)"

	local path="${EPREFIX}/usr/$(get_libdir)/boost-${boost_slot}"
	local libpre="libboost_"
	local libpost="$(get_libname)"
	local libname=""

	# boost libraries
	for library in $(ls -1 ${path}/${libpre}*${libpost} | \
		grep -v '\-mt' | grep -v python); do
		libname="$(basename ${library})"
		libname="${libname/${libpre}}"
		libname="${libname/${libpost}}"

cat >> "${S}/Jamroot" << __EOF__

use-project /boost/${libname} : . ;
__EOF__

cat >> "${S}/Jamfile" << __EOF__

project boost/${libname} ;

lib boost_${libname}
 :
 : <name>boost_${libname} <search>/usr/$(get_libdir)/boost-${boost_slot} <variant>gentoorelease <threading>single ;

lib boost_${libname}
 :
 : <name>boost_${libname} <search>/usr/$(get_libdir)/boost-${boost_slot}-debug <variant>gentoodebug <threading>single ;

lib boost_${libname}
 :
 : <name>boost_${libname}-mt <search>/usr/$(get_libdir)/boost-${boost_slot} <variant>gentoorelease <threading>multi ;

lib boost_${libname}
 :
 : <name>boost_${libname}-mt <search>/usr/$(get_libdir)/boost-${boost_slot}-debug <variant>gentoodebug <threading>multi ;
__EOF__
	done
}

_boost_config() {
	local compiler="gcc"
	local compilerVersion="$(gcc-version)"
	local compilerExecutable="$(tc-getCXX)"

	if [[ ${CHOST} == *-darwin* ]] ; then
		compiler="darwin"
		compilerVersion=$(gcc-fullversion)
	fi

	local config="user"
	einfo "Writing new Jamfile: ${config}-config.jam"
	cat > "${S}/${config}-config.jam" << __EOF__

variant gentoorelease : release : <optimization>none <debug-symbols>none ;
variant gentoodebug : debug : <optimization>none ;

using ${compiler} : ${compilerVersion} : ${compilerExecutable} : <cxxflags>"${CXXFLAGS}" <linkflags>"${LDFLAGS}" ;
__EOF__

	# Maintainer information:
	# The debug-symbols=none and optimization=none are not official upstream
	# flags but a Gentoo specific patch to make sure that all our CXXFLAGS
	# and LDFLAGS are being respected. Using optimization=off would for example
	# add "-O0" and override "-O2" set by the user.
}

_boost_execute() {
	if [ -n "${@}" ] ; then
		# pretty print
		einfo "${@//--/\n\t--}"
		${@}

		return ${?}
	else
		return -1
	fi
}

_boost_options() {
	local boost_slot="$(boost-utils_get_slot)"

	local config="user"

	local options=""
	options+=" pch=off --user-config=${S}/${config}-config.jam --prefix=${ED}/usr"
	options+=" --boost-build=/usr/share/boost-build-${boost_slot} --layout=versioned"
	options+=" --with-${PN/boost-}"

	echo -n ${options}
}

_boost_link_options() {
	local link_opts="link=shared"
	use static && link_opts+=",static"

	echo -n ${link_opts}
}

_boost_library_targets() {
	local library_targets="*$(get_libname)"
	use static && library_targets+=" *.a"

	echo -n ${library_targets}
}

_boost_threading() {
	local threading="single"
	use threads && threading+=",multi"

	echo -n ${threading}
}
