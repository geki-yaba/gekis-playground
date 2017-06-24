# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="6"

IUSE_BOOST_LIBS=" atomic chrono container context coroutine date_time exception filesystem graph graph_parallel iostreams locale log math mpi program_options python random regex serialization signals system test thread timer wave"

BOOST_PATCHSET="gentoo-boost-1.58.0.tar.xz"

inherit boost

BOOST_EXCLUDE=( "${BOOST_PATCHDIR}/51_boost-mpi-python31.diff" )

