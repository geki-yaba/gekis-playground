# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

IUSE_BOOST_LIBS="chrono context date_time filesystem graph graph_parallel
iostreams locale math mpi program_options python random regex serialization
signals system test thread timer wave"

BOOST_PATCHSET="gentoo-boost-1.51.0.tar.xz"

#BOOST_SP="-"
#BOOST_BETA="_b"

inherit boost

EPATCH_EXCLUDE="51_boost-mpi-python31.diff"

