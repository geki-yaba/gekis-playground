# Copyright 1999-2012 Gentoo Foundation
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

inherit alternatives base multilib versionator

EXPORT_FUNCTIONS pkg_pretend src_unpack src_configure src_compile src_install

SLOT="$(get_version_component_range 1-2)"
BOOST_SLOT="$(replace_all_version_separators _ ${SLOT})"

BOOST_SP="${BOOST_SP:="_"}"
BOOST_P="boost${BOOST_SP}$(replace_all_version_separators _)"
BOOST_PATCHDIR="${BOOST_PATCHDIR:="${WORKDIR}/patches"}"

if [ "${BOOST_BETA}" ]; then
	BOOST_P="${BOOST_P/_beta/${BOOST_BETA}}"
fi

DESCRIPTION="boost.org c++ header libraries"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"
[ "${BOOST_PATCHSET}" ] && \
	SRC_URI+=" http://gekis-playground.googlecode.com/files/${BOOST_PATCHSET}"

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

IUSE=""

RDEPEND="!app-admin/eselect-boost
	abi_x86_32? ( !app-emulation/emul-linux-x86-cpplibs[-abi_x86_32(-)] )"
DEPEND="${RDEPEND}
	app-arch/bzip2"
PDEPEND="~dev-libs/boost-${PV}"

S="${WORKDIR}/${BOOST_P}"

# alternatives
SOURCE="/usr/include/boost"
ALTERNATIVES="/usr/include/boost-[0-9]_[0-9][0-9]/boost"

boost-headers_pkg_pretend() {
	local err=

	if has_version 'dev-libs/boost:0' ; then
		eerror
		eerror "Found installed package dev-libs/boost:0."
		eerror
		eerror "	emerge --unmerge dev-libs/boost:0"
		err=1
	fi

	# old libraries
	ls -1 "${EPREFIX}"/usr/$(get_libdir)/libboost_* 2>/dev/null | \
		grep -v boost_*_* >/dev/null
	[ -z ${?} ] && err=1

	# old includes
	ls -1 "${EPREFIX}"/usr/include/boost_* >/dev/null 2>&1
	[ -z ${?} ] && err=1

	# unslotted boost-headers
	[ -e "${EPREFIX}${SOURCE}" ] && [ ! -L "${EPREFIX}${SOURCE}" ] && err=1

	# old eselect cruft
	local boostbook="/usr/share/boostbook"
	[ -e "${EPREFIX}${boostbook}" ] && [ -L "${EPREFIX}${boostbook}" ] && err=1

	if [ ${err} ] ; then
		eerror
		eerror "Files from old dev-libs/boost package found."
		eerror "Please clean your system following the howto at:"
		eerror
		eerror "	http://code.google.com/p/gekis-playground/wiki/Boost"
		eerror
		die "keep cool and clean! ;)"
	fi
}

boost-headers_src_unpack() {
	tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "${BOOST_P}/boost" \
		|| tar xjpf "${DISTDIR}/${BOOST_P}.tar.bz2" "./${BOOST_P}/boost" \
		|| die

	[ "${BOOST_PATCHSET}" ] && unpack "${BOOST_PATCHSET}"
}

boost-headers_src_configure() { :; }

boost-headers_src_compile() { :; }

boost-headers_src_install() {
	insinto "/usr/include/boost-${BOOST_SLOT}"
	doins -r boost
}
