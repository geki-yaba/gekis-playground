# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit cmake-utils eutils flag-o-matic

DEBIAN_URI="mirror://debian/pool/main/${PN:0:1}/${PN}"
DEBIAN_SRC="${PN}_${PV}-2.debian.tar.gz"

DESCRIPTION="MySQL database connector for C++ (mimics JDBC 4.0 API)"
HOMEPAGE="http://forge.mysql.com/wiki/Connector_C++"
SRC_URI="${DEBIAN_URI}/${DEBIAN_SRC}
	mirror://mysql/Downloads/Connector-C++/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="1.1.0"
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86"

IUSE="debug examples gcov static"

DEPEND=">=virtual/mysql-5.1
	dev-libs/boost
	dev-libs/openssl"
RDEPEND="${DEPEND}"

# cmake config that works ...
CMAKE_IN_SOURCE_BUILD="1"

src_prepare() {
	EPATCH_SUFFIX="diff"
	EPATCH_FORCE="yes"
	EPATCH_MULTI_MSG="Applying Debian patches"
	epatch "${WORKDIR}"/debian/patches
	epatch "${FILESDIR}/${PN}"-1.1.0_pre814-libdir.patch
	epatch "${FILESDIR}/${PN}"-1.1.0-clean-doc.patch
	epatch "${FILESDIR}/${PN}"-1.1.0-install-components.patch
}

src_configure() {
	# native lib/wrapper needs this!
	append-flags "-fno-strict-aliasing"

	mycmakeargs=(
		"-DMYSQLCPPCONN_BUILD_EXAMPLES=OFF"
		"-DMYSQLCPPCONN_ICU_ENABLE=OFF"
		$(cmake-utils_use debug MYSQLCPPCONN_TRACE_ENABLE)
		$(cmake-utils_use gconv MYSQLCPPCONN_GCOV_ENABLE)
	)

	# eclass/cmake-utils relies on this variable for various things
	# - how to do proper install targets? dynamic vs static? :)
	use static && CMAKE_BUILD_TYPE="GentooFull"

	cmake-utils_src_configure
}

src_compile() {
	# make
	cmake-utils_src_compile mysqlcppconn

	# make static
	use static && cmake-utils_src_compile mysqlcppconn-static
}

src_install() {
	# install
	emake DESTDIR="${D}" install/fast || die

	dodoc ANNOUNCE* CHANGES* README || die

	# examples
	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins "${S}"/examples/* || die
	fi
}
