# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit boost

IUSE=""

RDEPEND="dev-libs/boost-system:${SLOT}"
DEPEND="${RDEPEND}"

# additional targets to extract
BOOST_ADDITIONAL_TARGETS="detail"
