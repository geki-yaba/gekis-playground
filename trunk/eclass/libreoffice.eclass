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

EAPI="4"

_libreoffice_java="1.6"
_libreoffice_python="*:3.1:3.1"
PYTHON_BDEPEND="${_libreoffice_python}"
PYTHON_DEPEND="python? ${_libreoffice_python}"

KDE_REQUIRED="never"
CMAKE_REQUIRED="never"

inherit autotools base bash-completion-r1 boost-utils check-reqs flag-o-matic \
	java-pkg-opt-2 kde4-base multilib pax-utils python versionator nsplugins git-2

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_configure src_compile src_test src_install pkg_preinst pkg_postinst pkg_postrm

DESCRIPTION="LibreOffice - a productivity suite (geki version)"
HOMEPAGE="http://www.libreoffice.org/"

SLOT="0"

LICENSE="LGPL-3"
RESTRICT="binchecks mirror"

IUSE="+branding custom-cflags dbus debug eds gnome graphite gstreamer gtk gtk3
junit kde ldap mysql nlpsolver nsplugin odbc odk opengl pdfimport postgres
+python reportbuilder templates test webdav wiki xmlsec"

# config
MY_PV="$(get_version_component_range 1-2)"

# available template languages
LANGUAGES="de en en_GB en_ZA es fr hu it"

for language in ${LANGUAGES}; do
	IUSE+=" linguas_${language}"
done

# paths
LIBRE_URI="http://dev-www.libreoffice.org/bundles"
EXT_URI="http://ooo.itc.hu/oxygenoffice/download/libreoffice"
BRAND_URI="http://dev.gentooexperimental.org/~scarabeus"

# branding
BRAND_SRC="${PN}-branding-gentoo-0.4.tar.xz"

# templates
TDEPEND=""
TDEPEND+=" linguas_de? ( ${EXT_URI}/53ca5e56ccd4cab3693ad32c6bd13343-Sun-ODF-Template-Pack-de_1.0.0.oxt )"
TDEPEND+=" linguas_en? ( ${EXT_URI}/472ffb92d82cf502be039203c606643d-Sun-ODF-Template-Pack-en-US_1.0.0.oxt )"
TDEPEND+=" linguas_en_GB? ( ${EXT_URI}/472ffb92d82cf502be039203c606643d-Sun-ODF-Template-Pack-en-US_1.0.0.oxt )"
TDEPEND+=" linguas_en_ZA? ( ${EXT_URI}/472ffb92d82cf502be039203c606643d-Sun-ODF-Template-Pack-en-US_1.0.0.oxt )"
TDEPEND+=" linguas_es? ( ${EXT_URI}/4ad003e7bbda5715f5f38fde1f707af2-Sun-ODF-Template-Pack-es_1.0.0.oxt )"
TDEPEND+=" linguas_fr? ( ${EXT_URI}/a53080dc876edcddb26eb4c3c7537469-Sun-ODF-Template-Pack-fr_1.0.0.oxt )"
TDEPEND+=" linguas_hu? ( ${EXT_URI}/09ec2dac030e1dcd5ef7fa1692691dc0-Sun-ODF-Template-Pack-hu_1.0.0.oxt )"
TDEPEND+=" linguas_it? ( ${EXT_URI}/b33775feda3bcf823cad7ac361fd49a6-Sun-ODF-Template-Pack-it_1.0.0.oxt )"

SRC_URI="branding? ( ${BRAND_URI}/${BRAND_SRC} )
	templates? ( ${TDEPEND} )"

# modules
MODULES="core help"

if [[ ${PV} != *_pre ]]; then
	for module in ${MODULES}; do
		SRC_URI+=" ${LIBRE_URI}/${PN}-${module}.tar.xz"
	done
fi
PATCHES=( "${FILESDIR}" )

CDEPEND="
	dbus? ( dev-libs/dbus-glib )
	eds? ( gnome-extra/evolution-data-server )
	gnome? ( gnome-base/gconf:2 )
	graphite? ( media-gfx/graphite2 )
	gstreamer? ( media-libs/gstreamer
		media-libs/gst-plugins-base )
	gtk? ( x11-libs/gtk+:2 )
	gtk3? ( x11-libs/gtk+:3 )
	java? ( dev-java/bsh
		dev-java/lucene:2.9[analyzers] )
	kde? ( x11-libs/qt-core
		x11-libs/qt-gui
		kde-base/kdelibs
		kde-base/kstyles )
	ldap? ( net-nds/openldap )
	nsplugin? ( net-misc/npapi-sdk )
	mysql? ( dev-db/mysql-connector-c++:1.1.0 )
	opengl? ( virtual/opengl virtual/glu )
	pdfimport? ( app-text/poppler[cxx,xpdf-headers] )
	postgres? ( dev-db/postgresql-base )
	reportbuilder? ( dev-java/commons-logging:0 )
	webdav? ( net-libs/neon )
	wiki? ( dev-java/commons-codec:0
		dev-java/commons-httpclient:3
		dev-java/commons-lang:2.1
		dev-java/commons-logging:0
		dev-java/tomcat-servlet-api:2.4 )
	xmlsec? ( dev-libs/nspr
		dev-libs/nss )
	  app-text/hunspell
	  app-text/libexttextcat
	  app-text/libwpd:0.9[tools]
	  app-text/libwpg:0.2
	  app-text/libwps:0.2
	  app-text/mythes
	  dev-cpp/libcmis
	  dev-libs/expat
	>=dev-libs/hyphen-2.7.1
	  dev-libs/icu
	  dev-libs/jemalloc
	  dev-libs/libxml2
	  dev-libs/libxslt
	  dev-libs/openssl
	  dev-libs/redland[ssl]
	>=gnome-base/librsvg-2.32.1:2
	  media-libs/fontconfig
	  media-libs/freetype:2
	  media-libs/libpng
	  media-libs/libvisio
	  net-misc/curl
	  net-print/cups
	  sci-mathematics/lpsolve
	>=sys-libs/db-4.7
	  sys-libs/zlib
	  x11-libs/libXrender
	  x11-libs/cairo[X,svg]
	  x11-libs/libXaw
	  x11-libs/libXinerama
	  x11-libs/libXrandr
	  x11-libs/libXtst
	  x11-libs/startup-notification
	  virtual/jpeg"

#PDEPEND="~app-office/libreoffice-l10n-$(get_version_component_range 1-3)"

RDEPEND="${CDEPEND}
	java? ( >=virtual/jre-${_libreoffice_java} )"

DEPEND="${CDEPEND}
	java? ( virtual/jdk:${_libreoffice_java}
		dev-java/ant-core )
	junit? ( dev-java/junit:4 )
	odbc? ( dev-db/unixODBC )
	app-arch/zip
	app-arch/unzip
	dev-lang/perl
	dev-libs/boost-headers
	dev-perl/Archive-Zip
	dev-util/cppunit
	dev-util/gperf
	dev-util/intltool
	dev-util/mdds
	dev-util/pkgconfig
	media-gfx/imagemagick[png]
	media-libs/vigra
	sys-apps/coreutils
	sys-apps/grep
	sys-devel/bison
	sys-devel/flex
	sys-devel/gettext
	x11-proto/randrproto
	x11-proto/xextproto
	x11-proto/xineramaproto
	x11-proto/xproto"

_libreoffice_use_gtk="|| ( gtk gtk3 )"
REQUIRED_USE="eds? ( ${_libreoffice_use_gtk} )
	gnome? ( ${_libreoffice_use_gtk} )
	junit? ( java )
	reportbuilder? ( java )
	wiki? ( java )"

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

	_libreoffice_custom-cflags_message

	# skip build-time info for binary merge
	[[ ${MERGE_TYPE} == binary ]] && return

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
}

libreoffice_pkg_setup() {
	java-pkg-opt-2_pkg_setup

	use kde && kde4-base_pkg_setup

	python_set_active_version 3
	python_pkg_setup
}

libreoffice_src_unpack() {
	if [[ ${PV} == *_pre ]]; then
		local root="git://anongit.freedesktop.org/${PN}"
		EGIT_BRANCH="${EGIT_BRANCH:-${PN}-$(replace_all_version_separators - ${MY_PV})}"
		EGIT_COMMIT="${EGIT_BRANCH}"

		# clone modules
		for module in ${MODULES}; do
			EGIT_PROJECT="${PN}/${module}"
			EGIT_REPO_URI="${root}/${module}"

			[[ ${module} != core ]] && EGIT_SOURCEDIR="${WORKDIR}/${module}"
			EGIT_NOUNPACK=1
			git-2_src_unpack
		done
	else
		# unpack modules
		for module in ${MODULES}; do
			unpack "${PN}-${module}.tar.xz"
		done
	fi

	if use branding; then
		cd "${WORKDIR}"
		unpack "${BRAND_SRC}"
	fi

	# copy extension templates; o what fun ...
	if use templates; then
		local tmplfile tmplname
		local dest="${S}/extras/source/extensions"
		mkdir -p "${dest}"

		for template in ${TDEPEND}; do
			if [[ ${template: -3:3} == oxt ]]; then
				tmplfile="${DISTDIR}/$(basename ${template})"
				tmplname="$(echo "${template}" | \
					cut -f 2- -s -d - | cut -f 1 -d _)"

				[ -f ${tmplfile} ] && [ ! -f "${dest}/${tmplname}".oxt ] \
					&& { cp -v "${tmplfile}" "${dest}/${tmplname}".oxt || die; }
			fi
		done
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
		< "${FILESDIR}"/conf/GentooUnstable-${CONFFILE} \
		> ${config} \
		|| die "base configuration generation failed"

	# gentoo
	echo "--prefix=${EPREFIX}/usr" >> ${config}
	echo "--sysconfdir=${EPREFIX}/etc" >> ${config}
	echo "--libdir=${EPREFIX}/usr/$(get_libdir)" >> ${config}
	echo "--mandir=${EPREFIX}/usr/share/man" >> ${config}
	echo "--docdir=${EPREFIX}/usr/share/doc/${PF}" >> ${config}
	echo "--with-build-version=geki built ${PV} (unsupported)" >> ${config}
	echo "--with-external-tar=${DISTDIR}" >> ${config}
	echo "--with-num-cpus=$(grep -s -c ^processor /proc/cpuinfo)" >> ${config}
	use branding && echo "--with-about-bitmap=${WORKDIR}/branding-about.png" >> ${config}
	use branding && echo "--with-intro-bitmap=${WORKDIR}/branding-intro.png" >> ${config}
	echo "$(use_enable !debug release-build)" >> ${config}
	echo "$(use_enable gtk)" >> ${config}
	echo "$(use_enable gtk3)" >> ${config}
	echo "$(use_enable kde kde4)" >> ${config}
	echo "$(use_enable odk)" >> ${config}
	echo "$(use_with java)" >> ${config}
	echo "$(use_with templates sun-templates)" >> ${config}

	# extensions
	echo "$(use_enable mysql ext-mysql-connector)" >> ${config}
	echo "$(use_enable nlpsolver ext-nlpsolver)" >> ${config}
	echo "$(use_enable pdfimport ext-pdfimport)" >> ${config}
	echo "$(use_enable reportbuilder ext-report-builder)" >> ${config}
	echo "$(use_enable wiki ext-wiki-publisher)" >> ${config}

	# internal
	echo "$(use_enable dbus)" >> ${config}
	echo "$(use_enable debug symbols)" >> ${config}
	echo "$(use_enable test linkoo)" >> ${config}
	echo "$(use_enable xmlsec)" >> ${config}

	# system
	echo "$(use_enable eds evolution2)" >> ${config}
	echo "$(use_enable graphite)" >> ${config}
	echo "$(use_with graphite system-graphite)" >> ${config}
	echo "$(use_enable ldap)" >> ${config}
	echo "$(use_with ldap openldap)" >> ${config}
	echo "$(use_with odbc system-odbc)" >> ${config}
	echo "$(use_enable opengl)" >> ${config}
	echo "$(use_with opengl system-mesa-headers)" >> ${config}
	echo "$(use_enable webdav neon)" >> ${config}
	echo "$(use_with webdav system-neon)" >> ${config}

	# sql
	echo "$(use_with mysql system-mysql)" >> ${config}
	echo "$(use_with mysql system-mysql-cppconn)" >> ${config}
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
		echo "--with-jdk-home=$(java-config --jdk-home 2>/dev/null)" >> ${config}
		echo "--with-java-target-version=${_libreoffice_java}" >> ${config}
		echo "--with-jvm-path=/usr/$(get_libdir)/" >> ${config}
		echo "--with-system-beanshell" >> ${config}
		echo "--with-system-lucene" >> ${config}
		echo "--with-beanshell-jar=$(java-pkg_getjar bsh bsh.jar)" >> ${config}
		echo "--with-lucene-core-jar=$(java-pkg_getjar \
			lucene-2.9 lucene-core.jar)" >> ${config}
		echo "--with-lucene-analyzers-jar=$(java-pkg_getjar \
			lucene-2.9 lucene-analyzers.jar)" >> ${config}

		# junit:4
		use junit && echo "--with-junit=$(java-pkg_getjar \
			junit-4 junit.jar)" >> ${config}
	fi

	# junit:4
	use !junit && echo "--without-junit" >> ${config}

	# wiki extension
	if use wiki; then
		echo "--with-system-servlet-api" >> ${config}
		echo "--with-commons-codec-jar=$(java-pkg_getjar \
			commons-codec commons-codec.jar)" >> ${config}
		echo "--with-commons-httpclient-jar=$(java-pkg_getjar \
			commons-httpclient-3 commons-httpclient.jar)" >> ${config}
		echo "--with-commons-lang-jar=$(java-pkg_getjar \
			commons-lang-2.1 commons-lang.jar)" >> ${config}
		echo "--with-servlet-api-jar=$(java-pkg_getjar \
			tomcat-servlet-api-2.4 servlet-api.jar)" >> ${config}
	fi

	# reportbuilder & wiki extension
	if use reportbuilder || use wiki; then
		echo "--with-commons-logging-jar=$(java-pkg_getjar \
			commons-logging commons-logging.jar)" >> ${config}
		echo "--with-system-apache-commons" >> ${config}
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

	# silent miscompiles; LO adds -O2/1/0 where appropriate
	filter-flags "-O*"

	# optimize
	export ARCH_FLAGS="${CXXFLAGS}"

	# linker flags
	use debug || export LINKFLAGSOPTIMIZE="${LDFLAGS}"
	export LINKFLAGSDEFS="-Wl,-z,defs -L$(boost-utils_get_library_path)"

	# qt/kde --- yay
	use kde && export KDE4DIR="${KDEDIR}"
	use kde && export QT4LIB="/usr/$(get_libdir)/qt4"

	./autogen.sh --with-distro="GentooUnstable" \
		|| die "configure failed"
}

libreoffice_src_compile() {
	# hack for offlinehelp, this needs fixing upstream at some point
	# it is broken because we send --without-help
	# https://bugs.freedesktop.org/show_bug.cgi?id=46506
	(
		grep -v ^WORKDIR "${S}/Env.Host.sh" > "${S}/My.Host.sh"
		source "${S}/My.Host.sh"

		local path="${SOLARVER}/${INPATH}/res/img"
		mkdir -p "${path}"

		perl "${WORKDIR}/help/helpcontent2/helpers/create_ilst.pl" \
			-dir=default_images/res/helpimg \
			> "${path}/helpimg.ilst"
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

	use nsplugin && inst_plugin \
		/usr/$(get_libdir)/${PN}/program/libnpsoplugin.so

	# hack for offlinehelp, this needs fixing upstream at some point
	# it is broken because we send --without-help
	# https://bugs.freedesktop.org/show_bug.cgi?id=46506
	insinto /usr/$(get_libdir)/libreoffice/help
	doins xmlhelp/util/*.xsl
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
	ewarn " - VBA (VisualBasic-Assistant) support is no longer an extension"
	use pdfimport && elog " - pdfimport"
	elog " - presentation console"
	elog " - presentation minimizer"
	elog " - presentation ui"
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

if ! has _libreoffice_die ${EBUILD_DEATH_HOOKS}; then
	EBUILD_DEATH_HOOKS+=" _libreoffice_die"
fi

_libreoffice_die() {
	_libreoffice_custom-cflags_message

	echo "Python: $(python_get_version)"
}

