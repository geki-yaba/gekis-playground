# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit mount-boot

DESCRIPTION="gentoo-sources based pre-compiled kernel for intel systems"
HOMEPAGE="/dev/null"
SRC_URI="${PN}-${PV}.tar.xz"

LICENSE="AS-IS"
SLOT="${PV}"
KEYWORDS="amd64"
IUSE=""

DEPEND="app-arch/xz-utils"
RDEPEND="${DEPEND}"

S="${WORKDIR}"

src_install()
{
	insinto "${ROOT}"
	doins -r "${S}"/*
}

pkg_postinst()
{
	mount-boot_pkg_preinst

	if [ -d "${ROOT}"/boot/EFI/BOOT ]
	then
		[ -e "${ROOT}"/boot/EFI/BOOT/bootx64.efi ] \
			&& rm -v "${ROOT}"/boot/EFI/BOOT/bootx64.efi

		cp -v "${ROOT}"/boot/kernel-${PV}-intel "${ROOT}"/boot/EFI/BOOT/bootx64.efi
	fi

	mount-boot_pkg_postinst
}
