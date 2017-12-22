# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"
PHP_EXT_NAME="pthreads"
PHP_EXT_INI="yes"
PHP_EXT_ZENDEXT="no"

USE_PHP="php7-0 php7-1"
inherit php-ext-pecl-r3

DESCRIPTION="Threading API for PHP"

KEYWORDS="~amd64 ~x86"
LICENSE="PHP-3.01"
SLOT="0"
IUSE=""

DEPEND="php_targets_php7-0? ( dev-lang/php:7.0[threads] )
	php_targets_php7-1? ( dev-lang/php:7.1[threads] )"
RDEPEND="${DEPEND}"
