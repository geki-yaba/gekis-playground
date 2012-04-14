# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"
PYTHON_DEPEND="python? 2:2.6"
PYTHON_USE_WITH="threads"
PYTHON_USE_WITH_OPT="python"

inherit autotools boost-utils eutils flag-o-matic multilib python versionator

MY_P=${P/rb_/}
MY_P=${MY_P/torrent/torrent-rasterbar}
S=${WORKDIR}/${MY_P}

DESCRIPTION="C++ BitTorrent implementation focusing on efficiency and scalability"
HOMEPAGE="http://www.rasterbar.com/products/libtorrent/"
SRC_URI="http://libtorrent.googlecode.com/files/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="debug doc examples python ssl static-libs"
RESTRICT="test"

DEPEND="dev-libs/boost[filesystem,python?,thread]
	>=sys-devel/libtool-2.2
	examples? ( !net-p2p/mldonkey )
	ssl? ( dev-libs/openssl )"

RDEPEND="${DEPEND}"

pkg_setup() {
	if use python; then
		python_set_active_version 2
		python_pkg_setup
	fi
}

src_prepare() {
	use python && python_convert_shebangs -r 2 .
}

src_configure() {
	# use multi-threading versions of boost libs
	local myconf="--with-boost-libdir=$(boost-utils_get_library_path) \
		--with-boost-system=boost_system-mt \
		--with-boost-python=boost_python-mt"
	use debug && myconf+=" --enable-logging=verbose"

	econf $(use_enable debug) \
		$(use_enable test tests) \
		$(use_enable examples) \
		$(use_enable python python-binding) \
		$(use_enable ssl encryption) \
		$(use_enable static-libs static) \
		${myconf}
}

src_install() {
	emake DESTDIR="${ED}" install

	use static-libs || find "${ED}" -name '*.la' -delete

	dodoc ChangeLog AUTHORS NEWS README

	use doc && dohtml docs/*
}
