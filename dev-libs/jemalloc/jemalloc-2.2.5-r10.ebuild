# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit autotools base flag-o-matic multilib

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"
SRC_URI="http://www.canonware.com/download/${PN}/${P}.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="debug static-libs stats"

DEPEND=""
RDEPEND=""

PATCHES=( "${FILESDIR}/optimization.diff" "${FILESDIR}/no-pprof.diff" )

src_prepare() {
	base_src_prepare

	# autotooling
	eautoreconf
}

src_configure() {
	# configure
	econf \
		--with-jemalloc-prefix=j \
		$(use_enable debug) \
		$(use_enable stats) \
		|| die "configure failed"
}

src_install() {
	# install
	make DESTDIR="${ED}" install

	# doc
	dodoc ChangeLog README
	dohtml doc/jemalloc.html
	rm -rf "${ED}"/usr/share/doc/jemalloc

	# static
	use static-libs || rm -v "${ED}"/usr/$(get_libdir)/*.a
}
