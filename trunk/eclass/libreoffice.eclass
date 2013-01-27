# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: unified build of libreoffice
#

#
# TODO: proper documentation of eclass like portage/eclass/xorg-2.eclass
#

EAPI="5"

_libreoffice_java="1.6"
_libreoffice_kde="never"
_libreoffice_qt="4.7.4"

CMAKE_REQUIRED="${_libreoffice_kde}"
KDE_REQUIRED="${_libreoffice_kde}"
QT_MINIMAL="${_libreoffice_qt}"

PYTHON_COMPAT=( python3_3 )
PYTHON_REQ_USE="threads,xml"

inherit autotools base bash-completion-r1 boost-utils check-reqs flag-o-matic \
	java-pkg-opt-2 kde4-base multilib nsplugins pax-utils python-single-r1 \
	versionator git-2

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_configure src_compile src_test src_install pkg_preinst pkg_postinst pkg_postrm

DESCRIPTION="LibreOffice - a productivity suite (geki version)"
HOMEPAGE="http://www.libreoffice.org/"

SLOT="0"

LICENSE="|| ( LGPL-3 MPL-1.1 )"
RESTRICT="binchecks mirror"

IUSE="bluetooth +branding custom-cflags dbus debug eds +extensions +fonts glib
gnome graphite gstreamer gtk gtk3 kde nsplugin odbc odk opengl pdfimport
postgres +scripting telepathy test webdav"

# config
LV2="$(get_version_component_range 1-2)"
LV3="$(get_version_component_range 1-3)"

# available template languages
LANGUAGES="de en en_GB en_ZA es fr hu it"

for language in ${LANGUAGES}; do
	IUSE+=" linguas_${language}"
done

# extensions
EXTENSIONS="barcode ct2n diagram google-docs hunart languagetool mysql-connector
nlpsolver numbertext presenter-minimizer report-builder typo validator
watch-window wiki-publisher"

for extension in ${EXTENSIONS}; do
	IUSE+=" libreoffice_extension_${extension}"
done

# scripting
SCRIPTINGS="beanshell javascript"

for scripting in ${SCRIPTINGS}; do
	IUSE+=" libreoffice_scripting_${scripting}"
done

# paths
LIBRE_URI="http://dev-www.libreoffice.org/bundles"
EXT_URI="http://ooo.itc.hu/oxygenoffice/download/libreoffice"
BRAND_URI="http://dev.gentoo.org/~dilfridge/distfiles"

# branding
BRAND_SRC="${PN}-branding-gentoo-0.7.tar.xz"
SRC_URI="branding? ( ${BRAND_URI}/${BRAND_SRC} )"

# modules
MODULES="core help"

# patches
PATCHES=( "${FILESDIR}" )

CDEPEND="${PYTHON_DEPS}
	bluetooth? ( net-wireless/bluez )
	dbus? ( dev-libs/dbus-glib )
	eds? ( gnome-extra/evolution-data-server )
	gnome? ( gnome-base/gconf:2 )
	graphite? ( media-gfx/graphite2 )
	gstreamer? ( media-libs/gstreamer:1.0
		media-libs/gst-plugins-base:1.0 )
	gtk? ( x11-libs/gtk+:2 )
	gtk3? ( x11-libs/gtk+:3 )
	kde? ( x11-libs/qt-core[glib?]
		x11-libs/qt-gui
		kde-base/kdelibs
		kde-base/kstyles )
	opengl? ( virtual/opengl virtual/glu )
	pdfimport? ( app-text/poppler[cxx] )
	postgres? ( dev-db/postgresql-base[kerberos] )
	webdav? ( net-libs/neon )
	libreoffice_extension_mysql-connector? ( dev-db/mysql-connector-c++:0 )
	libreoffice_extension_report-builder? ( dev-java/commons-logging:0 )
	libreoffice_extension_wiki-publisher? ( dev-java/commons-codec:0
		dev-java/commons-httpclient:3
		dev-java/commons-lang:2.1
		dev-java/commons-logging:0
		dev-java/tomcat-servlet-api:3.0 )
	libreoffice_scripting_beanshell? ( dev-java/bsh )
	telepathy? ( >=net-libs/telepathy-glib-0.18.0 )
	  app-text/hunspell
	  app-text/libexttextcat
	  app-text/liblangtag
	  app-text/libmspub
	  app-text/libwpd:0.9[tools]
	  app-text/libwpg:0.2
	  app-text/libwps:0
	  app-text/mythes
	>=dev-cpp/clucene-2.3
	  dev-cpp/libcmis:0.3
	  dev-libs/expat
	  dev-libs/hyphen
	  dev-libs/icu:=
	  dev-libs/jemalloc
	>=dev-libs/liborcus-0.3
	  dev-libs/libxml2
	  dev-libs/libxslt
	  dev-libs/nspr
	  dev-libs/nss
	  dev-libs/openssl
	  dev-libs/redland[ssl]
	  media-libs/fontconfig
	  media-libs/freetype:2
	  media-libs/lcms:2
	  media-libs/libcdr
	  media-libs/libpng
	  media-libs/libvisio
	  net-misc/curl
	  net-nds/openldap
	  net-print/cups
	  sci-mathematics/lpsolve
	  sys-libs/zlib
	  x11-libs/libXrender
	  x11-libs/cairo[X,svg]
	  x11-libs/libXaw
	  x11-libs/libXinerama
	  x11-libs/libXrandr
	  x11-libs/libXtst
	  x11-libs/startup-notification
	  virtual/jpeg"

RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-${_libreoffice_java} )"

DEPEND="${CDEPEND}
	java? ( >=virtual/jdk-${_libreoffice_java}
		dev-java/ant-core )
	odbc? ( dev-db/unixODBC )
	odk? ( app-doc/doxygen )
	test? ( java? ( dev-java/junit:4 )
		dev-util/cppunit )
	app-arch/zip
	app-arch/unzip
	dev-lang/perl
	dev-libs/boost[date_time]
	dev-perl/Archive-Zip
	dev-util/gperf
	dev-util/intltool
	dev-util/mdds
	dev-util/pkgconfig
	media-gfx/imagemagick[png]
	media-libs/vigra
	net-misc/npapi-sdk
	sys-apps/coreutils
	sys-apps/grep
	sys-devel/bison
	sys-devel/flex
	sys-devel/gettext
	sys-devel/ucpp
	x11-proto/randrproto
	x11-proto/xextproto
	x11-proto/xineramaproto
	x11-proto/xproto"

#	=app-office/libreoffice-l10n-${LV2}*
PDEPEND="
	fonts? ( media-fonts/liberation-fonts
		media-fonts/libertine-ttf
		media-fonts/urw-fonts )"

_libreoffice_use_gtk="|| ( gtk gtk3 )"
REQUIRED_USE="
	bluetooth? ( dbus )
	eds? ( ${_libreoffice_use_gtk} )
	gnome? ( ${_libreoffice_use_gtk} )
	libreoffice_extension_report-builder? ( java )
	libreoffice_extension_nlpsolver? ( java )
	libreoffice_extension_wiki-publisher? ( java )
	libreoffice_scripting_beanshell? ( java )
	libreoffice_scripting_javascript? ( java )
	nsplugin? ( ${_libreoffice_use_gtk} )
	telepathy? ( ${_libreoffice_use_gtk} )"

libreoffice_pkg_pretend() {
	elog
	eerror "This ${PN} version is geki."
	eerror "Things could just break."

	if ! use java; then
		elog
		ewarn "	You are merging ${PN} without java support!"
		ewarn "	This results in some of its functionality being disabled."
		ewarn "	If something you need does not work, rebuild:"
		ewarn "	# USE=\"java\" emerge ${CATEGORY}/${PN}"
	fi

	# skip build-time info for binary merge
	[[ ${MERGE_TYPE} == binary ]] && return

	_libreoffice_custom-cflags_message

	elog
	einfo "There are various extensions to ${PN}."
	einfo "You may check ./configure for '--enable-ext-*'"
	einfo "and request them here: https://forums.gentoo.org/viewtopic-t-865091.html"

	CHECKREQS_MEMORY="512M"
	use debug && CHECKREQS_DISK_BUILD="16G" \
		|| CHECKREQS_DISK_BUILD="8G"
	use debug && CHECKREQS_DISK_USR="1G" \
		|| CHECKREQS_DISK_USR="512M"
	check-reqs_pkg_pretend

	# ensure pg version
	if use postgres; then
		local pgslot="$(postgresql-config show)"
		if [[ ${pgslot//.} < 90 ]]; then
			eerror "PostgreSQL slot must be set to 9.0 or higher."
			eerror "	postgresql-config set 9.0"
			die "PostgreSQL slot is not set to 9.0 or higher."
		fi
	fi

	# developer flags
	if [ -z ${I_WANT_TO_DEVELOP_LIBREOFFICE} ]; then
		for u in extensions scripting; do
			if use !${u}; then
				eerror "I_WANT_TO_DEVELOP_LIBREOFFICE is not set!"
				eerror "So, you are no developer, do not unset useflag[${u}]!"
				die
			fi
		done
	fi
}

libreoffice_pkg_setup() {
	java-pkg-opt-2_pkg_setup

	use kde && kde4-base_pkg_setup

	python-single-r1_pkg_setup
}

libreoffice_src_unpack() {
	local root="git://anongit.freedesktop.org/${PN}"
	EGIT_BRANCH="${EGIT_BRANCH:-${PN}-${LV2/./-}}"
	EGIT_COMMIT="${EGIT_BRANCH}"

	# clone modules
	for module in ${MODULES}; do
		EGIT_PROJECT="${PN}/${module}"
		EGIT_REPO_URI="${root}/${module}"

		[[ ${module} != core ]] && EGIT_SOURCEDIR="${WORKDIR}/${module}"
		EGIT_NOUNPACK=1
		git-2_src_unpack
	done

	if use branding; then
		cd "${WORKDIR}"
		unpack "${BRAND_SRC}"
	fi
}

libreoffice_src_prepare() {
	# specifics not for upstream
	EPATCH_SUFFIX="diff" base_src_prepare

	# we all love python
	sed -e "s:%eprefix%:${EPREFIX}:g" \
		-e "s:%libdir%:$(get_libdir):g" \
		-i pyuno/source/module/uno.py \
		-i scripting/source/pyprov/officehelper.py \
		|| die "system python adaption failed!"

	# create distro config
	local config="${S}/distro-configs/GentooUnstable.conf"
	sed -e /^#/d \
		< "${FILESDIR}"/conf/GentooUnstable-${LV2} \
		> ${config} \
		|| die "base configuration generation failed"

	# gentoo
	echo "--prefix=${EPREFIX}/usr" >> ${config}
	echo "--sysconfdir=${EPREFIX}/etc" >> ${config}
	echo "--libdir=${EPREFIX}/usr/$(get_libdir)" >> ${config}
	echo "--mandir=${EPREFIX}/usr/share/man" >> ${config}
	echo "--docdir=${EPREFIX}/usr/share/doc/${PF}" >> ${config}
	echo "--with-boost-libdir=$(boost-utils_get_library_path)" >> ${config}
	echo "--with-build-version=geki built ${PV} (unsupported)" >> ${config}
	echo "--with-external-tar=${DISTDIR}" >> ${config}
	echo "--with-parallelism=$(grep -s -c ^processor /proc/cpuinfo)" >> ${config}
	echo "--enable-mergelibs" >> ${config}
	# new feature: --with-branding
	#use branding && echo "--with-branding=${WORKDIR}" >> ${config}
	use branding && echo "--with-intro-bitmap=${WORKDIR}/branding-intro.png" \
		>> ${config}
	echo "$(use_enable !debug release-build)" >> ${config}
	echo "$(use_enable gtk)" >> ${config}
	echo "$(use_enable gtk3)" >> ${config}
	echo "$(use_enable kde kde4)" >> ${config}
	echo "$(use_enable odk)" >> ${config}
	echo "$(use_with java)" >> ${config}
	echo "$(use_with odk doxygen)" >> ${config}

	# extensions
	for extension in ${EXTENSIONS}; do
		echo "$(use_enable libreoffice_extension_${extension} \
			ext-${extension})" >> ${config}
	done

	for scripting in ${SCRIPTINGS}; do
		echo "$(use_enable libreoffice_scripting_${scripting} \
			scripting-${scripting})" >> ${config}
	done

	# internal
	echo "$(use_enable dbus)" >> ${config}
	echo "$(use_enable debug symbols)" >> ${config}
	echo "$(use_enable test linkoo)" >> ${config}

	# system
	echo "$(use_enable eds evolution2)" >> ${config}
	echo "$(use_enable graphite)" >> ${config}
	echo "$(use_with graphite system-graphite)" >> ${config}
	echo "$(use_with odbc system-odbc)" >> ${config}
	echo "$(use_enable opengl)" >> ${config}
	echo "$(use_with opengl system-mesa-headers)" >> ${config}
	echo "$(use_enable python_single_target_python3_3 python system)" >> ${config}
	echo "$(use_enable webdav neon)" >> ${config}
	echo "$(use_with webdav system-neon)" >> ${config}

	# sql
	echo "$(use_with libreoffice_extension_mysql-connector \
		system-mysql)" >> ${config}
	echo "$(use_with libreoffice_extension_mysql-connector \
		system-mysql-cppconn)" >> ${config}
	echo "$(use_enable postgres postgresql-sdbc)" >> ${config}
	echo "$(use_with postgres system-postgresql)" >> ${config}

	# gnome
	echo "$(use_enable gnome lockdown)" >> ${config}
	echo "$(use_enable gnome gconf)" >> ${config}
	echo "$(use_enable gnome systray)" >> ${config}
	echo "$(use_enable gstreamer)" >> ${config}

	# gio
	local gtk="disable"
	use gtk && gtk="enable"
	use gtk3 && gtk="enable"
	echo "--${gtk}-gio" >> ${config}
	echo "--disable-gnome-vfs" >> ${config}

	# java
	if use java; then
		echo "--with-ant-home=${ANT_HOME}" >> ${config}
		echo "--with-jdk-home=$(java-config \
			--jdk-home 2>/dev/null)" >> ${config}
		echo "--with-jvm-path=/usr/$(get_libdir)/" >> ${config}

		# test: java/junit:4
		use test && echo "--with-junit=$(java-pkg_getjar \
			junit-4 junit.jar)" >> ${config}
	fi

	# test: cpp/cppunit java/junit:4
	use test && echo "--with-system-cppunit" >> ${config}
	use !test && echo "--without-junit" >> ${config}

	# extras
	echo "$(use_enable bluetooth sdremote)" >> ${config}
	echo "$(use_enable bluetooth sdremote-bluetooth)" >> ${config}
	echo "$(use_enable telepathy)" >> ${config}

	# extensions
	if use libreoffice_extension_wiki-publisher; then
		echo "--with-system-servlet-api" >> ${config}
		echo "--with-commons-codec-jar=$(java-pkg_getjar \
			commons-codec commons-codec.jar)" >> ${config}
		echo "--with-commons-httpclient-jar=$(java-pkg_getjar \
			commons-httpclient-3 commons-httpclient.jar)" >> ${config}
		echo "--with-commons-lang-jar=$(java-pkg_getjar \
			commons-lang-2.1 commons-lang.jar)" >> ${config}
		echo "--with-servlet-api-jar=$(java-pkg_getjar \
			tomcat-servlet-api-3.0 servlet-api.jar)" >> ${config}
	fi

	if use libreoffice_extension_report-builder \
	|| use libreoffice_extension_wiki-publisher; then
		echo "--with-commons-logging-jar=$(java-pkg_getjar \
			commons-logging commons-logging.jar)" >> ${config}
		echo "--with-system-apache-commons" >> ${config}
	fi

	# scripting
	if use libreoffice_scripting_beanshell; then
		echo "--with-system-beanshell" >> ${config}
		echo "--with-beanshell-jar=$(java-pkg_getjar bsh bsh.jar)" >> ${config}
	fi

	# developer
	echo "$(use_enable extensions)" >> ${config}
	echo "$(use_enable scripting)" >> ${config}

	AT_M4DIR="m4" eautoreconf
}

libreoffice_src_configure() {
	# bug 345799: set allowed flags for libreoffice
	# by default '-g' and the like are allowed which blow up the code

	# compiler flags
	use custom-cflags || strip-flags
	use debug || filter-flags "-g*"
	append-flags "-w"

	# silent miscompiles; LO adds -O2/1/0 where appropriate
	filter-flags "-O*"

	# optimize
	export ARCH_FLAGS="${CXXFLAGS}"
	export GMAKE_OPTIONS="${MAKEOPTS}"

	# linker flags
	use debug || export LINKFLAGSOPTIMIZE="${LDFLAGS}"

	# qt/kde --- yay --- still necessary?!
	#use kde && export KDE4DIR="${KDEDIR}"
	#use kde && export QT4LIB="/usr/$(get_libdir)/qt4"

	# pdfimport fubar'ed configure flag
	local want_pdfimport="FALSE"
	use pdfimport && want_pdfimport="TRUE"

	ENABLE_PDFIMPORT="${want_pdfimport}" \
	./autogen.sh --with-distro="GentooUnstable" \
		|| die "configure failed"
}

libreoffice_src_compile() {
	# hack for offlinehelp, this needs fixing upstream at some point
	# it is broken because we send --without-help
	# https://bugs.freedesktop.org/show_bug.cgi?id=46506
	(
		grep ^export "${S}/config_host.mk" | grep -v WORKDIR > "${S}/my_host.mk"
		sed -r \
			-e "s:\$(gb_SPACE): :g" \
			-e "s:\$(gb_Space): :g" \
			-e "s:(export [A-Z0-9_]+)=(.*)$:\1=\"\2\":" \
			-i my_host.mk || die
		source "${S}/my_host.mk"

		local path="${SOLARVER}/${INPATH}/res/img"
		mkdir -p "${path}" || die

		perl "${WORKDIR}/help/helpers/create_ilst.pl" \
			-dir=icon-themes/galaxy/res/helpimg \
			> "${path}/helpimg.ilst"

		[[ -s "${path}/helpimg.ilst" ]] \
			|| ewarn "The help images list is empty, something is fishy, report a bug."
	)

	make build || die "make failed"
}

libreoffice_src_test() {
	use test && make check
}

libreoffice_src_install() {
	# install
	make DESTDIR="${ED}" distro-pack-install \
		-o build -o check || die "install failed"

	# access
	use prefix || chown -RP root:0 "${ED}"

	# bash completion
	newbashcomp "${ED}"/etc/bash_completion.d/libreoffice.sh ${PN}
	rm -rf "${ED}"/etc/

	if use branding; then
		insinto /usr/$(get_libdir)/${PN}/program
		newins "${WORKDIR}/branding-sofficerc" sofficerc \
			|| ewarn "branding config failed"
	fi

	# proper location for nsplugin
	use nsplugin && inst_plugin /usr/$(get_libdir)/${PN}/program/libnpsoplugin.so

	# hack for offlinehelp, this needs fixing upstream at some point
	# it is broken because we send --without-help
	# https://bugs.freedesktop.org/show_bug.cgi?id=46506
	insinto /usr/$(get_libdir)/libreoffice/help
	doins xmlhelp/util/*.xsl

	# remove old cruft
	rm -rf "${ED}"/usr/share/mimelnk/
}

libreoffice_pkg_preinst() {
	# icon savelist
	kde4-base_pkg_preinst
}

libreoffice_pkg_postinst() {
	# mime data and kde4
	kde4-base_pkg_postinst

	# hardened
	_libreoffice_pax_fix

	elog
	elog " To start LibreOffice, run:"
	elog
	elog " $ libreoffice"
	elog
	elog "__________________________________________________________________"
	elog " Also, for individual components, you can use any of:"
	elog
	elog " lobase, localc, lodraw, lofromtemplate, loimpress,"
	elog " lomath, loweb or lowriter"
	elog
	elog "__________________________________________________________________"
	elog " Some parts have to be installed via Extension Manager now"
	elog
	elog " Extensions:"
	for extension in ${EXTENSIONS}; do
		use libreoffice_extension_${extension} && elog " - ${extension}"
	done
	elog
	elog " Scripting:"
	for scripting in ${SCRIPTINGS}; do
		use libreoffice_scripting_${scripting} && elog " - ${scripting}"
	done
	elog " ... more may come"
	elog
	elog " from /usr/$(get_libdir)/${PN}/share/extension/install/"
	elog
	elog " Either with the GUI ..."
	elog " or with the 'unopkg' commandline-tool."
	elog
	elog " ex.:	# unopkg add /usr/$(get_libdir)/${PN}/share/extension/install/<extension>.oxt"
	elog "		# unopkg remove <Identifier>"
	elog
	elog " To get the Identifier check the list of installed extensions."
	elog
	elog "		# unopkg list"
}

libreoffice_pkg_postrm() {
	# mime data
	kde4-base_pkg_postrm
}

_libreoffice_pax_fix() {
	local path="${EPREFIX}/usr/$(get_libdir)/${PN}/program"

	pax-mark -m "${path}/soffice.bin"
	pax-mark -m "${path}/unopkg.bin"
}

_libreoffice_custom-cflags_message() {
	if use custom-cflags; then
		eerror
		eerror "You enabled useflag[custom-cflags]."
		eerror
		eerror "Custom C[XX]FLAGS cause various random errors for ${PN}!"
		eerror "Not only at compile-time but also at runtime!"
		eerror
		eerror "So, you are on your own. Blame yourself if it fails. ;)"
		eerror "Only reports with a fix, not a workaround, are accepted!"
	fi
}

if ! has _libreoffice_die ${EBUILD_DEATH_HOOKS}; then
	EBUILD_DEATH_HOOKS+=" _libreoffice_die"
fi

_libreoffice_die() {
	_libreoffice_custom-cflags_message
}
