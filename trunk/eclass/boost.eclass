# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost libraries
#

EAPI="2"

inherit check-reqs flag-o-matic multilib python toolchain-funcs versionator

EXPORT_FUNCTIONS pkg_setup src_unpack src_prepare src_configure src_compile src_install src_test

MAJOR_PV="$(replace_all_version_separators _ ${SLOT})"
BJAM="bjam-${MAJOR_PV}"

BOOST_LIB="${PN/boost-}"
BOOST_P="boost_$(replace_all_version_separators _)"
BOOST_PN="${PN/-/_}"
BOOST_PATCHSET="gentoo-boost.tar.bz2"
BOOST_PATCHDIR="${WORKDIR}/patches"

DESCRIPTION="boost.org ${BOOST_LIB} libraries for C++"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2
	http://gekis-playground.googlecode.com/files/${BOOST_PATCHSET}"

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
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

boost_pkg_setup() {
	# use regular expression to read last job count or default to 1 :D
	jobs="$(echo "${MAKEOPTS}" | sed -r -e \
		"s:.*[-]{1,2}j(obs)?[= ]?([0-9]+):\2:")"
	jobs="-j${jobs:=1}"

	if use test ; then
		CHECKREQS_DISK_BUILD="1024"
		check_reqs

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
		ewarn "will be built containing debug-symbols. You'll be able to select them"
		ewarn "using the boost-eselect module. But even though the optimization flags"
		ewarn "you might have set are not stripped, there will be a performance"
		ewarn "penalty and linking other packages against the debug version"
		ewarn "of boost is _not_ recommended."
	fi
}

boost_src_unpack() {
	local cmd targets=
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
	cmd="tar xjpf ${DISTDIR}/${BOOST_P}.tar.bz2"
	cmd+=" --exclude=${BOOST_P}/boost --exclude=${BOOST_P}/doc"
	cmd+=" --exclude=${BOOST_P}/tools --exclude=${BOOST_P}/libs"
	echo ${cmd}; ${cmd} || die

	# libraries necessary to build test tools
	if use test ; then
		for library in filesystem system test detail ; do
			if ! [[ ${targets} =~ /${library} ]] ; then
				targets+=" ${BOOST_P}/libs/${library}"
			fi
		done
	fi

	# libraries to build
	cmd="tar xjpf ${DISTDIR}/${BOOST_P}.tar.bz2 ${targets}"
	echo ${cmd}; ${cmd} || die

	# unpack generic boost patches
	unpack "${BOOST_PATCHSET}"
}

boost_src_prepare() {
	EPATCH_SUFFIX="diff" \
	EPATCH_FORCE="yes" \
	epatch "${BOOST_PATCHDIR}"
}

boost_src_configure() {
	einfo "Writing new user-config.jam"

	local compiler compilerVersion compilerExecutable mpi pystring
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
	fi;

	[[ ${BOOST_LIB} == mpi ]] && mpi="using mpi ;"
	[[ ${BOOST_LIB} == graph_parallel ]] && mpi="using mpi ;"
	[[ ${BOOST_LIB} == python ]] && pystring="using python : $(python_get_version) : /usr : $(python_get_includedir) : $(python_get_libdir) ;"

	cat > "${S}/user-config.jam" << __EOF__

variant gentoorelease : release : <optimization>none <debug-symbols>none ;
variant gentoodebug : debug : <optimization>none ;

using ${compiler} : ${compilerVersion} : ${compilerExecutable} : <cxxflags>"${CXXFLAGS}" <linkflags>"${LDFLAGS}" ;

${pystring}

${mpi}

__EOF__

	# Maintainer information:
	# The debug-symbols=none and optimization=none
	# are not official upstream flags but a Gentoo
	# specific patch to make sure that all our
	# CXXFLAGS/LDFLAGS are being respected.
	# Using optimization=off would for example add
	# "-O0" and override "-O2" set by the user.
	# Please take a look at the boost-build ebuild
	# for more infomration.

	options="${BOOST_OPTIONAL_OPTIONS}"
	if [[ ${CATEGORY} == dev-libs ]] ; then
		options+=" --with-${BOOST_LIB}"
	fi

	# https://svn.boost.org/trac/boost/attachment/ticket/2597/add-disable-long-double.patch
	if use sparc || use mips || use hppa || use arm || use x86-fbsd || use sh; then
		options+=" --disable-long-double"
	fi

	options+=" pch=off --user-config=\"${S}/user-config.jam\" \
		--boost-build=/usr/share/boost-build-${MAJOR_PV} --prefix=\"${D}/usr\" \
		--layout=versioned"

	link_opts="link=shared"
	library_targets="*$(get_libname)"
	if use static ; then
		link_opts+=",static"
		library_targets+=" *.a"
	#there is no dynamically linked version of libboost_test_exec_monitor
	elif [[ ${BOOST_LIB} == test ]] ; then
		library_targets+=" libboost_test_exec_monitor*.a"
	fi
}

boost_src_compile() {
	einfo "Using the following command to build: "
	einfo "${BJAM} ${jobs} -q -d+2 gentoorelease ${options} threading=$(_boost_threading) ${link_opts} runtime-link=shared"

	${BJAM} ${jobs} -q -d+2 gentoorelease ${options} \
		threading=$(_boost_threading) ${link_opts} runtime-link=shared \
		|| die "building boost failed"

	# ... and do the whole thing one more time to get the debug libs
	if use debug ; then
		einfo "Using the following command to build: "
		einfo "${BJAM} ${jobs} -q -d+2 gentoodebug ${options} threading=$(_boost_threading) ${link_opts} runtime-link=shared --buildid=debug"

		${BJAM} ${jobs} -q -d+2 gentoodebug ${options} \
			threading=$(_boost_threading) ${link_opts} runtime-link=shared \
			--buildid=debug \
			|| die "building boost failed"
	fi
}

boost_src_install() {
	pushd "libs/${BOOST_LIB}/build"

	einfo "Using the following command to install: "
	einfo "${BJAM} -q -d+2 gentoorelease ${options} threading=$(_boost_threading) ${link_opts} runtime-link=shared --includedir=\"${D}/usr/include\" --libdir=\"${D}/usr/$(get_libdir)\" install"

	${BJAM} -q -d+2 gentoorelease ${options} \
		threading=$(_boost_threading) ${link_opts} runtime-link=shared \
		--includedir="${D}/usr/include" \
		--libdir="${D}/usr/$(get_libdir)" \
		install || die "install failed for options '${options}'"

	if use debug ; then
		einfo "Using the following command to install: "
		einfo "${BJAM} -q -d+2 gentoodebug ${options} threading=$(_boost_threading) ${link_opts} runtime-link=shared --includedir=\"${D}/usr/include\" --libdir=\"${D}/usr/$(get_libdir)\" --buildid=debug"

		${BJAM} -q -d+2 gentoodebug ${options} \
			threading=$(_boost_threading) ${link_opts} runtime-link=shared \
			--includedir="${D}/usr/include" \
			--libdir="${D}/usr/$(get_libdir)" \
			--buildid=debug \
			install || die "install failed for options '${options}'"
	fi

	popd

	[[ ${BOOST_LIB} == python ]] || rm -rf "${D}/usr/include/boost-${MAJOR_PV}/boost"/python* || die

	# Move the mpi.so to the right place and make sure it's slotted
	if [[ ${BOOST_LIB} == mpi ]] && [[ -n "${PYVER}" ]]; then
		exeinto "$(python_get_sitedir)/boost_${MAJOR_PV}" || die
		doexe "${D}/usr/$(get_libdir)/mpi.so" || die
		touch "${D}$(python_get_sitedir)/boost_${MAJOR_PV}/__init__.py" || die
		rm -f "${D}/usr/$(get_libdir)/mpi.so" || die
	fi

	# install tests
	cd "${S}/libs/${BOOST_LIB}/test" || die

	if [ -f regress.log ] ; then
		docinto status || die
		dohtml *.html "${S}"/boost.png || die
		dodoc regress.log || die
	fi

	# install docs
	cd "${S}"
	if use doc ; then
		find libs/${BOOST_LIB}/* -iname "test" -or -iname "src" | xargs rm -rf

		insinto /usr/share/doc/${PF}/html
		doins -r libs/${BOOST_LIB} || die

		# avoid broken links
		insinto /usr/share/doc/${PF}
		doins LICENSE_1_0.txt || die

		dosym /usr/share/doc/${PF}/html/${BOOST_LIB}/doc/index.html \
			/usr/share/doc/${PF}/index.htm
	fi

	cd "${D}/usr/$(get_libdir)" || die

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
	# some packages seem to have a problem with it. Creating symlinks...
	# The same goes for the mpi libs
	if ! _boost_has_non_mt_lib ; then
		local libs="lib${BOOST_PN}-mt-${MAJOR_PV}$(get_libname)"
		use static && libs+=" lib${BOOST_PN}-mt-${MAJOR_PV}.a"

		if use debug ; then
			libs+=" lib${BOOST_PN}-mt-${MAJOR_PV}-debug$(get_libname)"
			use static && libs+=" lib${BOOST_PN}-mt-${MAJOR_PV}-debug.a"
		fi

		for lib in ${libs} ; do
			dosym ${lib} "/usr/$(get_libdir)/$(sed -e 's/-mt//' <<< ${lib})" || die
		done
	fi

	# Create a subdirectory with completely unversioned symlinks
	# and store the names in the profiles-file for eselect
	dodir /usr/$(get_libdir)/boost-${MAJOR_PV} || die

	for f in $(ls -1 ${library_targets} | grep -v debug) ; do
		dosym ../${f} /usr/$(get_libdir)/boost-${MAJOR_PV}/${f/-${MAJOR_PV}} || die
	done

	if use debug ; then
		dodir /usr/$(get_libdir)/boost-${MAJOR_PV}-debug || die

		for f in $(ls -1 ${library_targets} | grep debug) ; do
			dosym ../${f} /usr/$(get_libdir)/boost-${MAJOR_PV}-debug/${f/-${MAJOR_PV}-debug} || die
		done
	fi

	[[ ${BOOST_LIB} == python ]] && python_need_rebuild

	# boost's build system truely sucks for not having a destdir.  Because for
	# this reason we are forced to build with a prefix that includes the
	# DESTROOT, dynamic libraries on Darwin end messed up, referencing the
	# DESTROOT instread of the actual EPREFIX.  There is no way out of here
	# but to do it the dirty way of manually setting the right install_names.
	[[ -z ${ED+set} ]] && local ED=${D%/}${EPREFIX}/

	if [[ ${CHOST} == *-darwin* ]] ; then
		einfo "Working around completely broken build-system(tm)"
		for d in "${ED}"usr/lib/*.dylib ; do
			if [[ -f ${d} ]] ; then
				# fix the "soname"
				ebegin "  correcting install_name of ${d#${ED}}"
				install_name_tool -id "/${d#${D}}" "${d}"
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
	cd "${S}/tools/regression/build" || die
	einfo "Using the following command to build test helpers: "
	einfo "${BJAM} -q -d+2 gentoorelease ${options} process_jam_log compiler_status"

	${BJAM} -q -d+2 gentoorelease ${options} \
		process_jam_log compiler_status \
		|| die "building regression test helpers failed"

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
	einfo "Using the following command to test: "
	einfo "${BJAM} ${options} --dump-tests"

	# Some of the test-checks seem to rely on regexps
	LC_ALL="C" \
	${BJAM} ${options} --dump-tests 2>&1 | tee regress.log || die

	# Postprocessing
	"${S}/tools/regression/build/bin/gcc-$(gcc-version)/gentoorelease/pch-off/process_jam_log" \
		--v2 <regress.log

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
}

_boost_has_non_mt_lib() {
	# has only mt version => fail
	[[ ${BOOST_LIB} == thread ]] && return 1
	[[ ${BOOST_LIB} == mpi ]] && return 1
	return 0
}

_boost_threading() {
	local threading="single"
	if _boost_has_non_mt_lib && use threads ; then
		threading+=",multi"
	fi

	echo ${threading}
}
