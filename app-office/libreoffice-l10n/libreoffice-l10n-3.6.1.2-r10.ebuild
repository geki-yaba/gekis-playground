# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit eutils multilib rpm versionator

DESCRIPTION="Translations for LibreOffice"
HOMEPAGE="http://www.libreoffice.org"

SLOT="0"

LICENSE="|| ( LGPL-3 MPL-1.1 )"
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux"
IUSE="offlinehelp"

RESTRICT="binchecks mirror strip"

LANGUAGES="af am ar as be bg bn bo br brx bs ca ca_XV cs cy da de dgo dz el en
en_GB en_ZA eo es et eu fa fi fr ga gd gl gu he hi hr hu id is it ja ka kk km
kn kok ko ks ku lb lo lt lv mai mk ml mn mni mr my nb ne nl nn nr nso oc om or
pa_IN pl pt pt_BR ro ru rw sa_IN sat sd sh si sk sl sq sr ss st sv sw_TZ ta te
tg th tn tr ts tt ug uk uz ve vi xh zh_CN zh_TW zu"
LANGUAGES_HELP="bg bn bo bs ca ca_XV cs da de dz el en-US en-GB en-ZA eo es et
eu fi fr gl gu he hi hr hu id is it ja ka km ko lb mk nb ne nl nn om pl pt
pt_BR ru si sk sl sq sv tg tr ug uk vi zh_CN zh_TW"

LN="${PN/-l10n}"
LV2="$(get_version_component_range 1-2)"
LV3="$(get_version_component_range 1-3)"

L10N_RPM="LibO_${PV}_Linux_x86_langpack-rpm"
L10N_URI="http://download.documentfoundation.org/${LN}/testing/${LV3}"
RPM_LANG_URI="${L10N_URI}/rpm/x86/${L10N_RPM}"
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

RDEPEND="app-text/hunspell"

RESTRICT="mirror strip"

S="${WORKDIR}"

pkg_setup() {
	strip-linguas ${LANGUAGES}
}

src_unpack() {
	default

	local lang_path help_path
	for language in ${LINGUAS//_/-}; do
		# break away if not enabled (paludis support)
		use_if_iuse linguas_${language} || continue

		lang_path="${L10N_RPM}_${language}/RPMS/"
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
	local path="${S}/opt/${LN}${LV2}"

	# no lingua set or en without offlinehelp
	if [ -d "${path}" ] ; then
		insinto /usr/$(get_libdir)/${LN}
		doins -r "${path}"/*
	fi
}

