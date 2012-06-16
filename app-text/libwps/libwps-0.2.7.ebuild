# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit base

DESCRIPTION="Microsoft Works file word processor format import filter library"
HOMEPAGE="http://libwps.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.xz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc debug static-libs"

RDEPEND="app-text/libwpd:0.9"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( app-doc/doxygen )"

src_configure() {
	econf $(use_with doc docs) \
		$(use_enable debug) \
		$(use_enable static-libs static) \
		--docdir="${EPREFIX%/}/usr/share/doc/${PF}" \
		--disable-dependency-tracking
}

src_install() {
	default

	find "${ED}" -name '*.la' -delete
}

