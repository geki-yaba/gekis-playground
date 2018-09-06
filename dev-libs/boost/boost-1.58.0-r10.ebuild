# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=7

IUSE_BOOST_LIBS=" chrono context date_time filesystem graph graph_parallel iostreams locale math mpi program_options python random regex serialization signals system test thread timer wave"

BOOST_PATCHSET="gentoo-boost-1.51.0.tar.xz"

inherit boost

BOOST_EXCLUDE=( "${BOOST_PATCHDIR}/51_boost-mpi-python31.diff" )

