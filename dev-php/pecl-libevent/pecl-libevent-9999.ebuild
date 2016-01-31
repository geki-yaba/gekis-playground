# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
PHP_EXT_NAME="libevent"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

USE_PHP="php7-0"
inherit php-ext-pecl-r2 git-r3

SRC_URI=""
S="${WORKDIR}/${P/pecl-}"
# php7-0 support
EGIT_REPO_URI="https://github.com/expressif/pecl-event-libevent.git"
EGIT_CHECKOUT_DIR="${S}"
KEYWORDS="~amd64 ~x86"

DESCRIPTION="PHP wrapper for libevent"
LICENSE="PHP-3"
SLOT="0"
IUSE=""

DEPEND=">=dev-libs/libevent-1.4.0"
RDEPEND="${DEPEND}"

src_unpack()
{
	git-r3_src_unpack

	pushd "${S}" 2>/dev/null
	epatch "${FILESDIR}"/libevent.c.patch
	popd 2>/dev/null

	# php-ext-source-r2_src_unpack: no git support :)
	local slot orig_s="${PHP_EXT_S}"
	for slot in $(php_get_slots); do
		cp -r "${orig_s}" "${WORKDIR}/${slot}" || die "Failed to copy source ${orig_s} to PHP target directory"
	done
}
