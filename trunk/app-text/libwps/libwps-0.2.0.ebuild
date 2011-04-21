# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

DESCRIPTION="Microsoft Works format import library"
HOMEPAGE="http://libwps.sf.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0.2"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc static-libs"

RDEPEND="app-text/libwpd:0.9"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	doc? ( app-doc/doxygen )"

src_configure() {
	econf $(use_with doc docs) \
		$(use_enable static-libs static) \
		--disable-dependency-tracking
}

src_install() {
	default

	find "${ED}" -name '*.la' -delete

	for b in "${D}"/usr/bin/${PN: -3:3}*; do
		mv -v ${b} ${b}-${SLOT}
	done
}
