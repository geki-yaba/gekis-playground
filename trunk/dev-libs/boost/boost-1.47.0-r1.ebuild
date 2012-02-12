# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

BOOST_LIBRARIES="date_time filesystem graph graph_parallel iostreams math mpi
program_options python random regex serialization signals system test thread
wave"

BOOST_PATCHSET="gentoo-boost-1.47.0-r1.tar.xz"

inherit boost

DESCRIPTION="boost.org libraries for C++"
HOMEPAGE="http://www.boost.org/"

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

