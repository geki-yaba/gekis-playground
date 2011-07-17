# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: Selectively build/install boost tools
#          - Wrap boost eclass
#

#
# TODO:	proper documentation of eclass like portage/eclass/java-utils-2.eclass
#

EAPI="4"

inherit boost

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_configure src_compile src_install src_test

DESCRIPTION="boost.org tools"
HOMEPAGE="http://www.boost.org/"
SRC_URI="mirror://sourceforge/boost/${BOOST_P}.tar.bz2
	http://gekis-playground.googlecode.com/files/gentoo-boost.tar.bz2"

LICENSE="Boost-1.0"
SLOT="$(get_version_component_range 1-2)"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"

boost-tools_pkg_pretend() {
	boost_pkg_pretend
}

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
		docinto status
		dohtml *.html "${S}"/boost.png
		dodoc regress.log
	fi

	# install docs
	cd "${S}"
	if use doc ; then
		find libs/*/* -iname "test" -or -iname "src" | xargs rm -rf

		dohtml -A pdf,txt,cpp,hpp \
			*.{htm,html,png,css} \
			-r doc

		dohtml -A pdf,txt \
			-r tools

		insinto /usr/share/doc/${PF}/html
		doins -r libs

		# To avoid broken links
		insinto /usr/share/doc/${PF}/html
		doins LICENSE_1_0.txt
	fi

	# install tools
	cd "${S}/dist/bin" || die

	for b in * ; do
		newbin "${b}" "${b}-${MAJOR_PV}"
	done

	cd "${S}/dist" || die

	# install boostbook
	insinto /usr/share
	doins -r share/boostbook

	# Append version postfix for slotting
	mv "${ED}/usr/share/boostbook" "${D}/usr/share/boostbook-${MAJOR_PV}" || die
}

boost-tools_src_test() {
	boost_src_test
}
