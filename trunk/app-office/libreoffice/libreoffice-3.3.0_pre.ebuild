# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit libreoffice

# keywords
KEYWORDS=""

# root
S="${WORKDIR}/${PN}"

# git clone
CLONE_DIR="${S}/clone"

# exclude patches
EPATCH_EXCLUDE="$(for f in "${FILESDIR}"/33_*; do basename $f; done)"
