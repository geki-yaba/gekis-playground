# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit boost-ext

DESCRIPTION="Boost.Log c++ library"
HOMEPAGE="http://boost-log.sourceforge.net/libs/log/doc/html/index.html"
SRC_URI="mirror://sourceforge/${PN}/${P//_/-}-${PR}.zip"

SLOT="0"

RDEPEND="dev-libs/boost[datetime,filesystem,regex]"
DEPEND="${RDEPEND}"
