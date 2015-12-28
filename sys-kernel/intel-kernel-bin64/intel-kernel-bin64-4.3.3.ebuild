# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit base mount-boot

DESCRIPTION="gentoo-sources based pre-compiled kernel for intel systems"
HOMEPAGE="/dev/null"
SRC_URI="${PN}-${PV}.tar.xz"

LICENSE="AS-IS"
SLOT="${PV}"
KEYWORDS="amd64"
IUSE=""

DEPEND="app-arch/xz-utils"
RDEPEND="${DEPEND}
	sys-kernel/gentoo-sources:${PV}"

S="${WORKDIR}"

src_install()
{
	insinto "${ROOT}"
	doins -r "${S}"/*
}

