# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit boost

RDEPEND=""
DEPEND=""

# additional libraries to install
BOOST_ADDITIONAL_LIBS="${PN/-/_unit_} ${PN/-*/_prg_exec_monitor}"
