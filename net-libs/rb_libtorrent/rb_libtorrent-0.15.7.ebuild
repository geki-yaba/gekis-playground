# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
PYTHON_DEPEND="python? 2:2.6"
PYTHON_USE_WITH="threads"

inherit boost-utils eutils flag-o-matic versionator python

MY_P=${P/rb_/}
MY_P=${MY_P/torrent/torrent-rasterbar}
S=${WORKDIR}/${MY_P}

DESCRIPTION="C++ BitTorrent implementation focusing on efficiency and scalability"
HOMEPAGE="http://www.rasterbar.com/products/libtorrent/"
SRC_URI="http://libtorrent.googlecode.com/files/${MY_P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~arm ~ppc ~ppc64 ~sparc ~x86 ~x86-fbsd"
IUSE="debug doc examples python ssl"
RESTRICT="test"

DEPEND="dev-libs/boost[filesystem,python?,thread]
	>=sys-devel/libtool-2.2
	sys-libs/zlib
	examples? ( !net-p2p/mldonkey )
	ssl? ( dev-libs/openssl )"

RDEPEND="${DEPEND}"

pkg_setup() {
	use python && python_set_active_version 2
}

src_prepare() {
	use python && python_convert_shebangs -r 2 .

	sed -e "s:BOOST_FILESYSTEM_VERSION=2:BOOST_FILESYSTEM_VERSION=3:g" \
		-e "s:BOOST_FILESYSTEM_VERSION 2:BOOST_FILESYSTEM_VERSION 3:g" \
		-e "s:\[BOOST_FILESYSTEM_VERSION\],\[2\]:[BOOST_FILESYSTEM_VERSION],[3]:g" \
		-i bindings/python/setup.py -i configure -i configure.ac -i Jamfile \
		-i libtorrent-rasterbar-cmake.pc -i libtorrent-rasterbar.pc

	epatch "${FILESDIR}/rb_libtorrent-0.15.7-boost-1_46.diff"
}

src_configure() {
	# use multi-threading versions of boost libs
	local boost_libs="--with-boost-system=boost_system-mt \
		--with-boost-filesystem=boost_filesystem-mt \
		--with-boost-thread=boost_thread-mt \
		--with-boost-python=boost_python-mt"
	local boost_lib="$(boost-utils_get_library_path)"

	append-flags "-DBOOST_FILESYSTEM_NARROW_ONLY"

	local myconf
	use debug && myconf+=" --enable-logging=verbose"

	econf $(use_enable debug) \
		$(use_enable test tests) \
		$(use_enable examples) \
		$(use_enable python python-binding) \
		$(use_enable ssl encryption) \
		--with-zlib=system \
		--with-boost-libdir=${boost_lib} \
		${boost_libs} \
		${myconf} \
		|| die
}

src_install() {
	emake DESTDIR="${D}" install || die 'emake install failed'

	dodoc ChangeLog AUTHORS NEWS README || die 'dodoc failed'

	if use doc ; then
		dohtml docs/* || die "Could not install HTML documentation"
	fi
}
