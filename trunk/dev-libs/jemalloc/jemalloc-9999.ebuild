# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

EGIT_REPO_URI="git://canonware.com/jemalloc.git"
EGIT_MASTER="dev"

inherit autotools eutils flag-o-matic git-2

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

src_prepare() {
	# strip jemalloc optimization preset
	epatch "${FILESDIR}/optimization.diff"
	# do not install pprof
	epatch "${FILESDIR}/no-pprof.diff"

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
