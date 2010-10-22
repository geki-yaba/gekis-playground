# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils versionator

MY_P="boost_$(replace_all_version_separators _)"
LIB="${PN/boost-}"

DESCRIPTION="boost.org ${LIB} libraries for C++"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${MY_P}.tar.bz2"

LICENSE="Boost-1.0"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE=""

RDEPEND=""
DEPEND=""
PDEPEND="dev-libs/boost:$(get_version_component_range 1-2)"

S="${WORKDIR}/${MY_P}"

pkg_setup() {
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

src_unpack() {
	tar xjpf "${DISTDIR}/${A}" "${MY_P}/boost"
}

src_prepare() {
	 # bug 291660
	epatch "${FILESDIR}/boost-1.42.0-parameter-needs-python.patch"
}

src_configure() { :; }

src_compile() { :; }

src_install() {
	# dir
	dir="/usr/include"

	# make dir
	dodir "${dir}"

	# copy headers
	insinto "${dir}"
	doins -r boost
}
