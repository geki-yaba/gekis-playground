# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Author: Hanno Meyer-Thurow <h.mth@web.de>
# Purpose: unified build of libreoffice
#

#
# TODO: proper documentation of eclass like portage/eclass/xorg-2.eclass
#

# 3.5
# TODO:	>=gnome-base/librsvg-2.32.1:2
#		--enable-librsvg=system
#		--enable-python - disabled: no translations!
#		--with-system-python removed
#		--disable-gtk3
#		--enable-cairo => --enable-cairo-canvas
#		--with-system-libvisio
#		--with-system-gettext
#		--with-system-libpng
#		--enable-release-build: debug build by default, yay! :D
#
# superfluous diff: as-needed, gbuild, ldflags, translate_toolkit-solenv
#

EAPI="4"

_libreoffice_python="<<*:2.6:3.1[threads,xml]>>"
PYTHON_BDEPEND="${_libreoffice_python}"
PYTHON_DEPEND="python? ( ${_libreoffice_python} )"

KDE_REQUIRED="never"
CMAKE_REQUIRED="never"

inherit autotools bash-completion boost-utils check-reqs db-use eutils \
	flag-o-matic java-pkg-opt-2 kde4-base multilib pax-utils python versionator \
	nsplugins
# inherit mono

[[ ${PV} == *_pre ]] && inherit git-2

EXPORT_FUNCTIONS pkg_pretend pkg_setup src_unpack src_prepare src_configure src_compile src_install pkg_preinst pkg_postinst pkg_postrm

DESCRIPTION="LibreOffice - a productivity suite (experimental version)"
HOMEPAGE="http://www.libreoffice.org/"

SLOT="0"

LICENSE="LGPL-3"
RESTRICT="binchecks mirror"

IUSE="+branding cups custom-cflags dbus debug eds gnome graphite gstreamer gtk
jemalloc junit kde languagetool ldap mysql nsplugin odbc odk offlinehelp opengl
+python reportbuilder templates +vba webdav wiki"
# mono, postgres - system only diff available - no chance to choose! :(

# available languages
LANGUAGES="af ar as ast be_BY bg bn bo br brx bs ca ca_XV cs cy da de dgo dz el
en en_GB en_ZA eo es et eu fa fi fr ga gd gl gu he hi hr hu id is it ja ka kk km
kn kok ko ks ku ky lo lt lv mai mk ml mn mni mr ms my nb ne nl nn nr ns oc om or
pa pap pl ps pt pt_BR ro ru rw sat sd sh si sk sl sq sr ss st sv sw_TZ ta te tg
th ti tn tr ts ug uk uz ve vi xh zh_CN zh_TW zu"

for language in ${LANGUAGES}; do
	IUSE+=" linguas_${language}"
done

# config
MY_PV="$(get_version_component_range 1-2)"

# paths
LIBRE_URI="${LIBRE_URI:="http://download.documentfoundation.org/libreoffice/src"}"
EXT_URI="http://ooo.itc.hu/oxygenoffice/download/libreoffice"
BRAND_URI="http://dev.gentooexperimental.org/~scarabeus"

# branding
BRAND_SRC="${PN}-branding-gentoo-0.3.tar.xz"

# available templates
# - en_* => en_US templates for simplicity; fix:
# https://forums.gentoo.org/viewtopic-p-6449940.html#6449940
# FIXME: assoc arrays in global namespace impossible?! anyone enlighten me, please!
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

# libreoffice modules
MODULES="artwork base calc components extensions extras filters help impress
libs-core libs-extern libs-extern-sys libs-gui postprocess sdk testing ure
writer translations"

if [[ ${PV} != *_pre ]]; then
	SRC_URI+=" ${LIBRE_URI}/${PN}-bootstrap-${PV}.tar.bz2"

	for module in ${MODULES}; do
		SRC_URI+=" ${LIBRE_URI}/${PN}-${module}-${PV}.tar.bz2"
	done
fi

# available app-dicts/myspell dictionaries
MYSPELLS="af bg ca cs cy da de el en eo es et fr ga gl he hr hu it ku lt mk nb
nl nn pl pt ru sk sl sv tn zu"

SDEPEND=""
for language in ${MYSPELLS}; do
	SDEPEND+=" linguas_${language}? ( app-dicts/myspell-${language} )"
done

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
#	mono? ( dev-lang/mono )
CDEPEND="${SDEPEND}
	cups? ( net-print/cups )
	dbus? ( dev-libs/dbus-glib )
	eds? ( gnome-extra/evolution-data-server )
	gnome? ( gnome-base/gconf:2 )
	graphite? ( media-gfx/graphite2 )
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
	  app-text/mythes
	  app-text/poppler[xpdf-headers]
	  dev-libs/boost[program_options,thread]
	  dev-libs/expat
	>=dev-libs/hyphen-2.7.1
	  dev-libs/icu
	  dev-libs/libxml2
	  dev-libs/libxslt
	  dev-libs/openssl
	  dev-libs/redland[ssl]
	  dev-util/gperf
	  media-libs/fontconfig
	  media-libs/freetype:2
	  media-libs/libpng
	  app-text/libwpg:0.2
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
	java? ( >=virtual/jre-1.5 )"

DEPEND="${CDEPEND}
	!dev-util/dmake
	java? ( >=virtual/jdk-1.5
		dev-java/ant-core )
	junit? ( dev-java/junit:4 )
	odbc? ( dev-db/unixODBC )
	app-arch/unzip
	app-arch/zip
	dev-lang/perl
	dev-libs/boost-headers
	dev-perl/Archive-Zip
	dev-util/cppunit
	dev-util/intltool
	dev-util/mdds
	dev-util/pkgconfig
	media-gfx/imagemagick[png]
	sys-apps/coreutils
	sys-apps/grep
	sys-devel/bison
	sys-devel/flex
	x11-libs/libXrender
	x11-proto/randrproto
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

	# kde
	use kde && kde4-base_pkg_setup

	# python
	local lo_python_version=2
	# python 3 if skipping translate-toolkit
	[ -z "${LINGUAS}" ] && lo_python_version=3

	python_set_active_version ${lo_python_version}
	python_pkg_setup

	# lang setup
	strip-linguas ${LANGUAGES}
}

libreoffice_src_unpack() {
	local clone="${S}/clone"

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
			EGIT_REPO_URI="${root}/${module}"
			EGIT_SOURCEDIR="${clone}/${module}"
			git_src_unpack
		done
	else
		unpack "${PN}-bootstrap-${PV}.tar.bz2"

		cd "${clone}"

		# unpack modules
		for module in ${MODULES}; do
			unpack "${PN}-${module}-${PV}.tar.bz2"
		done
	fi

	# link source into tree
	ln -sf "${clone}"/*/* "${S}"

	# branding
	if use branding; then
		cd "${S}"/src
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
	EPATCH_SUFFIX="diff"
	EPATCH_FORCE="yes"
	epatch "${FILESDIR}"

	# allow user to apply any additional patches without modifying ebuild
	epatch_user

	# FIXME: 3.5 done
	# disable printeradmin
	sed -e "s:.*printeradmin:#\0:" \
		-i "${S}"/sysui/desktop/share/create_tree.sh \
		|| die

	# FIXME: 3.5 done
	# honour linker hash-style
	sed -r -e "s:(hash-style)=both:\1=\$(WITH_LINKER_HASH_STYLE):" \
		-i "${S}"/solenv/gbuild/platform/unxgcc.mk

	# lang conf (i103809)
	local languages
	if [ -z "${LINGUAS}" ] || [[ ${LINGUAS} == en ]]; then
		languages=
	# but if localized we want en-US for broken code and sdk
	# case: en lingua already set
	elif [[ ${LINGUAS} =~ en( |$) ]]; then
		languages="$(sed -e 's/\ben\b/en_US/;s/_/-/g' <<< ${LINGUAS})"
	# case: en_US lingua not set, add
	else
		languages="en-US ${LINGUAS//_/-}"
	fi

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
	echo "--with-lang=${languages}" >> ${config}
	echo "--with-num-cpus=$(grep -s -c ^processor /proc/cpuinfo)" >> ${config}
	use branding && echo "--with-about-bitmap=${S}/src/branding-about.png" >> ${config}
	use branding && echo "--with-intro-bitmap=${S}/src/branding-intro.png" >> ${config}
	echo "$(use_enable gtk)" >> ${config}
	echo "$(use_enable kde kde4)" >> ${config}
#	echo "$(use_enable mono)" >> ${config}
	echo "$(use_enable odk)" >> ${config}
	echo "$(use_with java)" >> ${config}
	echo "$(use_with templates sun-templates)" >> ${config}

	# extensions
	echo "$(use_enable reportbuilder ext-report-builder)" >> ${config}
	echo "$(use_enable wiki ext-wiki-publisher)" >> ${config}
	echo "$(use_enable mysql ext-mysql-connector)" >> ${config}
	# FIXME: enable-ext
	echo "$(use_with languagetool)" >> ${config}

	# internal
	echo "$(use_enable dbus)" >> ${config}
	echo "$(use_enable debug symbols)" >> ${config}
	echo "$(use_with offlinehelp helppack-integration)" >> ${config}
	echo "$(use_enable vba)" >> ${config}
	use jemalloc && echo "--with-alloc=jemalloc" >> ${config}

	# system
	echo "$(use_enable cups)" >> ${config}
	echo "$(use_enable eds evolution2)" >> ${config}
	echo "$(use_enable graphite)" >> ${config}
	echo "$(use_with graphite system-graphite)" >> ${config}
	echo "$(use_enable ldap)" >> ${config}
	echo "$(use_with ldap openldap)" >> ${config}
	echo "$(use_with odbc system-odbc)" >> ${config}
	echo "$(use_enable opengl)" >> ${config}
	echo "$(use_with opengl system-mesa-headers)" >> ${config}
	# FIXME: lo 3.5 fubared :(
	echo "$(use_enable python)" >> ${config}
	echo "$(use_enable webdav neon)" >> ${config}
	echo "$(use_with webdav system-neon)" >> ${config}

	# mysql
	echo "$(use_with mysql system-mysql)" >> ${config}
	echo "$(use_with mysql system-mysql-cppconn)" >> ${config}

	# browser
	echo "$(use_enable nsplugin mozilla)" >> ${config}
	echo "$(use_with nsplugin system-mozilla libxul)" >> ${config}

	# gnome
	echo "--disable-gnome-vfs" >> ${config}
	echo "$(use_enable gtk gio)" >> ${config}
	echo "$(use_enable gnome lockdown)" >> ${config}
	echo "$(use_enable gnome gconf)" >> ${config}
	echo "$(use_enable gnome systray)" >> ${config}
	echo "$(use_enable gstreamer)" >> ${config}

	# java
	if use java; then
		echo "--with-ant-home=${ANT_HOME}" >> ${config}
		echo "--with-jdk-home=$(java-config --jdk-home 2>/dev/null)" >> ${config}
		echo "--with-java-target-version=1.5" >> ${config}
		echo "--with-jvm-path=/usr/$(get_libdir)/" >> ${config}
		echo "--with-system-beanshell" >> ${config}
#		echo "--with-system-hsqldb" >> ${config}
		echo "--with-system-lucene" >> ${config}
#		echo "--with-system-saxon" >> ${config}
		echo "--with-beanshell-jar=$(java-pkg_getjar bsh bsh.jar)" >> ${config}
#		echo "--with-hsqldb-jar=$(java-pkg_getjar hsqldb hsqldb.jar)" >> ${config}
		echo "--with-lucene-core-jar=$(java-pkg_getjar \
			lucene-2.9 lucene-core.jar)" >> ${config}
		echo "--with-lucene-analyzers-jar=$(java-pkg_getjar \
			lucene-2.9 lucene-analyzers.jar)" >> ${config}
#		echo "--with-saxon-jar=$(java-pkg_getjar saxon-9 saxon.jar)" >> ${config}

		# junit:4
		use junit && echo "--with-junit=$(java-pkg_getjar \
			junit-4 junit.jar)" >> ${config}
	fi

	# junit:4
	use !junit && echo "--without-junit" >> ${config}

	# reportbuilder extension
#	if use reportbuilder; then
#		echo "--with-system-jfreereport" >> ${config}
#		echo "--with-sac-jar=$(java-pkg_getjar \
#			sac sac.jar)" >> ${config}
#		echo "--with-flute-jar=$(java-pkg_getjar \
#			flute-jfree flute-jfree.jar)" >> ${config}
#		echo "--with-jcommon-jar=$(java-pkg_getjar \
#			jcommon-1.0 jcommon.jar)" >> ${config}
#		echo "--with-jcommon-serializer-jar=$(java-pkg_getjar \
#			jcommon-serializer jcommon-serializer.jar)" >> ${config}
#		echo "--with-libfonts-jar=$(java-pkg_getjar \
#			libfonts libfonts.jar)" >> ${config}
#		echo "--with-libformula-jar=$(java-pkg_getjar \
#			libformula libformula.jar)" >> ${config}
#		echo "--with-liblayout-jar=$(java-pkg_getjar \
#			liblayout liblayout.jar)" >> ${config}
#		echo "--with-libloader-jar=$(java-pkg_getjar \
#			libloader libloader.jar)" >> ${config}
#		echo "--with-librepository-jar=$(java-pkg_getjar \
#			librepository librepository.jar)" >> ${config}
#		echo "--with-libxml-jar=$(java-pkg_getjar \
#			libxml libxml.jar)" >> ${config}
#		echo "--with-jfreereport-jar=$(java-pkg_getjar \
#			jfreereport jfreereport.jar)" >> ${config}
#	fi

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

	# silent miscompiles; LO/OOo adds -O2/1/0 where appropriate
	filter-flags "-O*"

	# optimize
	export ARCH_FLAGS="${CXXFLAGS}"

	# linker flags
	# FIXME: as-needed seems to be fixed in 3.5?!
	append-ldflags "-Wl,--no-as-needed"
	use debug || export LINKFLAGSOPTIMIZE="${LDFLAGS}"
	export LINKFLAGSDEFS="-Wl,-z,defs -L$(boost-utils_get_library_path)"

	# qt/kde --- yay
	use kde && export KDE4DIR="${KDEDIR}"
	use kde && export QT4LIB="/usr/$(get_libdir)/qt4"

	./autogen.sh --with-distro="GentooUnstable" \
		|| die "configure failed"
}

libreoffice_src_compile() {
	# FIXME: necessary for 3.5?!
	# no need to download external sources
	# although we set two configure flags already for this ...
	touch src.downloaded

	# build
	make || die "make failed"
}

libreoffice_src_install() {
	# install
	make DESTDIR="${ED}" distro-pack-install || die "install failed"

	# access
	use prefix || chown -RP root:0 "${ED}"

	if use branding; then
		insinto /usr/$(get_libdir)/${PN}/program
		newins "${S}/src/branding-sofficerc" sofficerc || die
	fi

	use nsplugin && inst_plugin \
		/usr/$(get_libdir)/${PN}/program/libnpsoplugin.so
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

	# bash-completion postinst
	BASHCOMPLETION_NAME="libreoffice" \
	bash-completion_pkg_postinst

	# info
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
	# custom-cflags
	_libreoffice_custom-cflags_message

	# python version
	echo "Python: $(python_get_version)"
}
