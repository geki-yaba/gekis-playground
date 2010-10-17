# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit boost

DESCRIPTION="boost.org ${BOOST_LIB} Libraries for C++"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE="python"

RDEPEND="python? ( virtual/python )
	dev-libs/boost-serialization:${SLOT}
	|| ( sys-cluster/openmpi[cxx] sys-cluster/mpich2[cxx,threads] )"
DEPEND="${RDEPEND}"

pkg_setup() {
	# It doesn't compile with USE="python mpi" and python-3 (bug 295705)
	if use python ; then
		if [[ "$(python_get_version --major)" != "2" ]]; then
			eerror "The Boost.MPI python bindings do not support any other python version"
			eerror "than 2.x. Please either use eselect to select a python 2.x version or"
			eerror "disable the python and/or mpi use flag for =${CATEGORY}/${PF}."
			die "unsupported python version"
		fi
	fi

	boost_pkg_setup
}

src_configure() {
	use python && pystring="using python : $(python_get_version) : /usr : $(python_get_includedir) : $(python_get_libdir) ;"

	boost_src_configure
}
