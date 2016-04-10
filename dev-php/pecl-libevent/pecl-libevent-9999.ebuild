# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
PHP_EXT_NAME="libevent"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

# php7-0 support
USE_PHP="php7-0"
inherit php-ext-pecl-r2

DESCRIPTION="PHP wrapper for libevent"

EGIT_COMMIT="3784a2b0c52e20d3d4314dccee45c6f7604d22d0"
#EGIT_COMMIT="6887d83fcb315d5dfb6d27e92bc2e979bea69169"
#EGIT_COMMIT="ac255b86138de94d53388487e52d87fa9b92e278"
#EGIT_COMMIT="9e72744ce6224beafc7b54ce2a3a990f1c552a5a"
SRC_URI="https://github.com/expressif/pecl-event-libevent/archive/${EGIT_COMMIT}.zip -> ${PN}-${EGIT_COMMIT}.zip"

KEYWORDS="~amd64 ~x86"
LICENSE="PHP-3"
SLOT="0"
IUSE=""

DEPEND=">=dev-libs/libevent-1.4.0"
RDEPEND="${DEPEND}"

S="${WORKDIR}/pecl-event-libevent-${EGIT_COMMIT}"

src_unpack()
{
	default

	# php-ext-source-r2_src_unpack: no git support :)
	local slot orig_s="${S}"
	for slot in $(php_get_slots); do
		cp -r "${orig_s}" "${WORKDIR}/${slot}" || die "Failed to copy source ${orig_s} to PHP target directory"
	done
}
