# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

PYTHON_DEPEND="python? ( <<*:2.6>> )"

inherit boost python

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

	use python && python_pkg_setup
}

src_configure() {
	local jam_options="using mpi ;\n\n"
	use python && jam_options+="using python : $(python_get_version) : /usr : $(python_get_includedir) : $(python_get_libdir) ;"

	boost_src_configure
}

src_install() {
	boost_src_install

	# Move the mpi.so to the right place and make sure it's slotted
	if use python; then
		exeinto "$(python_get_sitedir)/boost_${MAJOR_PV}"
		doexe "${ED}/usr/$(get_libdir)/mpi.so"
		touch "${ED}$(python_get_sitedir)/boost_${MAJOR_PV}/__init__.py" || die
		rm -f "${ED}/usr/$(get_libdir)/mpi.so" || die

		python_need_rebuild
	fi
}
