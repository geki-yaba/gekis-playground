# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PHP_EXT_NAME="pthreads"
# add extension only to cli - upstream
PHP_EXT_SAPIS="cli"

USE_PHP="php7-2"

# overwrite pecl defaults for git
EGIT_COMMIT="e25675dee989a2e15b81da6c0e215d22bacff86a"
PHP_EXT_S="${WORKDIR}/${PHP_EXT_NAME}-${EGIT_COMMIT}"

inherit php-ext-pecl-r3

# overwrite pecl defaults for git
SRC_URI="https://github.com/krakjoe/pthreads/archive/${EGIT_COMMIT}.zip -> ${PN/pecl-/}-${PV}.zip"
S="${PHP_EXT_S}"

DESCRIPTION="Threading API for PHP"

KEYWORDS="~amd64 ~x86"
LICENSE="PHP-3.01"
SLOT="0"
IUSE=""

DEPEND="php_targets_php7-2? ( dev-lang/php:7.2[threads] )"
RDEPEND="${DEPEND}"
