# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit boost

RDEPEND="virtual/python"
DEPEND="${RDEPEND}"

src_unpack() {
	boost_src_unpack

	# copy library specific patches
	cp -v "${FILESDIR}/${PN}"-*.diff "${BOOST_PATCHDIR}"
}
