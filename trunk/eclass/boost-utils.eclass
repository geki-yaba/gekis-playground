# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow
# Purpose: Serve paths to boost libraries & headers
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

inherit flag-o-matic multilib

boost-utils_get_library_path() {
	local slot="$(grep -o -e "[0-9]_[0-9][0-9]" \
		/usr/include/boost/version.hpp)"
	local path="/usr/$(get_libdir)/boost-${slot}"

	[ -d "${path}" ] && echo -n "${path}"
}

boost-utils_add_library_path() {
	local path="$(boost-utils_get_library_path)"

	if [  "${path}" ] ; then
		append-ldflags "-L${path}"
	else
		die "path not found! (${path})"
	fi
}

boost-utils_add_paths() {
	boost-utils_add_library_path
}
