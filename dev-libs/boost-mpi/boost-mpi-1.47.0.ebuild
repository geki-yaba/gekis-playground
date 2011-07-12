# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# TODO: waiting for eclass/python EAPI=4 :D
#

#PYTHON_DEPEND="python? *"

#inherit boost python
inherit boost

IUSE="python"

RDEPEND="dev-libs/boost-serialization:${SLOT}
	|| ( sys-cluster/openmpi[cxx] sys-cluster/mpich2[cxx,threads] )"
DEPEND="${RDEPEND}"

src_unpack() {
	boost_src_unpack

	# copy library specific patches
	cp -v "${FILESDIR}/${PN}"-*.diff "${BOOST_PATCHDIR}"
}

src_prepare() {
	boost_src_prepare

#	use python && python_pkg_setup
}

src_configure() {
#	use python && pystring="using python : $(python_get_version) : /usr : $(python_get_includedir) : $(python_get_libdir) ;"

	boost_src_configure
}
