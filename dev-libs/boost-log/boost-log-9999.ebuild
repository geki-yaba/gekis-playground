# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

ESVN_REPO_URI="https://${PN}.svn.sourceforge.net/svnroot/${PN}/trunk/${PN}"

inherit boost-ext subversion

DESCRIPTION="Boost.Log c++ library"
HOMEPAGE="http://boost-log.sourceforge.net/libs/log/doc/html/index.html"
SRC_URI=""

SLOT="0"

RDEPEND="dev-libs/boost[date_time,filesystem,regex]"
DEPEND="${RDEPEND}"

S="${WORKDIR}/${PN}"

src_prepare() {
	subversion_src_prepare

	boost-ext_src_prepare
}
