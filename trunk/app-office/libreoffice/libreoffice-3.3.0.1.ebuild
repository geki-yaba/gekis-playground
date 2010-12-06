# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit libreoffice

# config
MY_P="${PN}-build-${PV}"

# keywords
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux"

# source
SRC_URI+=" ${LIBRE_SRC}/${MY_P}.tar.gz"

# root
S="${WORKDIR}/${MY_P}"
