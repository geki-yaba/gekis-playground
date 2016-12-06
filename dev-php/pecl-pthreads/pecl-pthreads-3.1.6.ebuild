# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="6"
PHP_EXT_NAME="pthreads"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

USE_PHP="php7-0 php7-1"
inherit php-ext-pecl-r3

DESCRIPTION="PHP wrapper for pthreads"

KEYWORDS="~amd64 ~x86"
LICENSE="PHP-3"
SLOT="0"
IUSE=""

DEPEND=""
RDEPEND=""
