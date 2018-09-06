# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow
# Purpose: Serve paths to boost libraries & headers
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

EAPI=7

inherit flag-o-matic

boost-utils_get_include_path() {
	[ ${#} -ne 1 ] && die "${FUNCNAME}: need boost slot as parameter"

	local slot="${1}"
	local path="${EPREFIX}/usr/include/boost-${slot/./_}"

	if [ -d "${path}" ] ; then
		echo -n "${path}"
	else
		die "${FUNCNAME}: path not found! (${path})"
	fi
}

boost-utils_get_library_path() {
	[ ${#} -gt 1 ] && die "${FUNCNAME}: need boost slot as parameter"

	local slot

	if [ ${#} -eq 1 ] ; then
		slot="${1}"
	else
		slot="$(boost-utils_get_slot)"
	fi

	local path="${EPREFIX}/usr/$(get_libdir)/boost-${slot}"

	if [ -d "${path}" ] ; then
		echo -n "${path}"
	else
		die "${FUNCNAME}: path not found! (${path})"
	fi
}

boost-utils_has_libraries() {
	local path="$(boost-utils_get_library_path)"

	if [ -d "${path}" ] ; then
		if [ "$(ls -A ${path})" ] ; then
			echo -n "true"
		fi
	fi
}

boost-utils_get_slot() {
	local header="${EPREFIX}/usr/include/boost/version.hpp"
	local slot="$(grep -o -e "[0-9]_[0-9][0-9]" ${header})"

	if [ "${slot}" ] ; then
		echo -n "${slot}"
	else
		die "${FUNCNAME}: could not find boost slot"
	fi
}

boost-utils_get_version() {
	local header="${EPREFIX}/usr/include/boost/version.hpp"
	local version="$(grep -o -e "BOOST_VERSION [0-9][0-9][0-9][0-9][0-9][0-9]" \
		${header} | cut -d' ' -f2)"

	local major=$(( ${version} / 100000 ))
	local minor=$(( ${version} / 100 % 1000 ))
	local micro=$(( ${version} % 100 ))

	version="${major}_${minor}_${micro}"

	if [ "${version}" ] ; then
		echo -n "${version}"
	else
		die "${FUNCNAME}: could not find boost version"
	fi
}

# convenience wrapper
boost-utils_add_library_path() {
	local path="$(boost-utils_get_library_path)"

	append-ldflags "-L${path}"
}

boost-utils_add_paths() {
	boost-utils_add_library_path
}
