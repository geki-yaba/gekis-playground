# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

DESCRIPTION="Linux system headers (LFS)"

IUSE=""
SLOT="0"

SRC_URI="mirror://gentoo/gentoo-headers-base-${PV}.tar.xz"

KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-linux ~arm-linux ~x86-linux"

DEPEND="app-arch/xz-utils"
RDEPEND="!!media-sound/alsa-headers"

S=${WORKDIR}/gentoo-headers-base-${PV}

src_unpack() {
	unpack ${A}
}

# no cross-compile support
#==============================================================
export CTARGET=${CTARGET:-${CHOST}}

kernel_header_destdir() {
	[[ ${CTARGET} == ${CHOST} ]] \
		&& echo /usr/include \
		|| die
}

src_install() {
	local ddir=$(kernel_header_destdir)
	mkdir -p "${ED}"${ddir}/ || die

	cp -pPR "${S}"/include/* "${ED}"${ddir}/

	# let other packages install some of these headers
	rm -rf "${ED}"${ddir}/scsi || die #glibc/uclibc/etc...

	# hrm, build system sucks
	find "${ED}" '(' -name '.install' -o -name '*.cmd' ')' -delete
	find "${ED}" -depth -type d -delete 2>/dev/null
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
