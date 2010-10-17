# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit boost

DESCRIPTION="boost.org ${BOOST_LIB} Libraries for C++"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE=""

RDEPEND=""
DEPEND=""

src_prepare() {
	boost_src_prepare

	# This enables building the boost.random library with /dev/urandom support
	if [[ -e /dev/urandom ]] ; then
		mkdir -p libs/random/build
		cp "${FILESDIR}/random-Jamfile" libs/random/build/Jamfile.v2
		# yeah, we WANT it to work on non-Linux too
		sed -i -e 's/#ifdef __linux__/#if 1/' libs/random/random_device.cpp || die
	fi
}
