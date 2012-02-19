# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

BOOST_PATCHSET="gentoo-boost-1.48.0.tar.xz"

PATCHES=( "${BOOST_PATCHDIR}/10_boost-exceptions-5731.diff"
	"${BOOST_PATCHDIR}/11_boost-BOOST_FOREACH-6131.diff" )

inherit boost-headers

