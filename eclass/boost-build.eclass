# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost build
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

EAPI="6"

inherit flag-o-matic toolchain-funcs versionator

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_compile src_install src_test

BOOST_SP="${BOOST_SP:="_"}"
BOOST_P="boost${BOOST_SP}$(replace_all_version_separators _)"
BOOST_PV="$(replace_all_version_separators _ $(get_version_component_range 1-2))"
BOOST_PATCHDIR="${BOOST_PATCHDIR:="${WORKDIR}/patches"}"

BOOST_TOOLSRC="${BOOST_TOOLSRC:="tools/build/v2"}"
BOOST_B="${BOOST_P}/${BOOST_TOOLSRC}"

DESCRIPTION="A system for large project software construction, which is simple to use and powerful."
HOMEPAGE="http://www.boost.org/doc/tools/build/index.html"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"
[ "${BOOST_PATCHSET}" ] && \
	SRC_URI+=" http://geki.selfhost.eu/files/${BOOST_PATCHSET}"

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x86-solaris ~x86-winnt"

IUSE="examples"

DEPEND="app-arch/bzip2"
RDEPEND=""

S="${WORKDIR}/${BOOST_B}"

boost-build_pkg_pretend() {
	ewarn "Compilation of ${PN} is known to break if {C,LD}FLAGS contain"
	ewarn "extra white space (bug 293652)"
}

boost-build_pkg_setup() {
	BOOST_JAM_SRC="${S}/engine"
	BOOST_JAM_TEST="${S}/test/engine"
}

boost-build_src_unpack() {
	tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "${BOOST_B}" \
		|| tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "./${BOOST_B}" \
		|| die

	# example folder moved with 1_56_0_beta1
	tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "${BOOST_P}/tools/build/example"
	
	[ "${BOOST_PATCHSET}" ] && unpack "${BOOST_PATCHSET}"
}

boost-build_src_prepare() {
	if [ -n "${BOOST_PATCHSET}" ]; then
		local p
		if [ ! -z ${BOOST_EXCLUDE+x} ]; then
			for p in "${BOOST_EXCLUDE[@]}"; do
				rm -fv "${p}"
			done
		fi

		if [ ! -z ${BOOST_PATCHES+x} ]; then
			for p in "${BOOST_PATCHES[@]}"; do
				eapply -p0 --ignore-whitespace -- "${p}"
			done
		else
			eapply -p0 --ignore-whitespace -- "${BOOST_PATCHDIR}"
		fi
	fi

	# apply user patchsets
	eapply_user

	cd "${BOOST_JAM_SRC}" || die

	# remove stripping option
	sed -e 's|-s\b||' \
		-i build.jam || die "sed failed"

	# force regeneration
	rm -v jambase.c

	cd "${S}"

	# This patch allows us to fully control optimization
	# and stripping flags when bjam is used as build-system
	# We simply extend the optimization and debug-symbols feature
	# with empty dummies called 'none'
	sed -e "s/off speed space/\0 none/" \
		-e "s/debug-symbols      : on off/\0 none/" \
		-i tools/builtin.jam || die "sed failed"
}

boost-build_src_compile() {
	# use generic toolset to respect CC/CFLAGS
	local toolset=cc
	[[ ${CHOST} == *-darwin* ]] && toolset=darwin

	append-flags -fno-strict-aliasing

	cd "${BOOST_JAM_SRC}" || die

	# slotting
	sed -e "s|/usr/share/boost-build|\0-${BOOST_PV}|" \
		-i Jambase || die "sed failed"

	# The build.jam file for building bjam using a bootstrapped jam0 ignores
	# the LDFLAGS env var (bug #209794). We have now two options:
	# a) change the cc-target definition in build.jam to include separate compile
	#    and link targets to make it use the LDFLAGS var, or
	# b) a simple dirty workaround by injecting the LDFLAGS in the LIBS env var
	#    (which should not be set by us).
	LIBS=${LDFLAGS:=-O} CC=$(tc-getCC) \
	./build.sh ${toolset} \
		|| die "building bjam failed"
}

boost-build_src_install() {
	newbin "${BOOST_JAM_SRC}"/bin.*/bjam bjam-${BOOST_PV}

	cd "${S}"
	insinto /usr/share/boost-build-${BOOST_PV}
	doins -r bootstrap.jam build-system.jam build kernel options tools util

	# gone with 1_56_0_beta1
	for jam in boost-build.jam site-config.jam user-config.jam; do
		[ -e ${jam} ] && doins ${jam}
	done

	for txt in changes.txt hacking.txt release_procedure.txt \
		notes/build_dir_option.txt notes/relative_source_paths.txt; do
		[ -e ${txt} ] && dodoc ${txt}
	done

	if use examples; then
		insinto /usr/share/${PN}-${SLOT}
		[ -d example ] && doins -r example
		[ -d ../example ] && doins -r ../example
	fi
}

boost-build_src_test() {
	if [ -d "${BOOST_JAM_TEST}" ]; then
		cd "${BOOST_JAM_TEST}" || die
		./test.sh || die "tests failed"
	else
		ewarn "Test framework unsupported. Patches are welcomed!"
	fi
}

