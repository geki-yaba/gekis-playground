# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost tools
#          - Wrap boost eclass
#

EAPI="2"

inherit boost

EXPORT_FUNCTIONS pkg_setup src_unpack src_prepare src_configure src_compile src_install src_test

DESCRIPTION="boost.org tools"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2
	http://gekis-playground.googlecode.com/files/gentoo-boost.tar.bz2"

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

boost-tools_pkg_setup() {
	boost_pkg_setup
}

boost-tools_src_unpack() {
	unpack ${A}
}

boost-tools_src_prepare() {
	boost_src_prepare
}

boost-tools_src_configure() {
	boost_src_configure
}

boost-tools_src_compile() {
	local cmd
	local options="$(_boost_options)"

	cd "${S}/tools"
	cmd="${BJAM} ${jobs} -q -d+2 gentoorelease ${options}"
	_boost_execute "${cmd}" || die "build of tools failed"
}

boost-tools_src_install() {
	# install tests
	cd "${S}/status" || die

	if [ -f regress.log ] ; then
		docinto status || die
		dohtml *.html "${S}"/boost.png || die
		dodoc regress.log || die
	fi

	# install docs
	cd "${S}"
	if use doc ; then
		find libs/*/* -iname "test" -or -iname "src" | xargs rm -rf

		dohtml -A pdf,txt,cpp,hpp \
			*.{htm,html,png,css} \
			-r doc more people wiki || die

		dohtml -A pdf,txt \
			-r tools || die

		insinto /usr/share/doc/${PF}/html
		doins -r libs || die

		# To avoid broken links
		insinto /usr/share/doc/${PF}/html
		doins LICENSE_1_0.txt || die
	fi

	# install tools
	cd "${S}/dist/bin" || die

	for b in * ; do
		newbin "${b}" "${b}-${MAJOR_PV}" || die
	done

	cd "${S}/dist" || die

	# install boostbook
	insinto /usr/share || die
	doins -r share/boostbook || die

	# Append version postfix for slotting
	mv "${D}/usr/share/boostbook" "${D}/usr/share/boostbook-${MAJOR_PV}" || die
}

boost-tools_src_test() {
	boost_src_test
}
