# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
PHP_EXT_NAME="pthreads"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

USE_PHP="php7-0"
inherit php-ext-pecl-r2

KEYWORDS="~amd64 ~x86"

DESCRIPTION="PHP wrapper for pthreads"
LICENSE="PHP-3"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"
