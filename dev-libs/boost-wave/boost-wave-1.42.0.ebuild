# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit boost

RDEPEND="dev-libs/boost-date_time:${SLOT}
	dev-libs/boost-filesystem:${SLOT}
	dev-libs/boost-system:${SLOT}
	dev-libs/boost-thread:${SLOT}"
DEPEND="${RDEPEND}"

# additional targets to extract
BOOST_ADDITIONAL_TARGETS="detail"
