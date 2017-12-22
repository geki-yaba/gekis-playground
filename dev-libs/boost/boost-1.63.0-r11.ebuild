# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="6"

IUSE_BOOST_LIBS=" atomic chrono container context coroutine coroutine2 date_time exception fiber filesystem graph graph_parallel iostreams locale log math metaparse mpi program_options python python_numpy random regex serialization signals system test thread timer type_erasure wave"

# already in eclass since following libraries are in forever:
# filesystem, graph, graph_parallel, mpi, python, wave
REQD_BOOST_LIBS="
	boost_libs_coroutine2? (
		boost_libs_context
	)
	boost_libs_coroutine? (
		boost_libs_context
		boost_libs_system
		boost_libs_thread
	)
	boost_libs_fiber? (
		boost_libs_context
	)
	boost_libs_locale? (
		boost_libs_thread
		boost_libs_system
	)
	boost_libs_python_numpy? (
		boost_libs_python
	)"

BOOST_PATCHSET="gentoo-boost-1.63.0.tar.xz"

inherit boost

