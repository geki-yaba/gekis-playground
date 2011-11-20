# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Install boost headers
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

EAPI="4"

inherit base multilib versionator

EXPORT_FUNCTIONS pkg_pretend src_unpack src_configure src_compile src_install

BOOST_P="boost_$(replace_all_version_separators _)"
BOOST_PATCHDIR="${WORKDIR}/patches"

DESCRIPTION="boost.org header libraries for C++"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"
[[ ${BOOST_PATCHSET} ]] && \
	SRC_URI+=" http://gekis-playground.googlecode.com/files/${BOOST_PATCHSET}"

LICENSE="Boost-1.0"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE=""

RDEPEND="!app-admin/eselect-boost"
DEPEND="${RDEPEND}"
PDEPEND="~dev-libs/boost-${PV}"

S="${WORKDIR}/${BOOST_P}"

case ${PV} in
	1.47*) PATCHES=( "${BOOST_PATCHDIR}/boost-exceptions-5731.diff" ) ;;
esac

boost-headers_pkg_pretend() {
	local err=

	ls -1 /usr/$(get_libdir)/libboost_* | grep -v boost_*_*
	[ -z ${?} ] && err=1

	ls -1 /usr/include/boost_* >/dev/null 2>&1
	[ -z ${?} ] && err=1

	if [ ${err} ] ; then
		eerror
		eerror "Old files from boost.org package of the Gentoo Repository found."
		eerror "Please clean your system following the howto at:"
		eerror
		eerror "	http://code.google.com/p/gekis-playground/wiki/Boost"
		eerror
		die "keep cool and clean! ;)"
	fi
}

boost-headers_src_unpack() {
	tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "${BOOST_P}/boost"
	[[ ${BOOST_PATCHSET} ]] && unpack "${BOOST_PATCHSET}"
}

boost-headers_src_configure() { :; }

boost-headers_src_compile() { :; }

boost-headers_src_install() {
	# dir
	dir="/usr/include"

	# make dir
	dodir "${dir}"

	# copy headers
	insinto "${dir}"
	doins -r boost
}
