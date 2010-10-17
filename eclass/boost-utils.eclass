# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow
# Purpose: Serve paths to boost libraries & headers
#

inherit flag-o-matic multilib

# get_boost_library_path
get_boost_library_path() {
	local version="$(grep -o -e "[0-9]_[0-9][0-9]" \
		/usr/include/boost/version.hpp)"

	local path="/usr/$(get_libdir)/boost-${version}"

	[ -d "${path}" ] && echo -n "${path}"
}

# add_boost_library_path
add_boost_library_path() {
	local path="$(get_boost_library_path)"

	if [ "${path}" ] ; then
		append-ldflags "-L${path}"
	else
		die "path not found! (${path})"
	fi
}

# add_boost_paths: convenient wrapper
add_boost_paths() {
	add_boost_library_path
}
