# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-perl/ZMQ-LibZMQ2/ZMQ-LibZMQ2-1.40.0.ebuild,v 1.5 2014/02/16 14:14:52 zlogene Exp $

EAPI=5

MODULE_AUTHOR=DMAKI
MODULE_VERSION=1.06
inherit perl-module

DESCRIPTION="An OO libzmq 3.x wrapper for Perl"

SLOT="0"
KEYWORDS="amd64 hppa ppc ppc64 x86"
IUSE="test"

RDEPEND="
	dev-perl/ZMQ-LibZMQ3
	dev-perl/Sub-Name
"
DEPEND="${RDEPEND}
"

SRC_TEST=do
