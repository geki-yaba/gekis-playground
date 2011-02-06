# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit boost

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
