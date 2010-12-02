# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

DESCRIPTION="Microsoft Works format import library"
HOMEPAGE="http://libwps.sf.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86"
IUSE="doc"
RESTRICT="test"

RDEPEND=">=app-text/libwpd-0.9.0"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	doc? ( app-doc/doxygen )"

src_install() {
	emake DESTDIR="${D}" install || die "installation failed"
	dodoc CHANGES CREDITS INSTALL README
}
