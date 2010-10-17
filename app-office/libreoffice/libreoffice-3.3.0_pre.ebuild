# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="3"

WANT_AUTOCONF="2.5"
WANT_AUTOMAKE="1.9"

KDE_REQUIRED="never"
CMAKE_REQUIRED="never"

inherit autotools bash-completion boost-utils check-reqs confutils db-use \
	eutils fdo-mime flag-o-matic java-pkg-opt-2 kde4-base mono multilib \
	versionator

IUSE="blog cups dbus debug eds gnome graphite gstreamer gtk jemalloc junit kde
languagetool ldap mono mysql nsplugin odbc odk opengl pam python reportbuilder
templates webdav wiki"
# postgres - system only diff available - no chance to choose! :(

# available languages
LANGUAGES="af ar as be_BY bg bn br bs ca cs cy da de dz el en en_GB en_ZA eo es
et fa fi fr ga gl gu he hi hr hu it ja km ko ku lt lv mk ml mr nb ne nl nn nr ns
or pa pl pt pt_BR ru rw sh sk sl sr ss st sv ta te tg th ti tn tr ts uk ur ve vi
xh zh_CN zh_TW zu"

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
# - en_* => en_US templates for simplicity; fix
# https://forums.gentoo.org/viewtopic-p-6449940.html#6449940
TEMPLATES="de en en_GB en_ZA es fr hu it"
EXT_SRC="ftp://ftp.devall.hu/kami/go-oo"

TDEPEND=""
for template in ${TEMPLATES}; do
	TDEPEND+=" linguas_${template}? ( \
		${EXT_SRC}/Sun_ODF_Template_Pack_${template/en*/en-US}.oxt )"
done

DESCRIPTION="OpenOffice.org, unstable 3.x development sources."
HOMEPAGE="http://www.documentfoundation.org/"

SLOT="0"

LICENSE="LGPL-3"
KEYWORDS=""
RESTRICT="binchecks mirror"

# configs
GIT_BUILD="3a7a43cebb335ee3164be58cc379a35747a65ccd"
MY_P="build-${GIT_BUILD}"
MY_PV="$(get_version_component_range 1-3)"

S="${WORKDIR}/${MY_P}"

# paths
CLONE_DIR="${S}/clone"
GIT_DIR="git://anongit.freedesktop.org/git/libreoffice"
GO_SRC="http://download.go-oo.org"

SRC_URI="http://cgit.freedesktop.org/libreoffice/build/snapshot/${MY_P}.tar.gz
	mono? ( ${GO_SRC}/DEV300/ooo-cli-prebuilt-$(get_version_component_range 1-2).tar.bz2 )
	templates? ( ${TDEPEND} )
	${GO_SRC}/SRC680/biblio.tar.bz2
	${GO_SRC}/SRC680/extras-3.tar.bz2
	blog? ( ${GO_SRC}/src/oooblogger-0.1.oxt )
	languagetool? ( ${GO_SRC}/src/JLanguageTool-1.0.0.tar.bz2 )"

# libreoffice modules
MODULES="artwork base bootstrap calc components extensions extras filters help
impress libs-core libs-extern libs-extern-sys libs-gui postprocess sdk testing
ure writer l10n"

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
	!app-office/openoffice-bin
	!app-office/openoffice
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
	kde? ( >=x11-libs/qt-core-4.6
		>=x11-libs/qt-gui-4.6
		>=kde-base/kdelibs-4.4
		>=kde-base/kstyles-4.4 )
	ldap? ( net-nds/openldap )
	nsplugin? ( net-libs/xulrunner:1.9 )
	mono? ( >=dev-lang/mono-2.4 )
	mysql? ( >=dev-db/mysql-connector-c++-1.1.0_pre814 )
	opengl? ( virtual/opengl virtual/glu )
	python? ( dev-lang/python:2.6[threads,xml] )
	webdav? ( net-libs/neon )
	wiki? ( dev-java/commons-codec:0
		dev-java/commons-httpclient:3
		dev-java/commons-lang:2.1
		dev-java/commons-logging:0
		dev-java/tomcat-servlet-api:2.4 )
	  app-text/hunspell
	  app-text/libwpd
	  app-text/libwps
	  app-text/poppler[xpdf-headers]
	  dev-libs/boost-program_options
	  dev-libs/boost-thread
	  dev-libs/expat
	>=dev-libs/icu-4.2.1
	  dev-libs/libxml2
	  dev-libs/libxslt
	  dev-libs/openssl
	  dev-libs/redland[ssl]
	  dev-util/gperf
	  media-libs/fontconfig
	  media-libs/freetype:2
	  media-libs/jpeg
	  media-libs/libpng
	  media-libs/libwpg
	  media-libs/vigra
	  net-misc/curl
	>=sys-libs/db-4.7
	  sys-libs/zlib
	  x11-libs/cairo[svg]
	  x11-libs/libXaw
	  x11-libs/libXinerama
	  x11-libs/libXtst
	  x11-libs/startup-notification"

RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-1.5 )"

DEPEND="${CDEPEND}
	!dev-util/dmake
	java? ( >=virtual/jdk-1.5
		dev-java/ant-core
		junit? ( dev-java/junit:4 ) )
	odbc? ( dev-db/unixODBC )
	pam? ( sys-libs/pam
		sys-apps/shadow[pam] )
	app-arch/unzip
	app-arch/zip
	dev-lang/perl
	dev-libs/boost-headers
	dev-perl/Archive-Zip
	dev-util/cppunit
	dev-util/intltool
	dev-util/pkgconfig
	dev-vcs/git
	media-gfx/imagemagick
	sys-apps/coreutils
	sys-apps/grep
	sys-devel/bison
	sys-devel/flex
	x11-libs/libXrender
	x11-proto/xextproto
	x11-proto/xineramaproto
	x11-proto/xproto"

PROVIDE="virtual/ooo"

pkg_setup() {
	local err=

	# welcome
	elog
	eerror "This ${PN} version uses the master branch."
	eerror "Expect it to just break."
	elog

	# ...
	if is-flagq -ffast-math; then
		eerror "You are using -ffast-math, which is known to cause problems."
		eerror "Please remove it from your CFLAGS, using this globally causes"
		eerror "all sorts of problems."
		use python && eerror "After that you will also have to - at least - rebuild python"
		use python && eerror "otherwise the ${PN} build will break."
		err=1
	fi

	if is-flagq -finline-functions; then
		eerror "You are using -finline-functions, which is known to cause problems."
		eerror "Please remove it from your CFLAGS."
		err=1
	fi

	# space
	CHECKREQS_MEMORY="512"
	use debug && CHECKREQS_DISK_BUILD="12000" \
		|| CHECKREQS_DISK_BUILD="6000"
	use debug && CHECKREQS_DISK_USR="1024" \
		|| CHECKREQS_DISK_USR="512"
	check_reqs

	[ ${err} ] && die "bad luck"

	# java
	java-pkg-opt-2_pkg_setup

	if ! use java; then
		ewarn "You are building with java-support disabled, this results in some"
		ewarn "of the OpenOffice.org functionality being disabled."
		ewarn "If something you need does not work for you, rebuild with"
		ewarn "java in your USE-flags."
		ewarn
	fi

	# check useflags dependencies
	confutils_use_depend_all !python java
	confutils_use_depend_all junit java
	confutils_use_depend_all languagetool java
	confutils_use_depend_all reportbuilder java
	confutils_use_depend_all wiki java
	confutils_use_depend_all gnome gtk
	confutils_use_depend_all nsplugin gtk

	# lang setup
	strip-linguas ${LANGUAGES}

	# lang conf (i103809)
	if [ -z "${LINGUAS}" ] || [[ ${LINGUAS} == en ]]; then
		export LINGUAS_OOO=
	# but if localized we want en-US for broken code and sdk
	# case: en lingua already set
	# XXX: sad to see bash not matching [^_] to EOS
	elif [[ ${LINGUAS} =~ en([^_]|$) ]]; then
		export LINGUAS_OOO="$(echo ${LINGUAS} | sed -e 's/\ben\b/en_US/;s/_/-/g')"
	# case: en-US lingua not set, add
	else
		export LINGUAS_OOO="en-US ${LINGUAS//_/-}"
	fi

	# kde
	use kde && kde4-base_pkg_setup
}

src_unpack() {
	# layered clone/build process - fun! :)

	# ideal solution:
	# - use eclass/git
	# - clone ooo with specific tag/hash
	# - clone OOo split sources with their own specific tag
	# - anyone? :D

	unpack ${MY_P}.tar.gz

	cd "${S}"

	# prepare paths
	mkdir -p "${CLONE_DIR}"

	pushd "${CLONE_DIR}" >/dev/null
		for module in ${MODULES}; do
			git clone "${GIT_DIR}/${module}"
		done
	popd >/dev/null
}

src_prepare() {
	# specifics not for upstream
	EPATCH_SUFFIX="diff" \
	EPATCH_FORCE="yes" \
	EPATCH_EXCLUDE="$(for f in "${FILESDIR}"/32_*; do basename $f; done)" \
	epatch "${FILESDIR}"

	# gentoo
	local CONFFILE="${S}/distro-configs/GentooUnstable.conf.in"
	cp -dP ${S}/distro-configs/Gentoo.conf.in ${CONFFILE}
	echo "--with-build-version=\\\"geki built ${PV} (unsupported)\\\"" >> ${CONFFILE}

	# gentooexperimental defaults
	echo "--without-afms" >> ${CONFFILE}
	echo "--without-agfa-monotype-fonts" >> ${CONFFILE}
	echo "--without-fonts" >> ${CONFFILE}
	echo "--without-ppds" >> ${CONFFILE}
	echo "--with-linker-hash-style=gnu" >> ${CONFFILE}
	echo "--with-system-cppunit" >> ${CONFFILE}
	echo "--with-system-openssl" >> ${CONFFILE}
	echo "--with-system-redland" >> ${CONFFILE}
#	echo "--with-system-xmlsec" >> ${CONFFILE}
#	echo "--with-vba-package-format=extn" >> ${CONFFILE}
	echo "--enable-xrender-link" >> ${CONFFILE}
	echo "--with-system-xrender-headers" >> ${CONFFILE}
	echo "--disable-systray" >> ${CONFFILE}

	# extensions
	echo "--with-extension-integration" >> ${CONFFILE}
	echo "--enable-minimizer" >> ${CONFFILE}
	echo "--enable-pdfimport" >> ${CONFFILE}
	echo "--enable-presenter-console" >> ${CONFFILE}
	use java && use reportbuilder && echo "--enable-report-builder" >> ${CONFFILE}
	use java && use wiki && echo "--enable-wiki-publisher" >> ${CONFFILE}

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
	echo "$(use_with odbc system-odbc-headers)" >> ${CONFFILE}
	echo "$(use_enable opengl)" >> ${CONFFILE}
	echo "$(use_enable python)" >> ${CONFFILE}
	echo "$(use_enable webdav neon)" >> ${CONFFILE}
	echo "$(use_with webdav system-neon)" >> ${CONFFILE}

	# mysql
	echo "$(use_enable mysql mysql-connector)" >> ${CONFFILE}
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

		# reportbuilder extension
#		if use reportbuilder; then
#			echo "--with-system-jfreereport" >> ${CONFFILE}
#			echo "--with-sac-jar=$(java-pkg_getjar \
#				sac sac.jar)" >> ${CONFFILE}
#			echo "--with-flute-jar=$(java-pkg_getjar \
#				flute-jfree flute-jfree.jar)" >> ${CONFFILE}
#			echo "--with-jcommon-jar=$(java-pkg_getjar \
#				jcommon-1.0 jcommon.jar)" >> ${CONFFILE}
#			echo "--with-jcommon-serializer-jar=$(java-pkg_getjar \
#				jcommon-serializer jcommon-serializer.jar)" >> ${CONFFILE}
#			echo "--with-libfonts-jar=$(java-pkg_getjar \
#				libfonts libfonts.jar)" >> ${CONFFILE}
#			echo "--with-libformula-jar=$(java-pkg_getjar \
#				libformula libformula.jar)" >> ${CONFFILE}
#			echo "--with-liblayout-jar=$(java-pkg_getjar \
#				liblayout liblayout.jar)" >> ${CONFFILE}
#			echo "--with-libloader-jar=$(java-pkg_getjar \
#				libloader libloader.jar)" >> ${CONFFILE}
#			echo "--with-librepository-jar=$(java-pkg_getjar \
#				librepository librepository.jar)" >> ${CONFFILE}
#			echo "--with-libxml-jar=$(java-pkg_getjar \
#				libxml libxml.jar)" >> ${CONFFILE}
#			echo "--with-jfreereport-jar=$(java-pkg_getjar \
#				jfreereport jfreereport.jar)" >> ${CONFFILE}
#		fi

		# wiki extension
		if use wiki; then
			echo "--with-system-apache-commons" >> ${CONFFILE}
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
		fi

		# junit:4
		use junit && echo "--with-junit=$(java-pkg_getjar \
			junit-4 junit.jar)" >> ${CONFFILE}
	fi

	# junit:4
	use !junit && echo "--without-junit" >> ${CONFFILE}

	eautoreconf
}

src_configure() {
	filter-flags "-funroll-loops"
	filter-flags "-fprefetch-loop-arrays"
	filter-flags "-fno-default-inline"
	filter-flags "-O*"
	append-flags "-w"

	# linker flags
	use debug || export LINKFLAGSOPTIMIZE="${LDFLAGS}"
	export LINKFLAGSDEFS="-Wl,-z,defs -L$(get_boost_library_path)"

	# qt/kde --- yay
	use kde && export KDE4DIR="${KDEDIR}"
	use kde && export QT4LIB="/usr/$(get_libdir)/qt4"

	cd ${S}
	./configure \
		--prefix="${EPREFIX}"/usr \
		--sysconfdir="${EPREFIX}"/etc \
		--libdir="${EPREFIX}"/usr/$(get_libdir) \
		--mandir="${EPREFIX}"/usr/share/man \
		--with-git="${CLONE_DIR}" \
		--with-split \
		--with-distro="GentooUnstable" \
		--with-docdir="${EPREFIX}"/usr/share/doc/${PF} \
		--with-drink="cold blood" \
		--with-lang="${LINGUAS_OOO}" \
		--with-arch="${ARCH}" \
		--with-arch-flags="${CXXFLAGS}" \
		--with-num-cpus="$(grep -s -c ^processor /proc/cpuinfo)" \
		--with-binsuffix=no \
		--with-installed-ooo-dirname=${PN} \
		--with-srcdir="${DISTDIR}" \
		--disable-post-install-scripts \
		--with-system-hunspell \
		--with-system-libwpd \
		--with-system-libwpg \
		--with-system-libwps \
		--enable-extensions \
		--enable-cairo \
		--with-system-cairo \
		--disable-access \
		--disable-kde \
		--disable-layout \
		$(use_enable gtk) \
		$(use_enable kde kde4) \
		$(use_enable !debug strip) \
		$(use_with java) \
		$(use_enable mono) \
		$(use_enable pam) \
		$(use_enable odk) \
		$(use_with templates sun-templates) \
		$(use_with blog oooblogger) \
		$(use_with languagetool) \
		|| die "configure failed"
}

src_compile() {
	# download 3rd party software
	# - no more bundled within OOo tarballs
	# - other phases just delete it again, wtf!
	# - tell me, how to do better, please ...
	./download_external_sources.sh

	# build
	make || die "make failed"
}

src_install() {
	# version
	local oover="$(get_version_component_range 1-2)"

	# install
	make DESTDIR="${D}" install || die "install failed"

	# access
	use prefix || chown -RP root:0 "${ED}"

	# record java libraries
	use java && java-pkg_regjar \
		"${ED}/usr/$(get_libdir)/${PN}/basis${oover}/program/classes"/*.jar \
		"${ED}/usr/$(get_libdir)/${PN}/ure/share/java"/*.jar

	# move bash-completion from /etc to /usr/share/bash-completion. bug 226061
	dobashcompletion "${ED}"/etc/bash_completion.d/ooffice.sh ooffice
	rm -rf "${ED}"/etc/bash_completion.d/ || die "rm failed"
}

pkg_postinst() {
	# version
	local oover="$(get_version_component_range 1-2)"

	# mime data
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update

	# hardened
	pax_fix

	# kde4
	use kde && kde4-base_pkg_postinst

	# record jdbc-mysql java library to openoffice classpath if possible
	# - for a happy user experience
	"${EPREFIX}"/usr/$(get_libdir)/${PN}/basis${oover}/program/java-set-classpath \
		$(java-config --classpath=jdbc-mysql 2>/dev/null) >/dev/null

	# bash-completion postinst
	BASHCOMPLETION_NAME=ooffice \
	bash-completion_pkg_postinst

	# info
	elog " To start OpenOffice.org, run:"
	elog
	elog " $ ooffice"
	elog
	elog "__________________________________________________________________"
	elog " Also, for individual components, you can use any of:"
	elog
	elog " oobase, oocalc, oodraw, oofromtemplate,"
	elog " ooimpress, oomath, ooweb or oowriter"
	elog
	elog "__________________________________________________________________"
	elog " Some parts have to be installed via Extension Manager now"
	ewarn " - VBA (VisualBasic-Assistant) support is no longer an extension"
	elog " - pdfimport"
	elog " - presentation console"
	elog " - presentation minimizer"
	use java && use reportbuilder && \
		elog " - report builder"
	use java && use wiki && \
		elog " - wiki publisher"
	use mysql && elog " - MySQL (native) database connector (beta stadium!)"
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

pax_fix() {
	if [ -x ${EPREFIX}/sbin/chpax ] || [ -x ${EPREFIX}/sbin/paxctl ]; then
		local bin="${EPREFIX}/usr/$(get_libdir)/${PN}/program/soffice.bin"
		[ -e ${bin} ] && scanelf -Xxzm ${bin}
	fi
}
