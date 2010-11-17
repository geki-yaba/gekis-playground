# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit libreoffice

# config
MY_P="${PN}-build-${PV}"
MY_PV="3.3"

# keywords
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux"

# source
SRC_URI+=" ${LIBRE_SRC}/${MY_P}.tar.gz
	mono? ( ${GO_SRC}/DEV300/ooo-cli-prebuilt-${MY_PV}.tar.bz2 )"

# root
S="${WORKDIR}/${MY_P}"
