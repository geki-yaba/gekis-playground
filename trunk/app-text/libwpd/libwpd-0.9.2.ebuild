# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit alternatives base

DESCRIPTION="WordPerfect Document import/export library"
HOMEPAGE="http://libwpd.sf.net"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0.9"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="doc debug static-libs test tools"

DEPEND="dev-util/pkgconfig
	doc? ( app-doc/doxygen )
	test? ( dev-util/cppunit )"

PATCHES=( "${FILESDIR}/${PN}-0.9.1-test-build.diff" )

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
	alternatives_auto_makesym /usr/bin/wpd2html "/usr/bin/wpd2html-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpd2raw "/usr/bin/wpd2raw-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpd2text "/usr/bin/wpd2text-[0-9].[0-9]"
}

pkg_postrm() {
	alternatives_auto_makesym /usr/bin/wpd2html "/usr/bin/wpd2html-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpd2raw "/usr/bin/wpd2raw-[0-9].[0-9]"
	alternatives_auto_makesym /usr/bin/wpd2text "/usr/bin/wpd2text-[0-9].[0-9]"
}
