# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit base

DESCRIPTION="WordPerfect Document import/export library"
HOMEPAGE="http://libwpd.sf.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0.9"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc static-libs"

DEPEND="dev-util/pkgconfig
	doc? ( app-doc/doxygen )"

PATCHES=( "${FILESDIR}/${PN}-0.9.1-gcc46.diff" )

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
