# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit boost

IUSE="icu"

RDEPEND="icu? ( >=dev-libs/icu-3.3 )"
DEPEND="${RDEPEND}"

pkg_setup() {
	BOOST_OPTIONAL_OPTIONS=""
	use icu && BOOST_OPTIONAL_OPTIONS="-sICU_PATH=/usr"
	export BOOST_OPTIONAL_OPTIONS

	boost_pkg_setup
}
