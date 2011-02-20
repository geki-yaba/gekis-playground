# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# TODO: waiting for eclass/python EAPI=4 :D
#

#PYTHON_DEPEND="*"

#inherit boost python
inherit boost

RDEPEND=""
DEPEND=""

src_unpack() {
	boost_src_unpack

	# copy library specific patches
	cp -v "${FILESDIR}/${PN}"-*.diff "${BOOST_PATCHDIR}"
}

src_prepare() {
	boost_src_prepare

#	python_pkg_setup
}
