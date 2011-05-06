# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: unified build of libreoffice
#

#
# TODO: waiting for eclass/python EAPI=4 :D
#

EAPI="4"

WANT_AUTOCONF="2.5"
WANT_AUTOMAKE="1.9"

#WANT_AUTOMAKE="1.11"
#PYTHON_DEPEND="python? 2:2.6"
#PYTHON_USE_WITH="threads,xml"

KDE_REQUIRED="never"
CMAKE_REQUIRED="never"

inherit autotools bash-completion boost-utils check-reqs db-use eutils fdo-mime \
	flag-o-matic gnome2-utils java-pkg-opt-2 kde4-base mono multilib pax-utils \
	versionator
# inherit python

if [[ ${PV} == *_pre ]]; then
	# git-2 just hangs after first unpack?!
	inherit git
fi

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm

IUSE="cups custom-cflags dbus debug eds gnome graphite gstreamer gtk jemalloc
junit kde languagetool ldap mono mysql nsplugin odbc odk opengl python
reportbuilder templates webdav wiki"
# postgres - system only diff available - no chance to choose! :(

# available languages
LANGUAGES="af ar as ast be_BY bg bn bo br brx bs ca ca_XV cs cy da de dgo dz el
en en_GB en_ZA eo es et eu fa fi fr ga gd gl gu he hi hr hu id is it ja ka kk km
kn kok ko ks ku ky lo lt lv mai mk ml mn mni mr ms my nb ne nl nn nr ns oc om or
pa pap pl ps pt pt_BR ro ru rw sa sat sd sh si sk sl sq sr ss st sv sw_TZ ta te
tg th ti tn tr ts ug uk ur uz ve vi xh zh_CN zh_TW zu"

for language in ${LANGUAGES}; do
	IUSE+=" linguas_${language}"
done

# available app-dicts/myspell dictionaries
MYSPELLS="af bg ca cs cy da de el en eo es et fr ga gl he hr hu it ku lt mk nb
nl nn pl pt ru sk sl sv tn zu"

SDEPEND=""
for language in ${MYSPELLS}; do
	SDEPEND+=" linguas_${language}? ( app-dicts/myspell-${language} )"
done

# available templates
# - en_* => en_US templates for simplicity; fix:
# https://forums.gentoo.org/viewtopic-p-6449940.html#6449940
TEMPLATES="de en en_GB en_ZA es fr hu it"
EXT_SRC="ftp://ftp.devall.hu/kami/go-oo"

TDEPEND=""
for template in ${TEMPLATES}; do
	TDEPEND+=" linguas_${template}? ( \
		${EXT_SRC}/Sun_ODF_Template_Pack_${template/en*/en-US}.oxt )"
done

DESCRIPTION="LibreOffice - a productivity suite (experimental version)"
HOMEPAGE="http://www.libreoffice.org/"

SLOT="0"

LICENSE="LGPL-3"
RESTRICT="binchecks mirror"

# config
MY_PV="$(get_version_component_range 1-2)"

# paths
GO_SRC="http://download.go-oo.org"
LIBRE_SRC="http://download.documentfoundation.org/libreoffice/src"

SRC_URI="${GO_SRC}/SRC680/biblio.tar.bz2
	${GO_SRC}/SRC680/extras-3.1.tar.bz2
	mono? ( ${GO_SRC}/DEV300/ooo-cli-prebuilt-${MY_PV}.tar.bz2 )
	templates? ( ${TDEPEND} )"

# libreoffice modules
MODULES="artwork base calc components extensions extras filters help impress
libs-core libs-extern libs-extern-sys libs-gui postprocess sdk testing ure
writer translations"

if [[ ${PV} != *_pre ]]; then
	SRC_URI+=" ${LIBRE_SRC}/${PN}-bootstrap-${PV}.tar.bz2"

	for module in ${MODULES}; do
		SRC_URI+=" ${LIBRE_SRC}/${PN}-${module}-${PV}.tar.bz2"
	done
fi

#	>=dev-libs/xmlsec-1.2.14
#	reportbuilder? ( dev-java/sac
#		dev-java/flute-jfree
#		dev-java/jcommon
#		dev-java/jcommon-serializer
#		dev-java/libfonts
#		dev-java/libformula
#		dev-java/liblayout
#		dev-java/libloader
#		dev-java/librepository
#		dev-java/libxml
#		dev-java/jfreereport
#		dev-java/commons-logging:0 )
#	postgres? ( dev-db/postgresql )
#		dev-java/saxon:9
#		dev-db/hsqldb
CDEPEND="${SDEPEND}
	cups? ( net-print/cups )
	dbus? ( dev-libs/dbus-glib )
	eds? ( gnome-extra/evolution-data-server )
	gnome? ( gnome-base/gconf:2 )
	graphite? ( media-libs/silgraphite )
	gstreamer? ( media-libs/gstreamer
		media-libs/gst-plugins-base )
	gtk? ( x11-libs/gtk+:2 )
	java? ( dev-java/bsh
		dev-java/lucene:2.9[analyzers] )
	jemalloc? ( dev-libs/jemalloc )
	kde? ( x11-libs/qt-core
		x11-libs/qt-gui
		kde-base/kdelibs
		kde-base/kstyles )
	ldap? ( net-nds/openldap )
	nsplugin? ( net-libs/xulrunner:1.9 )
	mono? ( dev-lang/mono )
	mysql? ( dev-db/mysql-connector-c++:1.1.0 )
	opengl? ( virtual/opengl virtual/glu )
	reportbuilder? ( dev-java/commons-logging:0 )
	webdav? ( net-libs/neon )
	wiki? ( dev-java/commons-codec:0
		dev-java/commons-httpclient:3
		dev-java/commons-lang:2.1
		dev-java/commons-logging:0
		dev-java/tomcat-servlet-api:2.4 )
	  app-text/hunspell
	  app-text/libwpd:0.9[tools]
	  app-text/libwps:0.2
	  app-text/poppler[xpdf-headers]
	  dev-libs/boost[program_options,thread]
	  dev-libs/expat
	  dev-libs/icu
	  dev-libs/libxml2
	  dev-libs/libxslt
	  dev-libs/openssl
	  dev-libs/redland[ssl]
	  dev-util/gperf
	  media-libs/fontconfig
	  media-libs/freetype:2
	  media-libs/libpng
	  media-libs/libwpg:0.2
	  media-libs/vigra
	  net-misc/curl
	>=sys-libs/db-4.7
	  sys-libs/zlib
	  x11-libs/cairo[svg]
	  x11-libs/libXaw
	  x11-libs/libXinerama
	  x11-libs/libXrandr
	  x11-libs/libXtst
	  x11-libs/startup-notification
	  virtual/jpeg"

RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-1.5 )
	python? ( dev-lang/python:2.7[threads,xml] )"

DEPEND="${CDEPEND}
	!dev-util/dmake
	java? ( >=virtual/jdk-1.5
		dev-java/ant-core )
	junit? ( dev-java/junit:4 )
	odbc? ( dev-db/unixODBC )
	app-arch/unzip
	app-arch/zip
	dev-lang/perl
	dev-lang/python:2.7[threads,xml]
	dev-libs/boost-headers
	dev-perl/Archive-Zip
	dev-util/cppunit
	dev-util/intltool
	dev-util/pkgconfig
	dev-vcs/git
	media-gfx/imagemagick[png]
	sys-apps/coreutils
	sys-apps/grep
	sys-devel/bison
	sys-devel/flex
	x11-libs/libXrender
	x11-proto/xextproto
	x11-proto/xineramaproto
	x11-proto/xproto"

REQUIRED_USE="junit? ( java ) languagetool? ( java ) reportbuilder? ( java ) wiki? ( java ) gnome? ( gtk ) nsplugin? ( gtk )"

libreoffice_pkg_pretend() {
	# welcome
	elog
	eerror "This ${PN} version is experimental."
	eerror "Things could just break."

	elog
	einfo "There are various extensions to ${PN}."
	einfo "You may check ./configure for '--enable-ext-*'"
	einfo "and request them here: https://forums.gentoo.org/viewtopic-t-865091.html"

	# custom-cflags
	_libreoffice_custom-cflags_message

	# space
	CHECKREQS_MEMORY="512"
	use debug && CHECKREQS_DISK_BUILD="16000" \
		|| CHECKREQS_DISK_BUILD="8000"
	use debug && CHECKREQS_DISK_USR="1024" \
		|| CHECKREQS_DISK_USR="512"
	check_reqs

	if ! use java; then
		elog
		ewarn "You are building with java-support disabled, this results in some"
		ewarn "of the LibreOffice functionality being disabled."
		ewarn "If something you need does not work for you, rebuild with"
		ewarn "java in your USE-flags."
	fi
}

libreoffice_pkg_setup() {
	# java
	java-pkg-opt-2_pkg_setup

	# lang setup
	strip-linguas ${LANGUAGES}

	# lang conf (i103809)
	if [ -z "${LINGUAS}" ] || [[ ${LINGUAS} == en ]]; then
		LINGUAS_OOO=
	# but if localized we want en-US for broken code and sdk
	# case: en lingua already set
	elif [[ ${LINGUAS} =~ en( |$) ]]; then
		LINGUAS_OOO="$(echo ${LINGUAS} | sed -e 's/\ben\b/en_US/;s/_/-/g')"
	# case: en_US lingua not set, add
	else
		LINGUAS_OOO="en-US ${LINGUAS//_/-}"
	fi

	# kde
	use kde && kde4-base_pkg_setup

	# python
#	if use python; then
#		python_set_active_version 2
#		python_pkg_setup
#	fi
}

libreoffice_src_unpack() {
	# layered clone/build process - fun! :)
	if [[ ${PV} == *_pre ]]; then
		local root="git://anongit.freedesktop.org/${PN}"
		EGIT_BRANCH="${EGIT_BRANCH:-${PN}-$(replace_all_version_separators - ${MY_PV})}"
		# eclass/git feature: if not equal use EGIT_COMMIT, which defaults to master
		EGIT_COMMIT="${EGIT_BRANCH}"

		# unpack build tools
		EGIT_PROJECT="${PN}/bootstrap"
		EGIT_REPO_URI="${root}/bootstrap"
		git_src_unpack

		# clone modules
		for module in ${MODULES}; do
			EGIT_PROJECT="${PN}/${module}"
			EGIT_UNPACK_DIR="${CLONE_DIR}/${module}"
			EGIT_REPO_URI="${root}/${module}"
			git_src_unpack
		done
	else
		unpack "${PN}-bootstrap-${PV}.tar.bz2"

		cd "${CLONE_DIR}"

		# unpack modules
		for module in ${MODULES}; do
			unpack "${PN}-${module}-${PV}.tar.bz2"
		done
	fi

	# move source into tree
	# FIXME: symlink; possible to use ./g pull?
	mv -n "${CLONE_DIR}"/*/* "${S}"

	# no need to download external sources
	# although we set two configure flags already for this ...
	touch "${S}"/src.downloaded
}

libreoffice_src_prepare() {
	# gentoo
	local CONFFILE="${S}/distro-configs/GentooUnstable.conf"

	# specifics not for upstream
	EPATCH_SUFFIX="diff"
	EPATCH_FORCE="yes"
	epatch "${FILESDIR}"

	# allow user to apply any additional patches without modifying ebuild
	epatch_user

	# create distro config
	# FIXME: add GentooUnstable-VERSION.conf to ${FILESDIR} for defaults
	echo "--prefix="${EPREFIX}"/usr" >> ${CONFFILE}
	echo "--sysconfdir="${EPREFIX}"/etc" >> ${CONFFILE}
	echo "--libdir="${EPREFIX}"/usr/$(get_libdir)" >> ${CONFFILE}
	echo "--mandir="${EPREFIX}"/usr/share/man" >> ${CONFFILE}
	echo "--docdir=${EPREFIX}/usr/share/doc/${PF}" >> ${CONFFILE}
	echo "--with-external-dict-dir=/usr/share/myspell" >> ${CONFFILE}
	echo "--with-external-hyph-dir=/usr/share/myspell" >> ${CONFFILE}
	echo "--with-external-thes-dir=/usr/share/myspell" >> ${CONFFILE}
	echo "--with-system-boost" >> ${CONFFILE}
	echo "--with-system-curl" >> ${CONFFILE}
	echo "--with-system-db" >> ${CONFFILE}
	echo "--with-system-dicts" >> ${CONFFILE}
	echo "--with-system-expat" >> ${CONFFILE}
	echo "--with-system-hunspell" >> ${CONFFILE}
	echo "--with-system-icu" >> ${CONFFILE}
	echo "--with-system-libxslt" >> ${CONFFILE}
	echo "--with-system-openssl" >> ${CONFFILE}
	echo "--with-system-vigra" >> ${CONFFILE}
	echo "--without-myspell-dicts" >> ${CONFFILE}
	echo "--without-stlport" >> ${CONFFILE}
	echo "--with-system-zlib" >> ${CONFFILE}
	echo "--with-vendor=Gentoo Foundation" >> ${CONFFILE}
	echo "--with-build-version=geki built ${PV} (unsupported)" >> ${CONFFILE}
	echo "--with-lang=${LINGUAS_OOO}" >> ${CONFFILE}
	echo "--with-num-cpus=$(grep -s -c ^processor /proc/cpuinfo)" >> ${CONFFILE}
	echo "--with-system-hunspell" >> ${CONFFILE}
	echo "--with-system-libwpd" >> ${CONFFILE}
	echo "--with-system-libwpg" >> ${CONFFILE}
	echo "--with-system-libwps" >> ${CONFFILE}
	echo "--enable-cairo" >> ${CONFFILE}
	echo "--with-system-cairo" >> ${CONFFILE}
	echo "--disable-kde" >> ${CONFFILE}
	echo "--disable-layout" >> ${CONFFILE}
	echo "$(use_enable gtk)" >> ${CONFFILE}
	echo "$(use_enable kde kde4)" >> ${CONFFILE}
	echo "$(use_enable !debug strip-solver)" >> ${CONFFILE}
	echo "$(use_with java)" >> ${CONFFILE}
#	echo "$(use_enable mono)" >> ${CONFFILE}
	echo "$(use_enable odk)" >> ${CONFFILE}
	echo "$(use_with templates sun-templates)" >> ${CONFFILE}
	echo "--disable-crashdump" >> ${CONFFILE}
	echo "--disable-epm" >> ${CONFFILE}
	echo "--disable-unix-qstart" >> ${CONFFILE}
	echo "--disable-dependency-tracking" >> ${CONFFILE}
	echo "--disable-zenity" >> ${CONFFILE}
	echo "--disable-fetch-external" >> ${CONFFILE}
	echo "--with-external-tar=${DISTDIR}" >> ${CONFFILE}

	# gentooexperimental defaults
	echo "--without-afms" >> ${CONFFILE}
	echo "--without-fonts" >> ${CONFFILE}
	echo "--without-ppds" >> ${CONFFILE}
	echo "--with-system-cppunit" >> ${CONFFILE}
	echo "--with-system-openssl" >> ${CONFFILE}
	echo "--with-system-redland" >> ${CONFFILE}
#	echo "--with-system-xmlsec" >> ${CONFFILE}
	echo "--enable-xrender-link" >> ${CONFFILE}
	echo "--disable-systray" >> ${CONFFILE}

	# extensions
	echo "--with-extension-integration" >> ${CONFFILE}
	echo "--enable-ext-pdfimport" >> ${CONFFILE}
	echo "--enable-ext-presenter-console" >> ${CONFFILE}
	echo "--enable-ext-presenter-minimizer" >> ${CONFFILE}
	echo "$(use_enable reportbuilder ext-report-builder)" >> ${CONFFILE}
	echo "$(use_enable wiki ext-wiki-publisher)" >> ${CONFFILE}
	echo "$(use_enable mysql ext-mysql-connector)" >> ${CONFFILE}
	# FIXME: enable-ext
	echo "$(use_with languagetool)" >> ${CONFFILE}

	# internal
	echo "--disable-binfilter" >> ${CONFFILE}
	echo "$(use_enable dbus)" >> ${CONFFILE}
	echo "$(use_enable debug symbols)" >> ${CONFFILE}
	use jemalloc && echo "--with-alloc=jemalloc" >> ${CONFFILE}

	# system
	echo "$(use_enable cups)" >> ${CONFFILE}
	echo "$(use_enable eds evolution2)" >> ${CONFFILE}
	echo "$(use_enable graphite)" >> ${CONFFILE}
	echo "$(use_with graphite system-graphite)" >> ${CONFFILE}
	echo "$(use_enable ldap)" >> ${CONFFILE}
	echo "$(use_with ldap openldap)" >> ${CONFFILE}
	echo "$(use_with odbc system-odbc)" >> ${CONFFILE}
	echo "$(use_enable opengl)" >> ${CONFFILE}
	echo "$(use_with opengl system-mesa-headers)" >> ${CONFFILE}
	echo "$(use_enable python)" >> ${CONFFILE}
	echo "$(use_enable webdav neon)" >> ${CONFFILE}
	echo "$(use_with webdav system-neon)" >> ${CONFFILE}

	# mysql
	echo "$(use_with mysql system-mysql)" >> ${CONFFILE}
	echo "$(use_with mysql system-mysql-cppconn)" >> ${CONFFILE}

	# browser
	echo "$(use_enable nsplugin mozilla)" >> ${CONFFILE}
	echo "$(use_with nsplugin system-mozilla libxul)" >> ${CONFFILE}

	# gnome
	echo "--disable-gnome-vfs" >> ${CONFFILE}
	echo "$(use_enable gtk gio)" >> ${CONFFILE}
	echo "$(use_enable gnome lockdown)" >> ${CONFFILE}
	echo "$(use_enable gnome gconf)" >> ${CONFFILE}
	echo "$(use_enable gstreamer)" >> ${CONFFILE}

	# java
	if use java; then
		echo "--with-ant-home=${ANT_HOME}" >> ${CONFFILE}
		echo "--with-jdk-home=$(java-config --jdk-home 2>/dev/null)" >> ${CONFFILE}
		echo "--with-java-target-version=1.5" >> ${CONFFILE}
		echo "--with-jvm-path=/usr/$(get_libdir)/" >> ${CONFFILE}
		echo "--with-system-beanshell" >> ${CONFFILE}
#		echo "--with-system-hsqldb" >> ${CONFFILE}
		echo "--with-system-lucene" >> ${CONFFILE}
#		echo "--with-system-saxon" >> ${CONFFILE}
		echo "--with-beanshell-jar=$(java-pkg_getjar bsh bsh.jar)" >> ${CONFFILE}
#		echo "--with-hsqldb-jar=$(java-pkg_getjar hsqldb hsqldb.jar)" >> ${CONFFILE}
		echo "--with-lucene-core-jar=$(java-pkg_getjar \
			lucene-2.9 lucene-core.jar)" >> ${CONFFILE}
		echo "--with-lucene-analyzers-jar=$(java-pkg_getjar \
			lucene-2.9 lucene-analyzers.jar)" >> ${CONFFILE}
#		echo "--with-saxon-jar=$(java-pkg_getjar saxon-9 saxon.jar)" >> ${CONFFILE}

		# junit:4
		use junit && echo "--with-junit=$(java-pkg_getjar \
			junit-4 junit.jar)" >> ${CONFFILE}
	fi

	# junit:4
	use !junit && echo "--without-junit" >> ${CONFFILE}

	# reportbuilder extension
#	if use reportbuilder; then
#		echo "--with-system-jfreereport" >> ${CONFFILE}
#		echo "--with-sac-jar=$(java-pkg_getjar \
#			sac sac.jar)" >> ${CONFFILE}
#		echo "--with-flute-jar=$(java-pkg_getjar \
#			flute-jfree flute-jfree.jar)" >> ${CONFFILE}
#		echo "--with-jcommon-jar=$(java-pkg_getjar \
#			jcommon-1.0 jcommon.jar)" >> ${CONFFILE}
#		echo "--with-jcommon-serializer-jar=$(java-pkg_getjar \
#			jcommon-serializer jcommon-serializer.jar)" >> ${CONFFILE}
#		echo "--with-libfonts-jar=$(java-pkg_getjar \
#			libfonts libfonts.jar)" >> ${CONFFILE}
#		echo "--with-libformula-jar=$(java-pkg_getjar \
#			libformula libformula.jar)" >> ${CONFFILE}
#		echo "--with-liblayout-jar=$(java-pkg_getjar \
#			liblayout liblayout.jar)" >> ${CONFFILE}
#		echo "--with-libloader-jar=$(java-pkg_getjar \
#			libloader libloader.jar)" >> ${CONFFILE}
#		echo "--with-librepository-jar=$(java-pkg_getjar \
#			librepository librepository.jar)" >> ${CONFFILE}
#		echo "--with-libxml-jar=$(java-pkg_getjar \
#			libxml libxml.jar)" >> ${CONFFILE}
#		echo "--with-jfreereport-jar=$(java-pkg_getjar \
#			jfreereport jfreereport.jar)" >> ${CONFFILE}
#	fi

	# wiki extension
	if use wiki; then
		echo "--with-system-servlet-api" >> ${CONFFILE}
		echo "--with-commons-codec-jar=$(java-pkg_getjar \
			commons-codec commons-codec.jar)" >> ${CONFFILE}
		echo "--with-commons-httpclient-jar=$(java-pkg_getjar \
			commons-httpclient-3 commons-httpclient.jar)" >> ${CONFFILE}
		echo "--with-commons-lang-jar=$(java-pkg_getjar \
			commons-lang-2.1 commons-lang.jar)" >> ${CONFFILE}
		echo "--with-servlet-api-jar=$(java-pkg_getjar \
			tomcat-servlet-api-2.4 servlet-api.jar)" >> ${CONFFILE}
	fi

	# reportbuilder & wiki extension
	if use reportbuilder || use wiki; then
		echo "--with-commons-logging-jar=$(java-pkg_getjar \
			commons-logging commons-logging.jar)" >> ${CONFFILE}
		echo "--with-system-apache-commons" >> ${CONFFILE}
	fi

	eautoreconf
}

libreoffice_src_configure() {
	# set allowed flags for libreoffice
	# by default '-g' and the like are allowed which blow up the code: bug 345799

	# compiler flags
	use custom-cflags || strip-flags
	use debug || filter-flags "-g*"
	append-flags "-w"

	# silent miscompiles; LO/OOo adds -O2/1/0 where appropriate
	filter-flags "-O*"

	# optimize
	export ARCH_FLAGS="${CXXFLAGS}"

	# linker flags
	use debug || export LINKFLAGSOPTIMIZE="${LDFLAGS}"
	export LINKFLAGSDEFS="-Wl,-z,defs -L$(get_boost_library_path)"

	# qt/kde --- yay
	use kde && export KDE4DIR="${KDEDIR}"
	use kde && export QT4LIB="/usr/$(get_libdir)/qt4"

	./autogen.sh --with-distro="GentooUnstable"

	# no need to download external sources
	# although we set two configure flags already for this ...
	sed /DO_FETCH_TARBALLS=/d -i *Env.Set*
}

libreoffice_src_compile() {
	# build
	make || _libreoffice_die "make failed"
}

libreoffice_src_install() {
	# install
	make DESTDIR="${ED}" install || _libreoffice_die "install failed"

	# access
	use prefix || chown -RP root:0 "${ED}"

	# install desktop files
	domenu "${ED}"/usr/$(get_libdir)/${PN}/share/xdg/*.desktop

	cd "${S}"

	# install mime package
	dodir /usr/share/mime/packages
	cp sysui/*.pro/misc/${PN}/openoffice.org.xml \
		"${ED}"/usr/share/mime/packages/${PN}.xml

	# install icons
	local path="${ED}/usr/share"
	for icon in sysui/desktop/icons/hicolor/*/apps/*.png; do
		mkdir -p "${path}$(dirname ${icon##sysui\/desktop})"
		cp "${icon}" "${path}$(dirname ${icon##sysui\/desktop})"
	done

	# install wrapper
	# FIXME: exeinto should not be necessary! :D
	exeinto /usr/bin
	newexe sysui/*.pro/misc/${PN}/openoffice.sh ${PN}

	sed -e "s:/opt:/usr/$(get_libdir):" \
		-i "${ED}"/usr/bin/${PN} \
		|| _libreoffice_die "wrapper failed"

	# remove fuzz
	rm "${ED}"/gid_Module_*
}

libreoffice_pkg_preinst() {
	use gnome && gnome2_icon_savelist
}

libreoffice_pkg_postinst() {
	# mime data
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	use gnome && gnome2_icon_cache_update

	# hardened
	_libreoffice_pax_fix

	# kde4
	use kde && kde4-base_pkg_postinst

	# bash-completion postinst
#	BASHCOMPLETION_NAME="libreoffice-libre" \
#	bash-completion_pkg_postinst

	# info
	elog " To start LibreOffice, run:"
	elog
	elog " $ libreoffice"
	elog
#	elog "__________________________________________________________________"
#	elog " Also, for individual components, you can use any of:"
#	elog
#	elog " lobase-libre, localc-libre, lodraw-libre, lofromtemplate-libre,"
#	elog " loimpress-libre, lomath-libre, loweb-libre or lowriter-libre"
#	elog
	elog "__________________________________________________________________"
	elog " Some parts have to be installed via Extension Manager now"
	ewarn " - VBA (VisualBasic-Assistant) support is no longer an extension"
	elog " - pdfimport"
	elog " - presentation console"
	elog " - presentation minimizer"
	elog " - presentation ui"
	use languagetool && elog " - JLanguageTool"
	use reportbuilder && elog " - report builder"
	use wiki && elog " - wiki publisher"
	use mysql && elog " - MySQL (native) database connector"
	elog " ... more may come"
	elog
	elog " from /usr/$(get_libdir)/${PN}/share/extension/install/"
	elog
	elog " Either with the GUI ..."
	elog " or with the 'unopkg' commandline-tool."
	elog
	elog " ex.:	# unopkg-libre add /usr/$(get_libdir)/${PN}/share/extension/install/<extension>.oxt"
	elog "		# unopkg-libre remove <Identifier>"
	elog
	elog " To get the Identifier check the list of installed extensions."
	elog
	elog "		# unopkg-libre list"
}

libreoffice_pkg_postrm() {
	# mime data
	fdo-mime_desktop_database_update
	use gnome && gnome2_icon_cache_update
}

_libreoffice_pax_fix() {
	local bin="${EPREFIX}/usr/$(get_libdir)/${PN}/program/soffice.bin"
	pax-mark -m "${bin}"
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

_libreoffice_die() {
	# custom-cflags
	_libreoffice_custom-cflags_message

	die "${@}"
}
