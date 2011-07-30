# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

BOOST_PATCHSET="gentoo-boost-1.47.0-r1.tar.bz2"

inherit boost

DESCRIPTION="boost.org libraries for C++"
HOMEPAGE="http://www.boost.org/"

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

LIBRARIES="date_time filesystem graph graph_parallel iostreams math mpi
program_options python random regex serialization signals system test thread
wave"

for library in ${LIBRARIES} ; do
	IUSE+=" ${library}"
done

DEPEND="!dev-libs/boost-date_time
	!dev-libs/boost-filesystem
	!dev-libs/boost-graph
	!dev-libs/boost-graph_parallel
	!dev-libs/boost-iostreams
	!dev-libs/boost-math
	!dev-libs/boost-mpi
	!dev-libs/boost-program_options
	!dev-libs/boost-python
	!dev-libs/boost-random
	!dev-libs/boost-regex
	!dev-libs/boost-serialization
	!dev-libs/boost-signals
	!dev-libs/boost-system
	!dev-libs/boost-test
	!dev-libs/boost-thread
	!dev-libs/boost-wave
	!dev-util/boost-tools"
