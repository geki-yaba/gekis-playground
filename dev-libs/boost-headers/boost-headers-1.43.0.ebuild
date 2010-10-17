# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# There is a headers package, but they are generated so late.
#

EAPI="2"

inherit eutils versionator

MY_P="boost_$(replace_all_version_separators _)"
LIB="${PN/boost-}"

DESCRIPTION="boost.org ${LIB} Libraries for C++"
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
