# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit eutils rpm versionator

DESCRIPTION="Translations for LibreOffice"
HOMEPAGE="http://www.libreoffice.org"

SLOT="0"

LICENSE="LGPL-3"
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="offlinehelp"

RESTRICT="strip"

LANGUAGES="af ar as ast be bg bn bo br brx bs ca ca_XV cs cy da de dgo dz el
en en_GB en_ZA eo es et eu fa fi fr ga gl gu he hi hr hu id is it ja ka kk km
kn kok ko ks ku lo lt lv mai mk ml mn mni mr my nb ne nl nn nr nso oc om or
pa_IN pl pt pt_BR ro ru rw sat sd sh si sk sl sq sr ss st sv sw_TZ ta te tg
th tn tr ts ug uk uz ve vi xh zh_CN zh_TW zu"
LANGUAGES_HELP="bg bn bo bs ca ca_XV cs da de dz el en-US en-GB en-ZA eo es et
eu fi fr gl gu he hi hr hu id is it ja ka km ko mk nb ne nl nn om pl pt pt_BR ru
si sk sl sq sv tg tr ug uk vi zh_CN zh_TW"

MY_PN="${PN/-l10n}"
MY_PVR="beta0"
BASE_URI="http://download.documentfoundation.org/${MY_PN}/testing/${PV}-${MY_PVR}"
RPM_LANG_URI="${BASE_URI}/rpm/x86/LibO_${PV}${MY_PVR}_Linux_x86_langpack-rpm"
RPM_HELP_URI="${RPM_LANG_URI/langpack/helppack}"

for language in ${LANGUAGES}; do
	langpack="" helppack=""
	lingua="${language/_/-}"

	[[ ${language} == en ]] && lingua="en-US" \
		|| langpack="${RPM_LANG_URI}_${lingua}.tar.gz"
	[[ "${LANGUAGES_HELP}" =~ "${language}" ]] \
		&& helppack="offlinehelp? ( ${RPM_HELP_URI}_${lingua}.tar.gz )"
	IUSE+=" linguas_${language}"
	SRC_URI+=" linguas_${language}? ( ${langpack} ${helppack} )"
done

# available app-dicts/myspell dictionaries
MYSPELLS="af bg ca cs cy da de el en eo es et fr ga gl he hr hu it ku lt mk nb
nl nn pl pt ru sk sl sv tn zu"

SDEPEND=""
for language in ${MYSPELLS}; do
	SDEPEND+=" linguas_${language}? ( app-dicts/myspell-${language} )"
done

DEPEND="=app-office/libreoffice-${PV}_pre"
PDEPEND="${SDEPEND}"

S="${WORKDIR}"

pkg_setup() {
	strip-linguas ${LANGUAGES}
}

src_unpack() {
	default

	local lang_path help_path
	for language in ${LINGUAS//_/-}; do
		lang_path="LibO_${PV}${MY_PVR}_Linux_x86_langpack-rpm_${language}/RPMS/"
		help_path="${lang_path/langpack/helppack}"

		if [[ ${language} != en ]]; then
			[ -d "${S}"/${lang_path} ] || die "${S}/${lang_path} not found!"

			# remove dictionaries
			rm -v "${S}"/${lang_path}/*dict*.rpm

			rpm_unpack ./${lang_path}/*.rpm
		fi

		[[ ${language} == en ]] && language="en-US"
		if [[ "${LANGUAGES_HELP}" =~ "${language}" ]] && use offlinehelp; then
			help_path="${help_path/_en/_en-US}"
			[ -d "${S}"/${help_path} ] || die "${S}/${help_path} not found!"

			rpm_unpack ./${help_path}/*.rpm
		fi
	done
}

src_prepare() { :; }

src_configure() { :; }

src_compile() { :; }

src_install() {
	local version="$(get_version_component_range 1-2)"
	local path="${S}/opt/${MY_PN}${version}"

	# no linguas set or en without offlinehelp
	if [ -d "${path}" ] ; then
		insinto /usr/$(get_libdir)/${MY_PN}
		doins -r "${path}"/*
	fi
}

