# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

EGIT_REPO_URI="git://canonware.com/jemalloc.git"
EGIT_BRANCH="dev"

inherit autotools eutils flag-o-matic git

DESCRIPTION="Jemalloc is a general-purpose scalable concurrent allocator"
HOMEPAGE="http://www.canonware.com/jemalloc/"

SRC_URI=""

LICENSE="bsd"
SLOT="0"
KEYWORDS=""
IUSE="debug profiling statistics"

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
		$(use_enable debug) \
		$(use_enable profiling prof) \
		$(use_enable statistics stats) \
		|| die "configure failed"
}

src_install() {
	git_path_fix

	# install
	make DESTDIR="${D}" install
}

git_path_fix() {
	# PN twice
	cd "${PN}" || die "${PN} path not found! has this been fixed?!"
}
