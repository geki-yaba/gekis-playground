# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit autotools eutils flag-o-matic

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"

SRC_URI="http://www.canonware.com/download/${PN}/${P}.tar.bz2"

LICENSE="bsd"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug profiling statistics"

DEPEND=""
RDEPEND=""

src_prepare() {
	# strip jemalloc optimization preset
	epatch "${FILESDIR}/optimization.diff"

	# autotooling
	eautoreconf
}

src_configure() {
	# configure
	econf \
		$(use_enable debug) \
		$(use_enable profiling prof) \
		$(use_enable statistics stats) \
		|| die "configure failed"
}

src_install() {
	# install
	make DESTDIR="${D}" install
}
