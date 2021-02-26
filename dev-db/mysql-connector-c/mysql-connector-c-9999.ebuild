# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="C client library for MariaDB/MySQL"
HOMEPAGE="https://dev.mysql.com/downloads/"
LICENSE="GPL-2"

SRC_URI=""
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 sparc ~x86"

DEPEND="dev-db/mariadb-connector-c[mysqlcompat]"
RDEPEND="${DEPEND}"
BDEPEND=""
