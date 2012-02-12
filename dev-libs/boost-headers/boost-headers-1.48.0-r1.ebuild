# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

BOOST_PATCHSET="gentoo-boost-1.48.0.tar.xz"

BOOST_PATCHDIR="${WORKDIR}/patches"
PATCHES=( "${BOOST_PATCHDIR}/10_boost-exceptions-5731.diff"
	"${BOOST_PATCHDIR}/11_boost-BOOST_FOREACH-6131.diff" )

inherit boost-headers

RDEPEND=""
DEPEND=""
