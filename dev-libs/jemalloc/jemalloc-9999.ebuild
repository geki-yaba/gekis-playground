# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

EGIT_REPO_URI="git://canonware.com/jemalloc.git"
EGIT_MASTER="dev"

inherit autotools base flag-o-matic git-2

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS=""

IUSE="debug stats"

DEPEND=""
RDEPEND=""

S="${WORKDIR}"

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
	make DESTDIR="${D}" install
}
