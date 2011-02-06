# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost build
#

EAPI="4"

inherit flag-o-matic toolchain-funcs versionator

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_compile src_install src_test

MY_PV="$(replace_all_version_separators _)"
MAJOR_PV="$(replace_all_version_separators _ $(get_version_component_range 1-2))"
BOOST_P="boost_${MY_PV}"

DESCRIPTION="A system for large project software construction, which is simple to use and powerful."
HOMEPAGE="http://www.boost.org/doc/tools/build/index.html"
SRC_URI="mirror://sourceforge/boost/boost_${MY_PV}.tar.bz2"

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"

IUSE="examples python"

DEPEND="python? ( dev-lang/python )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/boost_${MY_PV}/tools"

boost-build_pkg_pretend() {
	ewarn "Compilation of ${PN} is known to break if {C,LD}FLAGS contain"
	ewarn "extra white space (bug 293652)"
}

boost-build_pkg_setup() {
	# set jam root
	if [[ ${SLOT} > 1.44 ]] ; then
		BOOST_JAM="${S}/build/v2/engine"
	else
		BOOST_JAM="${S}/jam"
	fi
}

boost-build_src_unpack() {
	local cmd
	cmd="tar xjpf ${DISTDIR}/${BOOST_P}.tar.bz2"
	cmd+=" boost_${MY_PV}/tools/build/v2"

	# old jam versions
	[[ ${SLOT} < 1.45 ]] && cmd+=" boost_${MY_PV}/tools/jam"

	# extract
	echo ${cmd}; ${cmd} || die
}

boost-build_src_prepare() {
	cd "${BOOST_JAM}/src" || die

	# Remove stripping option
	sed -e 's|-s\b||' \
		-i build.jam || die "sed failed"

	# Force regeneration
	rm -v jambase.c

	# This patch allows us to fully control optimization
	# and stripping flags when bjam is used as build-system
	# We simply extend the optimization and debug-symbols feature
	# with empty dummies called 'none'
	cd "${S}/build/v2"
	sed -e "s/off speed space/\0 none/" \
		-e "s/debug-symbols      : on off/\0 none/" \
		-i tools/builtin.jam || die "sed failed"
}

boost-build_src_compile() {
	# Using boost's generic toolset here, which respects CC and CFLAGS
	local toolset=cc
	[[ ${CHOST} == *-darwin* ]] && toolset=darwin

	append-flags -fno-strict-aliasing

	cd "${BOOST_JAM}/src" || die

	# For slotting
	sed -e "s|/usr/share/boost-build|\0-${MAJOR_PV}|" \
		-i Jambase || die "sed failed"

	# The build.jam file for building bjam using a bootstrapped jam0 ignores
	# the LDFLAGS env var (bug #209794). We have now two options:
	# a) change the cc-target definition in build.jam to include separate compile
	#    and link targets to make it use the LDFLAGS var, or
	# b) a simple dirty workaround by injecting the LDFLAGS in the LIBS env var
	#    (which should not be set by us).
	LIBS=${LDFLAGS:=-O} CC=$(tc-getCC) \
	./build.sh ${toolset} $(use_with python) \
		|| die "building bjam failed"
}

boost-build_src_install() {
	newbin "${BOOST_JAM}"/src/bin.*/bjam bjam-${MAJOR_PV}

	cd "${S}/build/v2"
	insinto /usr/share/boost-build-${MAJOR_PV}
	doins -r boost-build.jam bootstrap.jam build-system.jam site-config.jam user-config.jam \
		build kernel options tools util

	dodoc changes.txt hacking.txt release_procedure.txt \
		notes/build_dir_option.txt notes/relative_source_paths.txt

	if use examples ; then
		insinto /usr/share/doc/${PF}
		doins -r example
	fi
}

boost-build_src_test() {
	cd "${BOOST_JAM}"/test || die
	./test.sh || die "tests failed"
}
