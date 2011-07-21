# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost libraries
#

#
# TODO:	proper documentation of eclass like portage/eclass/xorg-2.eclass
#		refactor from split-boost to single-boost with useflags
#

EAPI="4"

inherit check-reqs flag-o-matic multilib toolchain-funcs versionator

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_configure src_compile src_install src_test

SLOT="$(get_version_component_range 1-2)"
MAJOR_PV="$(replace_all_version_separators _ ${SLOT})"
BJAM="bjam-${MAJOR_PV}"

BOOST_LIB="${PN/boost-}"
BOOST_PN="${PN/-/_}"
BOOST_PV="$(replace_all_version_separators _)"
BOOST_P="boost_${BOOST_PV}"
BOOST_PATCHDIR="${WORKDIR}/patches"

# patchset
if [[ ${SLOT} > 1.46 ]]; then
	BOOST_PATCHSET="gentoo-boost-1.47.0.tar.bz2"
else
	BOOST_PATCHSET="gentoo-boost.tar.bz2"
fi

DESCRIPTION="boost.org ${BOOST_LIB} libraries for C++"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2
	http://gekis-playground.googlecode.com/files/${BOOST_PATCHSET}"

LICENSE="Boost-1.0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE="debug doc static test"

# build threaded libraries? argh, clean ...
if [[ ${BOOST_LIB} != thread ]] && [[ ${BOOST_LIB} != mpi ]] ; then
	IUSE+=" +threads"
fi

RDEPEND="sys-libs/zlib"
DEPEND="${RDEPEND}
	~dev-libs/boost-headers-${PV}
	~dev-util/boost-build-${PV}"

S="${WORKDIR}/${BOOST_P}"

boost_pkg_pretend() {
	if use test ; then
		CHECKREQS_DISK_BUILD="15120"
		check_reqs
	fi
}

boost_pkg_setup() {
	# use regular expression to read last job count or default to 1 :D
	jobs="$(echo "${MAKEOPTS}" | sed -r -e \
		"s:.*[-]{1,2}j(obs)?[= ]?([0-9]+):\2:")"
	jobs="-j${jobs:=1}"

	if use test ; then
		ewarn "The tests may take several hours on a recent machine"
		ewarn "but they will not fail (unless something weird happens ;-)"
		ewarn "This is because the tests depend on the used compiler/-version"
		ewarn "and the platform and upstream says that this is normal."
		ewarn "If you are interested in the results, please take a look at the"
		ewarn "generated results page:"
		ewarn "  ${ROOT}usr/share/doc/${PF}/status/cs-$(uname).html"
		ebeep 5
	fi

	if use debug ; then
		ewarn "The debug USE-flag means that a second set of the boost libraries"
		ewarn "will be built containing debug-symbols. But even though the optimization"
		ewarn "flags you might have set are not stripped, there will be a performance"
		ewarn "penalty and linking other packages against the debug version of boost"
		ewarn "is _not_ recommended."
	fi
}

boost_src_unpack() {
	local cmd targets=""
	for depend in ${DEPEND} ${CATEGORY}/${PN}:${SLOT} ; do
		# no headers
		[[ ${depend} == dev-libs/boost-headers:${SLOT} ]] && continue

		if [[ ${depend} =~ dev-libs/boost-(.*): ]] ; then
			targets+=" ${BOOST_P}/libs/${BASH_REMATCH[1]}"
		fi
	done

	# additional targets
	for target in ${BOOST_ADDITIONAL_TARGETS} ; do
		targets+=" ${BOOST_P}/libs/${target}"
	done

	# generic data
	cmd="tar xjpf ${DISTDIR}/${BOOST_P}.tar.bz2 --exclude=${BOOST_P}/boost"
	cmd+=" --exclude=${BOOST_P}/doc --exclude=${BOOST_P}/libs"

	# libraries necessary to build test tools
	if use test ; then
		for library in filesystem system test detail ; do
			if ! [[ ${targets} =~ /${library} ]] ; then
				targets+=" ${BOOST_P}/libs/${library}"
			fi
		done
	# exclude tools otherwise
	else
		cmd+=" --exclude=${BOOST_P}/tools"
	fi

	# extract generic data
	_boost_execute "${cmd}" || die

	# libraries to build
	cmd="tar xjpf ${DISTDIR}/${BOOST_P}.tar.bz2 ${targets}"
	_boost_execute "${cmd}" || die

	# unpack generic boost patches
	unpack "${BOOST_PATCHSET}"
}

boost_src_prepare() {
	EPATCH_SUFFIX="diff"
	EPATCH_FORCE="yes"
	epatch "${BOOST_PATCHDIR}"

	# fix tests
	_boost_fix_jamtest
}

boost_src_configure() {
	einfo "Writing new user-config.jam"

	local compiler compilerVersion compilerExecutable
	if [[ ${CHOST} == *-darwin* ]] ; then
		compiler=darwin
		compilerVersion=$(gcc-fullversion)
		compilerExecutable=$(tc-getCXX)
		# we need to add the prefix, and in two cases this exceeds, so prepare
		# for the largest possible space allocation
		append-ldflags -Wl,-headerpad_max_install_names
	else
		compiler=gcc
		compilerVersion=$(gcc-version)
		compilerExecutable=$(tc-getCXX)
	fi

	# Using -fno-strict-aliasing to prevent possible creation of invalid code.
	append-flags "-fno-strict-aliasing"

	# bug 298489
	if use ppc || use ppc64 ; then
		[[ $(gcc-version) > 4.3 ]] && append-flags -mno-altivec
	fi

	cat > "${S}/user-config.jam" << __EOF__

variant gentoorelease : release : <optimization>none <debug-symbols>none ;
variant gentoodebug : debug : <optimization>none ;

using ${compiler} : ${compilerVersion} : ${compilerExecutable} : <cxxflags>"${CXXFLAGS}" <linkflags>"${LDFLAGS}" ;

${jam_options}

__EOF__

	# Maintainer information:
	# The debug-symbols=none and optimization=none are not official upstream
	# flags but a Gentoo specific patch to make sure that all our CXXFLAGS
	# and LDFLAGS are being respected. Using optimization=off would for example
	# add "-O0" and override "-O2" set by the user.
}

boost_src_compile() {
	local cmd
	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local threading="$(_boost_threading)"

	cmd="${BJAM} ${jobs} -q -d+2 gentoorelease threading=${threading}"
	cmd+=" ${link_opts} runtime-link=shared ${options}"
	_boost_execute "${cmd}" || die "build failed for options: ${options}"

	# ... and do the whole thing one more time to get the debug libs
	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "build failed for options: ${options}"
	fi
}

boost_src_install() {
	local cmd
	local options="$(_boost_options)"
	local link_opts="$(_boost_link_options)"
	local library_targets="$(_boost_library_targets)"
	local threading="$(_boost_threading)"

	pushd "libs/${BOOST_LIB}/build" >/dev/null

	cmd="${BJAM} -q -d+2 gentoorelease threading=${threading} ${link_opts}"
	cmd+=" runtime-link=shared --includedir=${ED}/usr/include"
	cmd+=" --libdir=${ED}/usr/$(get_libdir) ${options} install"
	_boost_execute "${cmd}" || die "install failed for options: ${options}"

	if use debug ; then
		cmd="${cmd/gentoorelease/gentoodebug --buildid=debug}"
		_boost_execute "${cmd}" || die "install failed for options: ${options}"
	fi

	popd >/dev/null

	# install tests
	cd "${S}/libs/${BOOST_LIB}/test" || die

	if [ -f regress.log ] ; then
		docinto status
		dohtml *.html "${S}"/boost.png
		dodoc regress.log
	fi

	# install docs
	cd "${S}"
	if use doc ; then
		local docdir="/usr/share/doc/${PF}"
		find libs/${BOOST_LIB}/* -iname "test" -or -iname "src" | xargs rm -rf

		insinto ${docdir}/html
		doins -r libs/${BOOST_LIB}

		# avoid broken links
		insinto ${docdir}
		doins LICENSE_1_0.txt

		ln -s "${ED}"/${docdir}/html/${BOOST_LIB}/doc/index.html \
			"${ED}"/${docdir}/index.htm
	fi

	cd "${ED}/usr/$(get_libdir)" || die

	# paths
	local path="/usr/$(get_libdir)/boost"
	local dbgver="${MAJOR_PV}-debug"

	# FIXME: build against installed boost libraries
	# libraries may have additional libraries with funny names; catch them
	for f in $(find ! -type d) ; do
		[[ ${f} =~ ${BOOST_PN} ]] && continue

		local found=
		for lib in ${BOOST_ADDITIONAL_LIBS} ; do
			[[ ${f} =~ ${lib} ]] && found=1
		done

		# found? continue
		[ ${found} ] && continue

		# remove
		rm -v ${f}
	done

	# The threading libs obviously always gets the "-mt" (multithreading) tag
	# some packages seem to have a problem with it. Creating symlinks ...
	# The same goes for the mpi libs
	if ! _boost_has_non_mt_lib ; then
		local libs="lib${BOOST_PN}-mt-${BOOST_PV/_0}$(get_libname)"
		use static && libs+=" lib${BOOST_PN}-mt-${BOOST_PV/_0}.a"

		if use debug ; then
			libs+=" lib${BOOST_PN}-mt-${dbgver}$(get_libname)"
			use static && libs+=" lib${BOOST_PN}-mt-${dbgver}.a"
		fi

		for lib in ${libs} ; do
			ln -s ${lib} \
				"${ED}"/usr/$(get_libdir)/"$(sed -e 's/-mt//' <<< ${lib})" \
				|| die
		done
	fi

	# Create a subdirectory with completely unversioned symlinks
	dodir ${path}-${MAJOR_PV}

	for f in $(ls -1 ${library_targets} | grep -v debug) ; do
		ln -s ../${f} \
			"${ED}"/${path}-${MAJOR_PV}/${f/-${BOOST_PV/_0}} \
			|| die
	done

	if use debug ; then
		dodir ${path}-${dbgver}

		for f in $(ls -1 ${library_targets} | grep debug) ; do
			ln -s ../${f} \
				"${ED}"/${path}-${dbgver}/${f/-${dbgver}} \
				|| die
		done
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
					install_name_tool -change \
						"${r}" \
						"${EPREFIX}/usr/lib/${r}" \
						"${d}"
					eend $?
				done
			fi
		done
	fi
}

boost_src_test() {
	if use test ; then
		local cmd
		local options="$(_boost_options)"

		cd "${S}/tools/regression/build" || die
		cmd="${BJAM} -q -d+2 gentoorelease ${options} process_jam_log compiler_status"
		_boost_execute "${cmd}" || die "build of regression test helpers failed"

		local path="${S}"

		if [[ ${CATEGORY} == dev-libs ]] ; then
			path+="/libs/${BOOST_LIB}/test"
		else
			path+="/status"
		fi

		cd "${path}" || die

		# The following is largely taken from tools/regression/run_tests.sh,
		# but adapted to our needs.

		# Run the tests & write them into a file for postprocessing
		# Some of the test-checks seem to rely on regexps
		cmd="${BJAM} ${options} --dump-tests"
		echo ${cmd}; LC_ALL="C" ${cmd} 2>&1 | tee regress.log || die

		# Postprocessing
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/process_jam_log" --v2 <regress.log

		#[[ -n $? ]] && die "Postprocessing the build log failed"

		cat > comment.html <<- __EOF__
<p>Tests are run on a <a href="http://www.gentoo.org/">Gentoo</a> system.</p>
__EOF__

		# Generate the build log html summary page
		"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/compiler_status" \
			--v2 --comment comment.html "${S}" cs-$(uname).html cs-$(uname)-links.html

		[[ -n $? ]] && die "Generating the build log html summary page failed"

		# And do some cosmetic fixes :)
		sed -e 's|http://www.boost.org/boost.png|boost.png|' -i *.html || die
	else
		einfo "Enable useflag[test] to actually run tests!"
	fi
}

_boost_execute() {
	# pretty print
	einfo "${@//--/\n\t--}"
	${@}
	return ${?}
}

_boost_has_non_mt_lib() {
	# has only mt version => fail
	[[ ${BOOST_LIB} == thread ]] && return 1
	[[ ${BOOST_LIB} == mpi ]] && return 1
	return 0
}

_boost_options() {
	local options="${BOOST_OPTIONAL_OPTIONS}"
	# https://svn.boost.org/trac/boost/attachment/ticket/2597/add-disable-long-double.patch
	if use sparc || use mips || use hppa || use arm || use x86-fbsd || use sh; then
		options+=" --disable-long-double"
	fi

	options+=" pch=off --user-config=${S}/user-config.jam --prefix=${ED}/usr"
	options+=" --boost-build=/usr/share/boost-build-${MAJOR_PV} --layout=versioned"

	if [[ ${CATEGORY} == dev-libs ]] ; then
		options+=" --with-${BOOST_LIB}"
	fi

	echo -n ${options}
}

_boost_link_options() {
	local link_opts="link=shared"
	if use static ; then
		link_opts+=",static"
	fi

	echo -n ${link_opts}
}

_boost_library_targets() {
	local library_targets="*$(get_libname)"
	# there is no dynamically linked version of libboost_test_exec_monitor
	if [[ ${BOOST_LIB} == test ]] ; then
		library_targets+=" libboost_test_exec_monitor*.a"
	elif use static ; then
		library_targets+=" *.a"
	fi

	echo -n ${library_targets}
}

_boost_threading() {
	local threading="single"
	if _boost_has_non_mt_lib && use threads ; then
		threading+=",multi"
	fi

	echo -n ${threading}
}

_boost_fix_jamtest() {
	# boost-1.45
	if [[ ${SLOT} == 1.45 ]] && use test ; then
		local libraries="${S}/libs/${BOOST_LIB}"
		if [[ ${CATEGORY} != dev-libs ]] ; then
			libraries="$(find "${S}"/lib/ -type d -name test)"
		fi

		for library in ${libraries} ; do
			local jam="${library}/Jamfile.v2"

			if [ -f ${jam} ] && ! grep -s -q "import testing" "${jam}" ; then
				sed -e "s:project:import testing ;\n\0:" -i "${jam}"
			fi
		done
	fi
}
