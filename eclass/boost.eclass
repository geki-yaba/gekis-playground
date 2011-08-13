# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost libraries
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#

EAPI="4"

_boost_python="<<*:2.6>>"
PYTHON_DEPEND="python? ( ${_boost_python} )"

inherit check-reqs flag-o-matic multilib python toolchain-funcs versionator

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_prepare src_configure src_compile src_install src_test

SLOT="$(get_version_component_range 1-2)"
BOOST_MAJOR="$(replace_all_version_separators _ ${SLOT})"
BOOST_JAM="bjam-${BOOST_MAJOR}"

BOOST_PV="$(replace_all_version_separators _)"
BOOST_P="${PN}_${BOOST_PV}"
BOOST_PATCHDIR="${WORKDIR}/patches"

SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2
	http://gekis-playground.googlecode.com/files/${BOOST_PATCHSET}"

IUSE="debug doc icu static test +threads tools"

RDEPEND="sys-libs/zlib
	regex? ( icu? ( dev-libs/icu ) )
	tools? ( dev-libs/icu )"
DEPEND="${RDEPEND}
	~dev-libs/boost-headers-${PV}
	~dev-util/boost-build-${PV}"

REQUIRED_USE="graph_parallel? ( mpi )"

S="${WORKDIR}/${BOOST_P}"

boost_pkg_pretend() {
	if use test ; then
		CHECKREQS_DISK_BUILD="15120"
		check_reqs
	fi
}

boost_pkg_setup() {
	# use regular expression to read last job count or default to 1 :D
	jobs="$(sed -r -e "s:.*[-]{1,2}j(obs)?[ =]?([0-9]+):\2:" <<< "${MAKEOPTS}")"
	jobs="-j${jobs:=1}"

	if use test ; then
		ewarn "The tests may take several hours on a recent machine"
		ewarn "but they will not fail (unless something weird happens ;-)"
		ewarn "This is because the tests depend on the used compiler/-version"
		ewarn "and the platform and upstream says that this is normal."
		ewarn "If you are interested in the results, please take a look at the"
		ewarn "generated results page:"
		ewarn "  ${ROOT}usr/share/doc/${PF}/status/cs-$(uname).html"
	fi

	if use debug ; then
		ewarn "The debug USE-flag means that a second set of the boost libraries"
		ewarn "will be built containing debug-symbols. But even though the optimization"
		ewarn "flags you might have set are not stripped, there will be a performance"
		ewarn "penalty and linking other packages against the debug version of boost"
		ewarn "is _not_ recommended."
	fi

	use python && python_pkg_setup
}

boost_src_prepare() {
	EPATCH_SUFFIX="diff"
	EPATCH_FORCE="yes"
	epatch "${BOOST_PATCHDIR}"

	# boost.random library: /dev/urandom support
	if use random && [[ -e /dev/urandom ]] ; then
		local lib_random="${S}/libs/random"

		mkdir -p "${lib_random}"/build
		cp -v "${FILESDIR}"/random-Jamfile "${lib_random}"/build

		sed -e 's/#ifdef __linux__/#if 1/' \
			-i "${lib_random}"/src/random_device.cpp \
			|| die
	fi

	# fix tests
	_boost_fix_jamtest
}

boost_src_configure() {
	local compiler="gcc"
	local compilerVersion="$(gcc-version)"
	local compilerExecutable="$(tc-getCXX)"

	if [[ ${CHOST} == *-darwin* ]] ; then
		compiler="darwin"
		compilerVersion=$(gcc-fullversion)

		# we need to add the prefix, and in two cases this exceeds, so prepare
		# for the largest possible space allocation
		append-ldflags -Wl,-headerpad_max_install_names
	fi

	# -fno-strict-aliasing: prevent invalid code
	append-flags "-fno-strict-aliasing"

	# bug 298489
	if use ppc || use ppc64 ; then
		[[ $(gcc-version) > 4.3 ]] && append-flags -mno-altivec
	fi

	local jam_options=""
	use mpi && jam_options+="using mpi ;"
	use python && jam_options+="using python : $(python_get_version) : /usr : $(python_get_includedir) : $(python_get_libdir) ;"

	einfo "Writing new user-config.jam"
	cat > "${S}/user-config.jam" << __EOF__

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

boost_src_compile() {
	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} ${jobs} -q -d+2 gentoorelease"
	cmd+=" threading=${threading} ${link_opts} runtime-link=shared ${options}"
	_boost_execute "${cmd}" || die "build failed for options: ${options}"

	# ... and do the whole thing one more time to get the debug libs
	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "build failed for options: ${options}"
	fi

	if use tools ; then
		cd "${S}/tools"

		cmd="${BOOST_JAM} ${jobs} -q -d+2 gentoorelease ${options}"
		_boost_execute "${cmd}" || die "build of tools failed"
	fi
}

boost_src_install() {
	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local library_targets="$(_boost_library_targets)"
	local threading="$(_boost_threading)"

	local cmd="${BOOST_JAM} -q -d+2 gentoorelease threading=${threading}"
	cmd+=" ${link_opts} runtime-link=shared --includedir=${ED}/usr/include"
	cmd+=" --libdir=${ED}/usr/$(get_libdir) ${options} install"
	_boost_execute "${cmd}" || die "install failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "install failed for options: ${options}"
	fi

	# install tools
	if use tools ; then
		cd "${S}/dist/bin" || die

		for b in * ; do
			newbin "${b}" "${b}-${BOOST_MAJOR}"
		done

		cd "${S}/dist" || die

		# install boostbook
		insinto /usr/share
		doins -r share/boostbook

		# slotting
		mv "${ED}/usr/share/boostbook" "${ED}/usr/share/boostbook-${BOOST_MAJOR}" || die
	fi

	# install tests
	cd "${S}/status" || die

	if [ -f regress.log ] ; then
		docinto status
		dohtml *.html "${S}"/boost.png
		dodoc regress.log
	fi

	# install docs
	cd "${S}"

	if use doc ; then
		local docdir="/usr/share/doc/${PF}/html"

		find libs/*/* -iname "test" -or -iname "src" | xargs rm -rf

		insinto ${docdir}
		doins -r libs
		# avoid broken links
		doins LICENSE_1_0.txt
	fi

	cd "${ED}/usr/$(get_libdir)" || die

	# debug version
	local dbgver="${BOOST_PV/_0}-debug"

	# The threading libs obviously always gets the "-mt" (multithreading) tag
	# some packages seem to have a problem with it. Creating symlinks ...
	# The same goes for the mpi libs
	for library in mpi thread ; do
		if use ${library} ; then
			libs="lib${PN}_${library}-mt-${BOOST_PV/_0}$(get_libname)"
			use static && libs+=" lib${PN}_${library}-mt-${BOOST_PV/_0}.a"

			if use debug ; then
				libs+=" lib${PN}_${library}-mt-${dbgver}$(get_libname)"
				use static && libs+=" lib${PN}_${library}-mt-${dbgver}.a"
			fi

			for lib in ${libs} ; do
				ln -s ${lib} \
					"${ED}"/usr/$(get_libdir)/"$(sed -e 's/-mt//' <<< ${lib})" \
					|| die
			done
		fi
	done

	# Create a subdirectory with completely unversioned symlinks
	local path="/usr/$(get_libdir)/${PN}-${BOOST_MAJOR}"

	dodir ${path}
	for f in $(ls -1 ${library_targets} | grep -v debug) ; do
		ln -s ../${f} "${ED}"/${path}/${f/-${BOOST_PV/_0}} || die
	done

	if use debug ; then
		path+="-debug"

		dodir ${path}
		for f in $(ls -1 ${library_targets} | grep debug) ; do
			ln -s ../${f} "${ED}"/${path}/${f/-${dbgver}} || die
		done
	fi

	# Move the mpi.so to the right place and make sure it's slotted
	if use mpi && use python ; then
		exeinto "$(python_get_sitedir)/boost_${BOOST_MAJOR}"
		doexe "${ED}/usr/$(get_libdir)/mpi.so"

		touch "${ED}$(python_get_sitedir)/boost_${BOOST_MAJOR}/__init__.py" || die
		rm -f "${ED}/usr/$(get_libdir)/mpi.so" || die

		python_need_rebuild
	fi

	# boost's build system truely sucks for not having a destdir.  Because of
	# this we are forced to build with a prefix that includes the
	# DESTROOT, dynamic libraries on Darwin end messed up, referencing the
	# DESTROOT instead of the actual EPREFIX.  There is no way out of here
	# but to do it the dirty way of manually setting the right install_names.
	[[ -z ${ED+set} ]] && local ED=${D%/}${EPREFIX}/

	if [[ ${CHOST} == *-darwin* ]] ; then
		einfo "Working around completely broken build-system(tm)"
		for d in "${ED}"usr/lib/*.dylib ; do
			if [[ -f ${d} ]] ; then
				# fix the "soname"
				ebegin "  correcting install_name of ${d#${ED}}"
					install_name_tool -id "/${d#${ED}}" "${d}"
				eend $?

				# fix references to other libs
				refs=$(otool -XL "${d}" | \
					sed -e '1d' -e 's/^\t//' | \
					grep "^libboost_" | \
					cut -f1 -d' ')

				for r in ${refs} ; do
					ebegin "    correcting reference to ${r}"
						install_name_tool -change "${r}" \
							"${EPREFIX}/usr/lib/${r}" "${d}"
					eend $?
				done
			fi
		done
	fi
}

boost_src_test() {
	if use test ; then
		local options="$(_boost_options)"

		cd "${S}/tools/regression/build" || die
		local cmd="${BOOST_JAM} -q -d+2 gentoorelease ${options} process_jam_log compiler_status"
		_boost_execute "${cmd}" || die "build of regression test helpers failed"

		cd "${S}/status" || die

		# The following is largely taken from tools/regression/run_tests.sh,
		# but adapted to our needs.

		# Run the tests & write them into a file for postprocessing
		# Some of the test-checks seem to rely on regexps
		cmd="${BOOST_JAM} ${options} --dump-tests"
		echo ${cmd}; LC_ALL="C" ${cmd} 2>&1 | tee regress.log || die

		# Postprocessing
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/process_jam_log" --v2 <regress.log

		[[ -n $? ]] && ewarn "Postprocessing the build log failed"

		cat > comment.html <<- __EOF__
<p>Tests are run on a <a href="http://www.gentoo.org/">Gentoo</a> system.</p>
__EOF__

		# Generate the build log html summary page
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/compiler_status" \
			--v2 --comment comment.html "${S}" cs-$(uname).html cs-$(uname)-links.html

		[[ -n $? ]] && ewarn "Generating the build log html summary page failed"

		# And do some cosmetic fixes :)
		sed -e 's|http://www.boost.org/boost.png|boost.png|' -i *.html || die
	else
		einfo "Enable useflag[test] to run tests!"
	fi
}

_boost_execute() {
	if [ -n "${@}" ] ; then
		# pretty print
		einfo "${@//--/\n\t--}"
		${@}

		return ${?}
	else
		return -1
	fi
}

_boost_options() {
	local options=""
	options+=" pch=off --user-config=${S}/user-config.jam --prefix=${ED}/usr"
	options+=" --boost-build=/usr/share/boost-build-${BOOST_MAJOR} --layout=versioned"

	# https://svn.boost.org/trac/boost/attachment/ticket/2597/add-disable-long-double.patch
	if use sparc || { use mips && [[ ${ABI} = "o32" ]]; } || use hppa || use arm || use x86-fbsd || use sh; then
		options+=" --disable-long-double"
	fi

	for library in ${LIBRARIES} ; do
		use ${library} && options+=" --with-${library}"
	done

	local use_icu="disable"
	use regex && use icu && use_icu="enable"
	options+=" --${use_icu}-icu"

	echo -n ${options}
}

_boost_link_options() {
	local link_opts="link=shared"
	use static && link_opts+=",static"

	echo -n ${link_opts}
}

_boost_library_targets() {
	local library_targets="*$(get_libname)"
	use static && library_targets+=" *.a"
	# there is no dynamically linked version of libboost_test_exec_monitor
	use test && library_targets+=" libboost_test_exec_monitor*.a"

	echo -n ${library_targets}
}

_boost_threading() {
	local threading="single"
	use threads && threading+=",multi"

	echo -n ${threading}
}

_boost_fix_jamtest() {
	local jam libraries="$(find "${S}"/lib/ -type d -name test)"

	for library in ${libraries} ; do
		jam="${library}/Jamfile.v2"

		if [ -f ${jam} ] && ! grep -s -q "import testing" "${jam}" ; then
			eerror "Jamfile broken for testing. 'import testing' missing."
			eerror "Report upstream broken file: ${jam}."

			sed -e "s:project:import testing ;\n\0:" -i "${jam}"
		fi
	done
}
