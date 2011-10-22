# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit alternatives

DESCRIPTION="C++ library to read and parse graphics in WPG"
HOMEPAGE="http://libwpg.sourceforge.net/libwpg.htm"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0.2"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc debug static-libs"

RDEPEND="app-text/libwpd:0.9[tools]"
DEPEND="${RDEPEND}
	dev-util/pkgconfig
	doc? ( app-doc/doxygen )"

src_configure() {
	econf $(use_with doc docs) \
		$(use_enable debug) \
		$(use_enable static-libs static) \
		--docdir="${EPREFIX%/}/usr/share/doc/${PF}" \
		--program-suffix=-${SLOT} \
		--disable-dependency-tracking
}

src_install() {
	default

	find "${ED}" -name '*.la' -delete
}

pkg_postinst() {
	alternatives_auto_makesym /usr/bin/wpg2svgbatch.pl "/usr/bin/wpg2svgbatch.pl-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2svg "/usr/bin/wpg2svg-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2raw "/usr/bin/wpg2raw-[0-9].[0-9]"
}

pkg_postrm() {
	alternatives_auto_makesym /usr/bin/wpg2svgbatch.pl "/usr/bin/wpg2svgbatch.pl-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2svg "/usr/bin/wpg2svg-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpg2raw "/usr/bin/wpg2raw-[0-9].[0-9]"
}
