# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit flag-o-matic qt4-r2 versionator

MY_P="${P/_/}"
DESCRIPTION="Qt BitTorrent client"
HOMEPAGE="http://www.qbittorrent.org/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="dbus +X geoip searchengine"

QT_MIN="4.6.1"
# boost version so that we always have thread support
CDEPEND="net-libs/rb_libtorrent
	>=x11-libs/qt-core-${QT_MIN}:4
	X? ( >=x11-libs/qt-gui-${QT_MIN}:4 )
	dbus? ( >=x11-libs/qt-dbus-${QT_MIN}:4 )
	dev-libs/boost[filesystem]"
DEPEND="${CDEPEND}
	dev-util/pkgconfig"
RDEPEND="${CDEPEND}
	searchengine? ( =dev-lang/python-2* )
	geoip? ( dev-libs/geoip )"

DOCS="AUTHORS Changelog NEWS README TODO"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	epatch "${FILESDIR}"/torrentAdditionDialog_history-reversed.diff

	qt4-r2_src_prepare
}

src_configure() {
	local myconf
	use X         || myconf+=" --disable-gui"
	use geoip     || myconf+=" --disable-geoip-database"
	use dbus 	  || myconf+=" --disable-qt-dbus"

	# econf fails, since this uses qconf
	./configure --prefix=/usr --qtdir=/usr ${myconf} \
		|| die "configure failed"

	eqmake4
}
