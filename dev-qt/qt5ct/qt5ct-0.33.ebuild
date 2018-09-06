# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

inherit qmake-utils

DESCRIPTION="Qt5 configuration utility"
HOMEPAGE="https://sourceforge.net/projects/qt5ct"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND="
	>=dev-qt/qtcore-5.4.0:5
	>=dev-qt/qtsvg-5.4.0:5
	>=dev-qt/linguist-tools-5.4.0:5
"
RDEPEND="${DEPEND}"

S="${WORKDIR}"/"${P}"

src_configure()
{
	local myeqmakeargs=(
		${PN}.pro
		PREFIX="${EPREFIX}/usr"
		DESKTOPDIR="${EPREFIX}/usr/share/applications"
		ICONDIR="${EPREFIX}/usr/share/pixmaps"
	)

	eqmake5 ${myeqmakeargs[@]}
}

src_install()
{
	emake INSTALL_ROOT="${ED}" install || die
}

pkg_postinst()
{
	elog "After this package is installed, please add the following"
	elog "line into the ~/.xprofile (user) or /etc/environment (system):"
	elog
	elog "	export QT_QPA_PLATFORMTHEME=qt5ct"
}
