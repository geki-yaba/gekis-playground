# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit versionator

DESCRIPTION="boost.org Libraries for C++ - Compatibility Wrapper"
HOMEPAGE="http://www.boost.org/"
SRC_URI=""

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE="date_time filesystem graph graph_parallel iostreams math mpi
program_options python random regex serialization signals system test thread
wave"

PKGS=
for pkg in ${IUSE//+} ; do
	PKGS+=" ${pkg}? ( dev-libs/boost-${pkg}:${SLOT} )"
done

RDEPEND="${PKGS}"
DEPEND="${RDEPEND}"
