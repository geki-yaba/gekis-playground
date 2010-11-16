# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit libreoffice

# config
MY_PV="$(get_version_component_range 1-2)"

# keywords
KEYWORDS=""

# source
SRC_URI+=" mono? ( ${GO_SRC}/DEV300/ooo-cli-prebuilt-${MY_PV}.tar.bz2 )"

# root
S="${WORKDIR}/${PN}"

# git clone
CLONE_DIR="${S}/clone"
