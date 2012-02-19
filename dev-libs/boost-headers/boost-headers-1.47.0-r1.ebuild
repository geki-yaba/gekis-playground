# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

BOOST_PATCHSET="gentoo-boost-1.47.0-r1.tar.xz"

PATCHES=( "${BOOST_PATCHDIR}/boost-exceptions-5731.diff" )

inherit boost-headers

