# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

PYTHON_DEPEND="<<*:2.6>>"

inherit boost python

RDEPEND=""
DEPEND=""

pkg_setup() {
	boost_pkg_setup
	python_pkg_setup
}

src_unpack() {
	boost_src_unpack

	# copy library specific patches
	cp -v "${FILESDIR}/${PN}"-*.diff "${BOOST_PATCHDIR}"
}
