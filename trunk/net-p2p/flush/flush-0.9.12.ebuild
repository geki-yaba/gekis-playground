# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# Header: $

EAPI="4"

inherit autotools base boost-utils flag-o-matic

DESCRIPTION="A GtkMM-based BitTorrent client"
HOMEPAGE="http://sourceforge.net/projects/flush/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86 ~ppc"
IUSE=""

DEPEND="dev-cpp/gtkmm:2.4
	dev-cpp/glibmm:2
	dev-cpp/libglademm:2.4
	dev-libs/libconfig
	dev-libs/boost[filesystem,signals]
	net-libs/rb_libtorrent
	sys-apps/dbus
	sys-devel/gettext
	x11-libs/gtk+:2
	x11-libs/libnotify"
RDEPEND="${DEPEND}"

PATCHES=( "${FILESDIR}"/filesystem-v3.diff "${FILESDIR}"/remove-silly.diff )

src_prepare() {
	base_src_prepare

	eautoreconf
}

src_configure() {
	append-flags "-DBOOST_FILESYSTEM_NARROW_ONLY"

	econf --disable-bundle-package \
		--enable-system-libconfig \
		--enable-system-libtorrent \
		--with-boost-libdir="$(boost-utils_get_library_path)" \
		--with-boost-filesystem=boost_filesystem-mt \
		--with-boost-signals=boost_signals-mt \
		--with-boost-system=boost_system-mt \
		--with-boost-thread=boost_thread-mt \
		--with-ssl \
		|| die "econf failed!"
}

src_install() {
	default

	ewarn
	ewarn "There seems to be some incompability with older version"
	ewarn "configuration files. If Flush seems to be unstable or"
	ewarn "too slow you can fix this with 'rm -rf ~/.flush'."
	ewarn
	ewarn "WARNING: This will remove all your loaded torrent files."
	ewarn
}

