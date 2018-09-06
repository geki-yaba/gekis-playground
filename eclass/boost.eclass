# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost libraries
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

#
# Things the Gentoo package is missing:
#
#	- header-only distribution
#	- at least make Boost.Math and Boost.Wave libraries optional
#	  (taking far too much compile time and noone uses that ... .. .)
#	- make Boost.Regex library optional
#	  (taking mediocre compile time and rarely used ...)
#
#	... until then I have to manage this. :/
#
# https://bugs.gentoo.org/show_bug.cgi?id=260404
# https://bugs.gentoo.org/show_bug.cgi?id=307921
#

EAPI=7

PYTHON_COMPAT=( python{2_7,3_{4,5,6}} )

inherit check-reqs flag-o-matic multilib-minimal multiprocessing python-r1 toolchain-funcs

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_prepare src_configure src_compile src_install src_test

SLOT="$(ver_cut 1-2)"
BOOST_SLOT="$(ver_rs 1- _ ${SLOT})"

BOOST_VERSION=( $(ver_rs 1- ' ') )

BOOST_SP="${BOOST_SP:="_"}"
BOOST_PV="$(ver_rs 1- _)"
BOOST_P="${PN}${BOOST_SP}${BOOST_PV}"
BOOST_PATCHDIR="${BOOST_PATCHDIR:="${WORKDIR}/patches"}"
BOOST_JAM="bjam-${BOOST_SLOT}"

if [ "${BOOST_BETA}" ]; then
	BOOST_P="${BOOST_P/_beta/${BOOST_BETA}}"
fi

DESCRIPTION="boost.org c++ libraries"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2"

if [ "${BOOST_PATCHSET}" ]; then
	SRC_URI+=" http://geki.selfhost.eu/files/${BOOST_PATCHSET}"
fi

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x86-solaris ~x86-winnt"
IUSE="debug doc examples icu static-libs test +threads tools ${IUSE_BOOST_LIBS// / boost_libs_}"

RDEPEND="sys-libs/zlib[${MULTILIB_USEDEP}]
	boost_libs_mpi? ( >=virtual/mpi-2.0-r4[${MULTILIB_USEDEP},cxx,threads] )
	boost_libs_python? ( ${PYTHON_DEPS} )
	icu? ( dev-libs/icu:=[${MULTILIB_USEDEP}] )
	!icu? ( virtual/libiconv[${MULTILIB_USEDEP}] )"
DEPEND="${RDEPEND}
	app-arch/bzip2[${MULTILIB_USEDEP}]
	~dev-libs/boost-headers-${PV}
	~dev-util/boost-build-${PV}"

if [ "${BOOST_VERSION[0]}" -eq 1 -a "${BOOST_VERSION[1]}" -ge 63 ]; then
RDEPEND+=" boost_libs_python_numpy? ( dev-python/numpy[${PYTHON_USEDEP}] )"
fi

REQUIRED_USE="
	boost_libs_filesystem? (
		boost_libs_system
	)
	boost_libs_graph? (
		boost_libs_regex
	)
	boost_libs_graph_parallel? (
		boost_libs_mpi
	)
	boost_libs_mpi? (
		boost_libs_serialization
		threads
	)
	boost_libs_python? (
		${PYTHON_REQUIRED_USE}
	)
	boost_libs_wave? (
		boost_libs_filesystem
		boost_libs_thread
		boost_libs_date_time
	)
	tools? ( icu )"

if [ "${REQD_BOOST_LIBS}" ]; then
	REQUIRED_USE+="${REQD_BOOST_LIBS}"
fi

S="${WORKDIR}/${BOOST_P}"

boost_pkg_pretend()
{
	if has_version 'dev-libs/boost:0'; then
		eerror "Found installed package dev-libs/boost:0."
		eerror
		eerror "	emerge --unmerge dev-libs/boost:0"
		die
	fi

	einfo "Enable useflag[test] to run developer tests!"

	use test && CHECKREQS_DISK_BUILD="15G" check-reqs_pkg_pretend
}

boost_pkg_setup()
{
	jobs="-j$(makeopts_jobs)"

	if use test; then
		ewarn "The tests may take several hours on a recent machine"
		ewarn "but they will not fail (unless something weird happens ;-)"
		ewarn "This is because the tests depend on the used compiler/-version"
		ewarn "and the platform and upstream says that this is normal."
		ewarn "If you are interested in the results, please take a look at the"
		ewarn "generated results page:"
		ewarn "  ${ROOT}/usr/share/doc/${PF}/status/cs-$(uname).html"
	fi

	if use debug; then
		ewarn "The debug USE-flag means that a second set of the boost libraries"
		ewarn "will be built containing debug-symbols. But even though the optimization"
		ewarn "flags you might have set are not stripped, there will be a performance"
		ewarn "penalty and linking other packages against the debug version of boost"
		ewarn "is _not_ recommended."
	fi
}

boost_src_prepare()
{
	if [ -n "${BOOST_PATCHSET}" ]; then
		local p
		if [ ! -z ${BOOST_EXCLUDE+x} ]; then
			for p in "${BOOST_EXCLUDE[@]}"; do
				rm -fv "${p}"
			done
		fi

		if [ ! -z ${BOOST_PATCHES+x} ]; then
			for p in "${BOOST_PATCHES[@]}"; do
				eapply -p0 --ignore-whitespace -- "${p}"
			done
		else
			eapply -p0 --ignore-whitespace -- "${BOOST_PATCHDIR}"
		fi
	fi

	# apply user patchsets
	eapply_user

	# boost.random library: /dev/urandom support
	if [ "${BOOST_VERSION[0]}" -eq 1 -a "${BOOST_VERSION[1]}" -lt 48 ] && use random && [ -e /dev/urandom ]; then
		local lib_random="libs/random"

		mkdir -p "${lib_random}"/build
		cp -v "${FILESDIR}"/random-Jamfile "${lib_random}"/build

		sed -e 's:#ifdef __linux__:#if 1:' \
			-i "${lib_random}"/src/random_device.cpp \
			|| die
	fi

	# fix glibc conflict
	[ "${BOOST_VERSION[0]}" -eq 1 -a "${BOOST_VERSION[1]}" -lt 50 ] && _boost_fix_glibc

	# fix tests
	use test && _boost_fix_jamtest
}

boost_src_configure()
{
	# -fno-strict-aliasing: prevent invalid code
	append-flags -fno-strict-aliasing

	# we need to add the prefix, and in two cases this exceeds, so prepare
	# for the largest possible space allocation
	[[ ${CHOST} == *-darwin* ]] && append-ldflags -Wl,-headerpad_max_install_names

	# bug 298489
	if use ppc || use ppc64; then
		append-flags -mno-altivec
	fi

	local cmd="_boost_config"
	_boost_execute "${cmd} default" || die "configuration file not written"

	use boost_libs_python && _boost_execute "python_foreach_impl ${cmd}"

	multilib_copy_sources
}

boost_src_compile()
{
	# call back ...
	multilib-minimal_src_compile
}

multilib_src_compile()
{
	# ... and forth :)
	local -x BOOST_ROOT="${BUILD_DIR}"

	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} ${jobs} -q -d 1 gentoorelease"
	cmd+=" threading=${threading} ${link_opts} runtime-link=shared ${options}"
	_boost_execute "${cmd}" || die "build failed for options: ${options}"

	if use debug; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "build failed for options: ${options}"
	fi

	# feature: python abi
	if use boost_libs_python && multilib_is_native_abi; then
		cmd="_boost_python_compile"
		_boost_execute "python_foreach_impl ${cmd}"
	fi

	if use tools && multilib_is_native_abi; then
		cd "${BOOST_ROOT}/tools"

		cmd="${BOOST_JAM} ${jobs} -q -d 1 gentoorelease ${options}"
		_boost_execute "${cmd}" || die "build of tools failed"
	fi
}

boost_src_install()
{
	# call back ...
	multilib-minimal_src_install
}

multilib_src_install_all()
{
	# ... and finalize :)
	cd "${S}/status" || die

	# install tests
	if [ -f regress.log ]; then
		docinto html
		dodoc *.html "${S}"/boost.png

		docinto status
		dodoc regress.log
	fi

	cd "${S}"

	insinto /usr/share/boost-${BOOST_SLOT}

	# install Jamroot, boostcpp.jam to build external libraries
	doins Jamroot boostcpp.jam

	# install examples
	if use examples; then
		local directory
		for directory in libs/*/build libs/*/example libs/*/examples libs/*/samples; do
			[ -d "${directory}" ] && doins -r "${directory}"
		done
	fi

	# install docs
	if use doc; then
		find libs/*/* -type d \
			-iname "test" \
			-or -iname "src" \
			-or -iname "samples" \
			-or -iname "examples" \
			-or -iname "example" \
			-or -iname "build" | \
			xargs rm -rf

		insinto "/usr/share/doc/${PN}-${SLOT}/html"

		doins -r libs
		# avoid broken links
		doins LICENSE_1_0.txt
	fi
}

multilib_src_install()
{
	# ... and forth ...
	local -x BOOST_ROOT="${BUILD_DIR}"

	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local library_targets="$(_boost_library_targets)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} -q -d 1 gentoorelease threading=${threading}"
	cmd+=" ${link_opts} runtime-link=shared --includedir=${ED}/usr/include"
	cmd+=" --libdir=${ED}/usr/$(get_libdir) ${options} install"
	_boost_execute "${cmd}" || die "install failed for options: ${options}"

	if use debug; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "install failed for options: ${options}"
	fi

	# feature: python abi
	if use boost_libs_python && multilib_is_native_abi; then
		cmd="_boost_python_install"
		_boost_execute "python_foreach_impl ${cmd}"
	fi

	# install tools
	if use tools && multilib_is_native_abi; then
		cd "${BOOST_ROOT}/dist/bin" || die

		for b in *; do
			newbin "${b}" "${b}-${BOOST_SLOT}"
		done

		cd "${BOOST_ROOT}/dist" || die

		# install boostbook
		insinto /usr/share
		doins -r share/boostbook

		# slotting
		mv "${ED}/usr/share/boostbook" "${ED}/usr/share/boostbook-${BOOST_SLOT}" || die
	fi

	cd "${ED}/usr/$(get_libdir)" || die

	# debug version
	local libver="${BOOST_PV/_0}"
	local dbgver="${libver}-debug"

	# The threading libs obviously always gets the "-mt" (multithreading) tag
	# some packages seem to have a problem with it. Creating symlinks ...
	# The same goes for the mpi libs
	local libraries="thread" libs
	use boost_libs_mpi && libraries+=" mpi"

	for library in ${libraries}; do
		if use boost_libs_${library}; then
			libs="lib${PN}_${library}-mt-${libver}$(get_libname)"
			use static-libs && libs+=" lib${PN}_${library}-mt-${libver}.a"

			if use debug; then
				libs+=" lib${PN}_${library}-mt-${dbgver}$(get_libname)"
				use static-libs && libs+=" lib${PN}_${library}-mt-${dbgver}.a"
			fi

			for lib in ${libs}; do
				ln -s ${lib} \
					"${ED}"/usr/$(get_libdir)/"$(sed -e 's:-mt::' <<< ${lib})" \
					|| die
			done
		fi
	done

	# subdirectory with unversioned symlinks
	local path="/usr/$(get_libdir)/${PN}-${BOOST_SLOT}"

	dodir ${path}
	for f in $(ls -1 ${library_targets} 2>/dev/null | grep -v debug); do
		ln -s ../${f} "${ED}"/${path}/${f/-${libver}} || die
	done

	if use debug; then
		path+="-debug"

		dodir ${path}
		for f in $(ls -1 ${library_targets} 2>/dev/null | grep debug); do
			ln -s ../${f} "${ED}"/${path}/${f/-${dbgver}} || die
		done
	fi

	# boost's build system truely sucks for not having a destdir.  Because of
	# this we are forced to build with a prefix that includes the
	# DESTROOT, dynamic libraries on Darwin end messed up, referencing the
	# DESTROOT instead of the actual EPREFIX.  There is no way out of here
	# but to do it the dirty way of manually setting the right install_names.

	if [[ ${CHOST} == *-darwin* ]]; then
		einfo "Working around completely broken build-system(tm)"
		for d in "${ED}"/usr/lib/*.dylib; do
			if [ -f ${d} ]; then
				# fix the "soname"
				ebegin "  correcting install_name of ${d#${ED}}"
					install_name_tool -id "${d#${ED}}" "${d}"
				eend $?

				# fix references to other libs
				refs=$(otool -XL "${d}" | \
					sed -e '1d' -e 's:^\t::' | \
					grep "^libboost_" | \
					cut -f1 -d' ')

				for r in ${refs}; do
					ebegin "    correcting reference to ${r}"
						install_name_tool -change "${r}" \
							"${EPREFIX}/usr/lib/${r}" "${d}"
					eend $?
				done
			fi
		done
	fi
}

boost_src_test()
{
	# FIXME: python tests disabled by design
	# FIXME: multilib testing?!
	if use test; then
		local options="$(_boost_options)"

		cd "${S}/tools/regression/build" || die
		local cmd="${BOOST_JAM} -q -d 1 gentoorelease ${options} process_jam_log compiler_status"
		_boost_execute "${cmd}" || die "build of regression test helpers failed"

		cd "${S}/status" || die

		# The following is largely taken from tools/regression/run_tests.sh,
		# but adapted to our needs.

		# Run the tests & write them into a file for postprocessing
		# Some of the test-checks seem to rely on regexps
		cmd="${BOOST_JAM} ${options} --dump-tests"
		echo ${cmd}; LC_ALL="C" ${cmd} 2>&1 | tee regress.log || die

		# postprocessing
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/process_jam_log" --v2 <regress.log

		[ -n $? ] && ewarn "Postprocessing the build log failed"

		cat > comment.html <<- __EOF__
<p>Tests are run on a <a href="http://www.gentoo.org/">Gentoo</a> system.</p>
__EOF__

		# generate the build log html summary page
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/compiler_status" \
			--v2 --comment comment.html "${S}" cs-$(uname).html cs-$(uname)-links.html

		[ -n $? ] && ewarn "Generating the build log html summary page failed"

		# do some cosmetic fixes :)
		sed -e 's#http://www.boost.org/boost.png#boost.png#' -i *.html || die
	fi
}

_boost_config()
{
	[ "${#}" -gt 1 ] && die "${FUNCNAME}: wrong parameter"

	local python_abi="${1}"

	local compiler="gcc"
	local compilerVersion="$(gcc-version)"
	local compilerExecutable="$(tc-getCXX)"

	if [[ ${CHOST} == *-darwin* ]]; then
		compiler="darwin"
		compilerVersion="$(gcc-fullversion)"
	elif [[ ${CHOST} == *-winnt* ]]; then
		local version="$(tc-getCXX) -v"

		compiler="parity"

		if [[ $(${version}) == *trunk* ]]; then
			compilerVersion="trunk"
		else
			compilerVersion="$(${version}
				| sed '1q' \
				| sed -e 's#\([a-z]*\) \([0-9]\.[0-9]\.[0-9][^ \t]*\) .*#\2#')"
		fi
	elif [ "${compilerExecutable}" = "icpc" ]; then
		compiler="intel-linux"
	fi

	local jam_options=""
	use boost_libs_mpi && jam_options+="using mpi ;"

	if [ "${python_abi}" != "default" ]; then
		# boost expects libpython$(pyver) and doesn't allow overrides
		# and the build system is so creepy that it's easier just to
		# provide a symlink (linker's going to use SONAME anyway)
		# TODO: replace it with proper override one day
		ln -sf "$(python_get_library_path)" "${T}/lib${EPYTHON}$(get_libname)" || die

		local condition="";
		if [ "${BOOST_VERSION[0]}" -eq 1 -a "${BOOST_VERSION[1]}" -ge 63 ]; then
			condition="<boost.python.numpy>$(usex boost_libs_python_numpy on off)"
		fi

		if tc-is-cross-compiler; then
			jam_options+="using python : ${EPYTHON#python} : : ${SYSROOT:-${EROOT}}/usr/include/${EPYTHON} : ${SYSROOT:-${EROOT}}/usr/$(get_libdir) : ${condition} ;"
		else
			# note: we need to provide version explicitly because of
			# a bug in the build system:
			# https://github.com/boostorg/build/pull/104
			jam_options+="using python : ${EPYTHON#python} : ${PYTHON} : $(python_get_includedir) : ${T} : ${condition} ;"
		fi
	fi

	local config="user"
	[ "${python_abi}" != "default" ] && config="${EPYTHON}"

	einfo "Writing new Jamfile: ${config}-config.jam"
	cat > "${S}/${config}-config.jam" << __EOF__

variant gentoorelease : release : <optimization>none <debug-symbols>none ;
variant gentoodebug : debug : <optimization>none ;

using ${compiler} : ${compilerVersion} : ${compilerExecutable} : <cxxflags>"${CXXFLAGS}" <linkflags>"${LDFLAGS}" ;

$(sed -e "s:;:;\n:g" <<< ${jam_options})
__EOF__

	# Maintainer information:
	# The debug-symbols=none and optimization=none are not official upstream
	# flags but a Gentoo specific patch to make sure that all our CXXFLAGS
	# and LDFLAGS are being respected. Using optimization=off would for example
	# add "-O0" and override "-O2" set by the user.
}

_boost_python_compile()
{
	local options="$(_boost_python_options ${EPYTHON})"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} ${jobs} -q -d 1 gentoorelease"
	cmd+=" threading=${threading} ${link_opts} runtime-link=shared ${options}"
	_boost_execute "${cmd}" || die "build failed for options: ${options}"

	if use debug; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "build failed for options: ${options}"
	fi

	local python_dir="$(find bin.v2/libs -type d -name python)"

	for directory in ${python_dir}; do
		_boost_execute "mv ${directory} ${directory}-${EPYTHON}" \
			|| die "move '${directory}' -> '${directory}-${EPYTHON}' failed"
	done

	if use boost_libs_mpi; then
		local mpi_library="$(find bin.v2/libs/mpi/build/*/gentoo* -type f -name mpi.so)"
		local count="$(echo "${mpi_library}" | wc -l)"

		[ "${count}" -ne 1 ] && die "multiple mpi.so files found"

		_boost_execute "mv stage/lib/mpi.so stage/lib/mpi.so-${EPYTHON}" \
			|| die "move 'stage/lib/mpi.so' -> 'stage/lib/mpi.so-${EPYTHON}' failed"
	fi
}

_boost_python_install()
{
	local python_dir="$(find bin.v2/libs -type d -name python-${EPYTHON})"

	local directory
	for directory in ${python_dir}; do
		rm -rf ${directory/-${EPYTHON}}
		_boost_execute "mv ${directory} ${directory/-${EPYTHON}}" \
			|| die "move '${directory}' -> '${directory/-${EPYTHON}}' failed"
	done

	if use boost_libs_mpi; then
		local mpi_library="$(find bin.v2/libs/mpi/build/*/gentoo* -type f -name mpi.so)"
		local count="$(echo "${mpi_library}" | wc -l)"

		[ "${count}" -ne 1 ] && die "multiple mpi.so files found"

		_boost_execute "cp stage/lib/mpi.so-${EPYTHON} stage/lib/mpi.so" \
			|| die "move 'stage/lib/mpi.so-${EPYTHON}' -> 'stage/lib/mpi.so' failed"
		_boost_execute "cp stage/lib/mpi.so-${EPYTHON} ${mpi_library}" \
			|| die "move 'stage/lib/mpi.so-${EPYTHON}' -> '${mpi_library}' failed"
	fi

	local options="$(_boost_python_options ${EPYTHON})"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} -q -d 1 gentoorelease threading=${threading}"
	cmd+=" ${link_opts} runtime-link=shared --includedir=${ED}/usr/include"
	cmd+=" --libdir=${ED}/usr/$(get_libdir) ${options} install"
	_boost_execute "${cmd}" || die "install failed for options: ${options}"

	if use debug; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "install failed for options: ${options}"
	fi

	rm -rf ${python_dir} || die "clean python paths"

	# move mpi.so to python sitedir
	if use boost_libs_mpi; then
		exeinto "$(python_get_sitedir)/boost_${BOOST_SLOT}"
		doexe "${ED}/usr/$(get_libdir)/mpi.so"
		doexe "${BOOST_ROOT}"/libs/mpi/build/__init__.py

		rm -f "${ED}/usr/$(get_libdir)/mpi.so" || die "mpi cleanup failed"
	fi

	python_optimize
}

_boost_execute()
{
	if [ -n "${@}" ]; then
		# pretty print
		einfo "${@//--/\n\t--}"
		${@}

		return ${?}
	else
		return -1
	fi
}

_boost_basic_options()
{
	[ "${#}" -gt 1 ] && die "${FUNCNAME}: too many parameters"

	local config="${1:-"user"}"

	local options=""
	options+=" pch=off --user-config=${BOOST_ROOT}/${config}-config.jam --prefix=${ED}/usr"
	options+=" --boost-build=/usr/share/boost-build-${BOOST_SLOT} --layout=versioned"

	# https://svn.boost.org/trac/boost/attachment/ticket/2597/add-disable-long-double.patch
	if use sparc || { use mips && [ "${ABI}" == "o32" ]; } || use hppa || use arm || use x86-fbsd || use sh; then
		options+=" --disable-long-double"
	fi

	echo -n ${options}
}

_boost_options()
{
	local options="$(_boost_basic_options)"

	# feature: python abi
	local library
	for library in ${IUSE_BOOST_LIBS}; do
		[[ ${library} != *python* ]] && use boost_libs_${library} && options+=" --with-${library}"
	done

	options+=" $(use_enable icu) boost.locale.icu=off"

	[[ ${CHOST} == *-winnt* ]] && options+=" -sNO_BZIP2=1"

	echo -n ${options}
}

_boost_python_options()
{
	[ "${#}" -ne 1 ] && die "${FUNCNAME}: bad parameters"

	local options="$(_boost_basic_options ${1})"

	# feature: python abi
	options+=" --with-python --python-buildid=${EPYTHON#python}"

	use boost_libs_mpi && options+=" --with-mpi"

	echo -n ${options}
}

_boost_link_options()
{
	local link_opts="link=shared"
	use static-libs && link_opts+=",static"

	echo -n ${link_opts}
}

_boost_library_targets()
{
	local library_targets="*$(get_libname)"
	use static-libs && library_targets+=" *.a"
	# there is no dynamically linked version of libboost_test_exec_monitor
	use test && library_targets+=" libboost_test_exec_monitor*.a"

	echo -n ${library_targets}
}

_boost_threading()
{
	local threading="single"
	use threads && threading+=",multi"

	echo -n ${threading}
}

_boost_fix_glibc()
{
	for f in $(grep -rl "TIME_UTC" * 2>/dev/null); do
		sed -e "s:TIME_UTC:TIME_UTC_:" -i ${f}
	done
}

_boost_fix_jamtest()
{
	local jam libraries="$(find libs/ -type d -name test)"

	for library in ${libraries}; do
		jam="${library}/Jamfile.v2"

		if [ -f ${jam} ]; then
			if grep -s -q ^project "${jam}"; then
				if ! grep -s -q "import testing" "${jam}"; then
					eerror "Jamfile broken for testing: 'import testing' missing. fixing ..."

					sed -e "s:^project:import testing ;\n\0:" -i "${jam}"
				fi
			fi
		fi
	done
}

