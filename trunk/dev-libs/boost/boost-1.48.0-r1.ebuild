# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

IUSE_BOOST_LIBS="date_time filesystem graph graph_parallel iostreams math mpi
program_options python random regex serialization signals system test thread
wave"

BOOST_PATCHSET="gentoo-boost-1.48.0.tar.xz"

inherit boost

