# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

BOOST_PATCHSET="gentoo-boost-1.58.0.tar.xz"

inherit boost-headers

BOOST_PATCHES=( "${BOOST_PATCHDIR}/61_boost-fusion-constexpr-types.diff" )

