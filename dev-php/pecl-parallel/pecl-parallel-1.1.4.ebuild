# Copyright 1999-2020 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PHP_EXT_NAME="parallel"
# add extension only to cli - upstream
PHP_EXT_SAPIS="cli"

USE_PHP="php7-4"

# overwrite pecl defaults for git
EGIT_COMMIT="197b5c9fd579734de87ce5bfeea5d9551caa9f22"
PHP_EXT_S="${WORKDIR}/${PHP_EXT_NAME}-${EGIT_COMMIT}"

inherit php-ext-pecl-r3

# overwrite pecl defaults for git
SRC_URI="https://github.com/krakjoe/parallel/archive/${EGIT_COMMIT}.zip -> ${PN/pecl-/}-${PV}.zip"
S="${PHP_EXT_S}"

DESCRIPTION="A succinct parallel concurrency API for PHP7"

KEYWORDS="~amd64 ~x86"
LICENSE="PHP-3.01"
SLOT="0"
IUSE=""

DEPEND="php_targets_php7-4? ( dev-lang/php:7.4[threads] )"
RDEPEND="${DEPEND}"

PATCHES=(
	"${FILESDIR}/${PN}-1.1.4-future-done-is-done.patch"
	"${FILESDIR}/${PN}-1.1.4-recv-wait.patch"
)
