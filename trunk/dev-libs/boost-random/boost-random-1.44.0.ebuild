# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit boost

RDEPEND=""
DEPEND=""

src_prepare() {
	boost_src_prepare

	# This enables building the boost.random library with /dev/urandom support
	if [[ -e /dev/urandom ]] ; then
		mkdir -p libs/random/build
		cp "${FILESDIR}/random-Jamfile" libs/random/build/Jamfile.v2
		# yeah, we WANT it to work on non-Linux too
		sed -i -e 's/#ifdef __linux__/#if 1/' libs/random/random_device.cpp || die
	fi
}
