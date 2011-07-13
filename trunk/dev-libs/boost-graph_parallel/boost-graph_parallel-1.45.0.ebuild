# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit boost

RDEPEND="dev-libs/boost-mpi:${SLOT}"
DEPEND="${RDEPEND}"

# additional targets to extract
BOOST_ADDITIONAL_TARGETS="detail serialization"

src_configure() {
	local jam_options="using mpi ;"

	boost_src_configure
}
