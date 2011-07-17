# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit libreoffice

# keywords
KEYWORDS="~amd64 ~ppc ~ppc64 ~sparc ~x86"

# root
S="${WORKDIR}/${PN}-bootstrap-${PV}"

# config
CONFFILE="3.4.1"

# addons
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/48a9f787f43a09c0a9b7b00cd1fddbbf-hyphen-2.7.1.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/09357cc74975b01714e00c5899ea1881-pixman-0.12.0.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/128cfc86ed5953e57fe0f5ae98b62c2e-libtextcat-2.2.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/17410483b5b5f267aa18b7e00b65e6e0-hsqldb_1_8_0.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/1756c4fa6c616ae15973c104cd8cb256-Adobe-Core35_AFMs-314.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/18f577b374d60b3c760a3a3350407632-STLport-4.5.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/1f24ab1d39f4a51faf22244c94a6203f-xmlsec1-1.2.14.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/24be19595acad0a2cae931af77a0148a-LICENSE_source-9.0.0.7-bj.html"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/26b3e95ddf3d9c077c480ea45874b3b8-lp_solve_5.5.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/284e768eeda0e2898b0d5bf7e26a016e-raptor-1.4.18.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/2a177023f9ea8ec8bd00837605c5df1b-jakarta-tomcat-5.0.30-src.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/ca4870d899fd7e943ffc310a5421ad4d-liberation-fonts-ttf-1.06.0.20100721.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/35c94d2df8893241173de1d16b6034c0-swingExSrc.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/35efabc239af896dfb79be7ebdd6e6b9-gentiumbasic-fonts-1.10.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/39bb3fcea1514f1369fcfc87542390fd-sacjava-1.3.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/3ade8cfe7e59ca8e65052644fed9fca4-epm-3.7.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/48470d662650c3c074e1c3fabbc67bbd-README_source-9.0.0.7-bj.txt"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/4a660ce8466c9df01f19036435425c3a-glibc-2.1.3-stub.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/599dc4cc65a07ee868cf92a667a913d2-xpdf-3.02.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/7376930b0d3f3d77a685d94c4a3acda8-STLport-4.5-0119.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/798b2ffdc8bcfe7bca2cf92b62caf685-rhino1_5R5.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/8294d6c42e3553229af9934c5c0ed997-stax-api-1.0-2-sources.jar"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/a7983f859eafb2677d7ff386a023bc40-xsltml_2.1.2.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/ada24d37d8d638b3d8a9985e80bc2978-source-9.0.0.7-bj.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/c441926f3a552ed3e5b274b62e86af16-STLport-4.0.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/d4c4d91ab3a8e52a2e69d48d34ef4df4-core.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/e0707ff896045731ff99e99799606441-README_db-4.7.25.NC-custom.txt"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/fca8706f2c4619e2fa3f8f42f8fc1e9d-rasqal-0.9.16.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/fdb27bfe2dbe2e7b57ae194d9bf36bab-SampleICC-1.3.2.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/37282537d0ed1a087b1c8f050dc812d9-dejavu-fonts-ttf-2.32.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/067201ea8b126597670b5eff72e1f66c-mythes-1.2.0.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/3404ab6b1792ae5f16bbd603bd1e1d03-libformula-1.1.7.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/3bdf40c0d199af31923e900d082ca2dd-libfonts-1.1.6.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/8ce2fcd72becf06c41f7201d15373ed9-librepository-1.1.6.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/97b2d4dba862397f446b217e2b623e71-libloader-1.1.6.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/d8bd5eed178db6e2b18eeed243f85aa8-flute-1.1.6.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/db60e4fde8dd6d6807523deb71ee34dc-liblayout-0.2.10.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/eeb2c7ddf0d302fba4bfc6e97eac9624-libbase-1.1.6.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/f94d9870737518e3b597f9265f4e9803-libserializer-1.1.6.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/ba2930200c9f019c2d93a8c88c651a0f-flow-engine-0.9.4.zip"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/451ccf439a36a568653b024534669971-ConvertTextToNumber-1.3.2.oxt"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/47e1edaa44269bc537ae8cabebb0f638-JLanguageTool-1.0.0.tar.bz2"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/90401bca927835b6fbae4a707ed187c8-nlpsolver-0.9.tar.bz2"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/0f63ee487fda8f21fafa767b3c447ac9-ixion-0.2.0.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/71474203939fafbe271e1263e61d083e-nss-3.12.8-with-nspr-4.8.6.tar.gz"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/7a0dcb3fe1e8c7229ab4fb868b7325e6-mdds_0.5.2.tar.bz2"
ADDONS_SRC+=" http://dev-www.libreoffice.org/src/0625a7d661f899a8ce263fc8a9879108-graphite2-0.9.2.tgz"
ADDONS_SRC+=" http://download.go-oo.org/extern/185d60944ea767075d27247c3162b3bc-unowinreg.dll"
ADDONS_SRC+=" http://download.go-oo.org/extern/b4cae0700aa1c2aef7eb7f345365e6f1-translate-toolkit-1.8.1.tar.bz2"
ADDONS_SRC+=" http://www.numbertext.org/linux/881af2b7dca9b8259abbca00bbbc004d-LinLibertineG-20110101.zip"
SRC_URI+=" ${ADDONS_SRC}"