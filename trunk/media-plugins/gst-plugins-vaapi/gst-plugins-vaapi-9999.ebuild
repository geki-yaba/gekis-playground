# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

EGIT_REPO_URI="git://gitorious.org/vaapi/gstreamer-vaapi.git"
EGIT_BOOTSTRAP="[ ! -f gtk-doc.make ] && echo 'EXTRA_DIST =' > gtk-doc.make; eautoreconf"

inherit autotools-utils git-2

DESCRIPTION="GStreamer VA-API plugins"
HOMEPAGE="http://gitorious.org/vaapi/gstreamer-vaapi"
SRC_URI=""

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS=""

IUSE="doc opengl static-libs"

DEPEND="dev-libs/glib:2
	>=media-libs/gstreamer-0.10.36:0.10
	>=media-libs/gst-plugins-base-0.10.36:0.10
	x11-libs/libva
	x11-libs/libX11
	>=virtual/ffmpeg-0.6[vaapi]
	doc? ( dev-util/gtk-doc )
	opengl? ( virtual/opengl )"

RDEPEND="${DEPEND}"

DOCS=(AUTHORS README COPYING NEWS)

MY_PN="gstreamer-vaapi"
S="${WORKDIR}/${MY_PN}"

src_configure() {
	local myeconfargs=(
		$(use_enable opengl glx)
		$(use_enable opengl vaapi-glx)
		$(use_enable opengl vaapisink-glx)
	)
	autotools-utils_src_configure
}
