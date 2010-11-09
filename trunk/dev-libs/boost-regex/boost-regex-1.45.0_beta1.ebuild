# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit boost

IUSE="icu"

RDEPEND="icu? ( dev-libs/icu )"
DEPEND="${RDEPEND}"

pkg_setup() {
	BOOST_OPTIONAL_OPTIONS=""
	use icu && BOOST_OPTIONAL_OPTIONS="-sICU_PATH=/usr"
	export BOOST_OPTIONAL_OPTIONS

	boost_pkg_setup
}
