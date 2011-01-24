# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit autotools eutils flag-o-matic

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"
SRC_URI="http://www.canonware.com/download/${PN}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="debug profile stats"

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
		--with-jemalloc-prefix=j \
		$(use_enable debug) \
		$(use_enable profile prof) \
		$(use_enable stats) \
		|| die "configure failed"
}

src_install() {
	# install
	make DESTDIR="${D}" install

	# rename pproff to prevent collision
	mv "${D}"/usr/bin/pprof "${D}"/usr/bin/jpprof
}
