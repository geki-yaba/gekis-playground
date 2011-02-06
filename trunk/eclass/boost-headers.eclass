# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Install boost headers
#

EAPI="4"

inherit eutils multilib versionator

EXPORT_FUNCTIONS pkg_pretend src_unpack src_prepare src_configure src_compile src_install

MY_P="boost_$(replace_all_version_separators _)"
LIB="${PN/boost-}"
VER="$(get_version_component_range 1-2)"

DESCRIPTION="boost.org ${LIB} libraries for C++"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${MY_P}.tar.bz2"

LICENSE="Boost-1.0"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE=""

RDEPEND="!app-admin/eselect-boost"
DEPEND="${RDEPEND}"
PDEPEND="~dev-libs/boost-${PV}"

S="${WORKDIR}/${MY_P}"

boost-headers_pkg_pretend() {
	local err=

	ls -1 /usr/$(get_libdir)/libboost_* | grep -v boost_*_*
	[[ -z ${?} ]] && err=1

	ls -1 /usr/include/boost_* >/dev/null 2>&1
	[[ -z ${?} ]] && err=1

	if [ ${err} ] ; then
		eerror
		eerror "Old files from boost.org package of the Gentoo Repository found."
		eerror "Please clean your system following the howto at:"
		eerror
		eerror "	http://code.google.com/p/gekis-playground/wiki/Boost"
		eerror
		die "keep cool and clean! ;)"
	fi
}

boost-headers_src_unpack() {
	tar xjpf "${DISTDIR}/${A}" "${MY_P}/boost"
}

boost-headers_src_prepare() {
	if [[ ${VER} < 1.44 ]] ; then
		# bug 291660
		epatch "${FILESDIR}/boost-1.42.0-parameter-needs-python.patch"
	fi

	if [[ ${VER} > 1.44 ]] ; then
		epatch "${FILESDIR}/boost-1.45.0-lambda_bind.patch"
	fi
}

boost-headers_src_configure() { :; }

boost-headers_src_compile() { :; }

boost-headers_src_install() {
	# dir
	dir="/usr/include"

	# make dir
	dodir "${dir}"

	# copy headers
	insinto "${dir}"
	doins -r boost
}
