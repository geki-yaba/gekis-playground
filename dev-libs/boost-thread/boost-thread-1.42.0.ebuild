# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit boost

IUSE=""

RDEPEND=""
DEPEND=""

src_prepare() {
	boost_src_prepare

	# thread has no install target
	local jam="${S}/libs/thread/build/Jamfile.v2"
	echo "boost-install boost_thread ;" >> "${jam}"
}
