# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit libreoffice

# keywords
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86 ~amd64-linux ~x86-linux"

# root
S="${WORKDIR}/core"

# config
CONFFILE="3.5"
EGIT_BRANCH="libreoffice-3-5"

# addons
ADDONS_URI="http://dev-www.libreoffice.org/src/"
ADDONS_SRC+=" ${ADDONS_URI}/17410483b5b5f267aa18b7e00b65e6e0-hsqldb_1_8_0.zip"
ADDONS_SRC+=" ${ADDONS_URI}/1f24ab1d39f4a51faf22244c94a6203f-xmlsec1-1.2.14.tar.gz"
ADDONS_SRC+=" ${ADDONS_URI}/2a177023f9ea8ec8bd00837605c5df1b-jakarta-tomcat-5.0.30-src.tar.gz"
ADDONS_SRC+=" ${ADDONS_URI}/35c94d2df8893241173de1d16b6034c0-swingExSrc.zip"
ADDONS_SRC+=" ${ADDONS_URI}/39bb3fcea1514f1369fcfc87542390fd-sacjava-1.3.zip"
ADDONS_SRC+=" ${ADDONS_URI}/4a660ce8466c9df01f19036435425c3a-glibc-2.1.3-stub.tar.gz"
ADDONS_SRC+=" ${ADDONS_URI}/798b2ffdc8bcfe7bca2cf92b62caf685-rhino1_5R5.zip"
ADDONS_SRC+=" ${ADDONS_URI}/a7983f859eafb2677d7ff386a023bc40-xsltml_2.1.2.zip"
ADDONS_SRC+=" ${ADDONS_URI}/ada24d37d8d638b3d8a9985e80bc2978-source-9.0.0.7-bj.zip"
ADDONS_SRC+=" ${ADDONS_URI}/d4c4d91ab3a8e52a2e69d48d34ef4df4-core.zip"
ADDONS_SRC+=" ${ADDONS_URI}/fdb27bfe2dbe2e7b57ae194d9bf36bab-SampleICC-1.3.2.tar.gz"
ADDONS_SRC+=" ${ADDONS_URI}/3404ab6b1792ae5f16bbd603bd1e1d03-libformula-1.1.7.zip"
ADDONS_SRC+=" ${ADDONS_URI}/3bdf40c0d199af31923e900d082ca2dd-libfonts-1.1.6.zip"
ADDONS_SRC+=" ${ADDONS_URI}/8ce2fcd72becf06c41f7201d15373ed9-librepository-1.1.6.zip"
ADDONS_SRC+=" ${ADDONS_URI}/97b2d4dba862397f446b217e2b623e71-libloader-1.1.6.zip"
ADDONS_SRC+=" ${ADDONS_URI}/ace6ab49184e329db254e454a010f56d-libxml-1.1.7.zip"
ADDONS_SRC+=" ${ADDONS_URI}/d8bd5eed178db6e2b18eeed243f85aa8-flute-1.1.6.zip"
ADDONS_SRC+=" ${ADDONS_URI}/db60e4fde8dd6d6807523deb71ee34dc-liblayout-0.2.10.zip"
ADDONS_SRC+=" ${ADDONS_URI}/eeb2c7ddf0d302fba4bfc6e97eac9624-libbase-1.1.6.zip"
ADDONS_SRC+=" ${ADDONS_URI}/f94d9870737518e3b597f9265f4e9803-libserializer-1.1.6.zip"
ADDONS_SRC+=" ${ADDONS_URI}/ba2930200c9f019c2d93a8c88c651a0f-flow-engine-0.9.4.zip"
ADDONS_SRC+=" ${ADDONS_URI}/451ccf439a36a568653b024534669971-ConvertTextToNumber-1.3.2.oxt"
ADDONS_SRC+=" ${ADDONS_URI}/b99fb620b1324b4ce79ee6998b507146-JLanguageTool-1.4.0.tar.bz2"
ADDONS_SRC+=" ${ADDONS_URI}/0f63ee487fda8f21fafa767b3c447ac9-ixion-0.2.0.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/extern/185d60944ea767075d27247c3162b3bc-unowinreg.dll"
SRC_URI+=" ${ADDONS_SRC}"
