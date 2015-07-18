# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

#BOOST_SP="-"
#BOOST_BETA="_b"

BOOST_PATCHSET="gentoo-boost-1.58.0.tar.xz"

inherit boost-headers

PATCHES=( "${BOOST_PATCHDIR}/61_boost-fusion-constexpr-types.diff" )

