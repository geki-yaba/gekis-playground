# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="Linux system headers (LFS)"

IUSE=""
SLOT="0"

SRC_URI="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-${PV}.tar.xz"

KEYWORDS="~amd64"

DEPEND="app-arch/xz-utils"
RDEPEND="!!media-sound/alsa-headers"

S="${WORKDIR}/linux-${PV}"

src_unpack() {
	unpack ${A}
}

# no cross-compile support
#==============================================================
export CTARGET="${CTARGET:-${CHOST}}"

tc-arch-kernel()
{
	case ${CHOST} in
		i?86*)
			echo X86
			;;
		x86_64*)
			echo X86_64
			;;
		*)
			die
			;;
	esac
}

kernel_header_destdir() {
	[[ ${CTARGET} == ${CHOST} ]] \
		&& echo /usr/include \
		|| die
}

pkg_pretend()
{
	local tmp
	
	# test for arch
	tmp="$(tc-arch-kernel)"

	# test for host
	tmp="$(kernel_header_destdir)"
}

src_compile() {
	emake ARCH=$(tc-arch-kernel) mrproper || die
	emake ARCH=$(tc-arch-kernel) INSTALL_HDR_PATH=dest headers_install || die
}

src_install() {
	# let other packages install some of these headers
	rm -rf "${S}"/dest/scsi || die #glibc/uclibc/etc...

	# hrm, build system sucks
	find "${S}"/dest '(' -name '.install' -o -name '*.cmd' ')' -delete
	find "${S}"/dest -depth -type d -delete 2>/dev/null

	local ddir="$(kernel_header_destdir)"
	mkdir -p "${ED}"${ddir}/ || die

	cp -pPR "${S}"/dest/include/* "${ED}"${ddir}/
}

src_test() {
	# Make sure no uapi/ include paths are used by accident.
	egrep -r \
		-e '# *include.*["<]uapi/' \
		"${D}" && die "#include uapi/xxx detected"

	einfo "Possible unescaped attribute/type usage"
	egrep -r \
		-e '(^|[[:space:](])(asm|volatile|inline)[[:space:](]' \
		-e '\<([us](8|16|32|64))\>' \
		.

	einfo "Missing linux/types.h include"
	egrep -l -r -e '__[us](8|16|32|64)' "${ED}" | xargs grep -L linux/types.h

	emake ARCH=$(tc-arch-kernel) headers_check
}
