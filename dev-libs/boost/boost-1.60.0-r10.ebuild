# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

IUSE_BOOST_LIBS=" atomic chrono container context coroutine date_time exception filesystem graph graph_parallel iostreams locale log math mpi program_options python random regex serialization signals system test thread timer wave"

BOOST_PATCHSET="gentoo-boost-1.59.0-r1.tar.xz"

#BOOST_SP="-"
#BOOST_BETA="_b"

inherit boost
