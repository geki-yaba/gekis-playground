# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2

ESVN_PROJECT="${PN}"
ESVN_REPO_URI="https://lincetorrent.svn.sourceforge.net/svnroot/lincetorrent/trunk"

inherit autotools eutils subversion

DESCRIPTION="A light, powerful and full-featured gtkmm bittorrent client"
SRC_URI=""
HOMEPAGE="http://lincetorrent.sourceforge.net"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE="dbus libnotify"

RDEPEND="dev-cpp/gtkmm:2.4
	dev-cpp/cairomm
	dev-cpp/glibmm
	net-libs/rb_libtorrent
	dev-libs/boost[date_time,filesystem,signals,thread]
	dev-libs/libxml2
	sys-devel/gettext
	dbus? ( dev-libs/dbus-glib )
	libnotify? ( x11-libs/libnotify )"
DEPEND="${RDEPEND}
	dev-util/intltool"

src_prepare () {
	# fix doc installation directory (#298899)
	sed \
		-e "s|/share/doc/lince|/share/doc/lince-${PV}|" \
		-i Makefile.am

	eautoreconf
}

src_configure() {
	econf \
		$(use_with dbus) \
		$(use_with libnotify) \
		|| die "econf failed!"
}

src_install () {
	emake DESTDIR="${D}" install || die "emake install failed"
}
