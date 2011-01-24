# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

EGIT_REPO_URI="git://canonware.com/jemalloc.git"
EGIT_BRANCH="dev"
# eclass/git feature: if not equal use EGIT_COMMIT, which defaults to master
EGIT_COMMIT="${EGIT_BRANCH}"

inherit autotools eutils flag-o-matic git

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"
SRC_URI=""

LICENSE="BSD"
SLOT="0"
KEYWORDS=""

IUSE="debug profile stats"

DEPEND=""
RDEPEND=""

S="${WORKDIR}"

src_prepare() {
	git_path_fix

	# strip jemalloc optimization preset
	epatch "${FILESDIR}/optimization.diff"

	# autotooling
	eautoreconf
}

src_configure() {
	git_path_fix

	# configure
	econf \
		--with-jemalloc-prefix=j \
		$(use_enable debug) \
		$(use_enable profile prof) \
		$(use_enable stats) \
		|| die "configure failed"
}

src_install() {
	git_path_fix

	# install
	make DESTDIR="${D}" install

	# rename pproff to prevent collision
	mv "${D}"/usr/bin/pprof "${D}"/usr/bin/jpprof
}

git_path_fix() {
	# PN twice
	cd "${PN}" || die "${PN} path not found! has this been fixed?!"
}
