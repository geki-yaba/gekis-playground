# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit libreoffice

# keywords
KEYWORDS=""

# root
S="${WORKDIR}/${PN}"

# root
S="${WORKDIR}/${PN}/bootstrap"

# git clone
CLONE_DIR="${S}/clone"
EGIT_BRANCH="master"

# addons
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/09357cc74975b01714e00c5899ea1881-pixman-0.12.0.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/128cfc86ed5953e57fe0f5ae98b62c2e-libtextcat-2.2.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/17410483b5b5f267aa18b7e00b65e6e0-hsqldb_1_8_0.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/1756c4fa6c616ae15973c104cd8cb256-Adobe-Core35_AFMs-314.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/18f577b374d60b3c760a3a3350407632-STLport-4.5.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/1f24ab1d39f4a51faf22244c94a6203f-xmlsec1-1.2.14.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/24be19595acad0a2cae931af77a0148a-LICENSE_source-9.0.0.7-bj.html"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/26b3e95ddf3d9c077c480ea45874b3b8-lp_solve_5.5.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/284e768eeda0e2898b0d5bf7e26a016e-raptor-1.4.18.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/2a177023f9ea8ec8bd00837605c5df1b-jakarta-tomcat-5.0.30-src.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/ca4870d899fd7e943ffc310a5421ad4d-liberation-fonts-ttf-1.06.0.20100721.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/35c94d2df8893241173de1d16b6034c0-swingExSrc.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/35efabc239af896dfb79be7ebdd6e6b9-gentiumbasic-fonts-1.10.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/377a60170e5185eb63d3ed2fae98e621-README_silgraphite-2.3.1.txt"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/39bb3fcea1514f1369fcfc87542390fd-sacjava-1.3.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/3ade8cfe7e59ca8e65052644fed9fca4-epm-3.7.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/48470d662650c3c074e1c3fabbc67bbd-README_source-9.0.0.7-bj.txt"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/4a660ce8466c9df01f19036435425c3a-glibc-2.1.3-stub.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/599dc4cc65a07ee868cf92a667a913d2-xpdf-3.02.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/5aba06ede2daa9f2c11892fbd7bc3057-libserializer.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/7376930b0d3f3d77a685d94c4a3acda8-STLport-4.5-0119.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/79600e696a98ff95c2eba976f7a8dfbb-liblayout.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/798b2ffdc8bcfe7bca2cf92b62caf685-rhino1_5R5.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/8294d6c42e3553229af9934c5c0ed997-stax-api-1.0-2-sources.jar"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/8ea307d71d11140574bfb9fcc2487e33-libbase.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/a06a496d7a43cbdc35e69dbe678efadb-libloader.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/a4d9b30810a434a3ed39fc0003bbd637-LICENSE_stax-api-1.0-2-sources.html"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/a7983f859eafb2677d7ff386a023bc40-xsltml_2.1.2.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/ada24d37d8d638b3d8a9985e80bc2978-source-9.0.0.7-bj.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/bc702168a2af16869201dbe91e46ae48-LICENSE_Python-2.6.1"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/c441926f3a552ed3e5b274b62e86af16-STLport-4.0.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/d0b5af6e408b8d2958f3d83b5244f5e8-hyphen-2.4.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/d1a3205871c3c52e8a50c9f18510ae12-libformula.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/d4c4d91ab3a8e52a2e69d48d34ef4df4-core.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/dbb3757275dc5cc80820c0b4dd24ed95-librepository.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/e0707ff896045731ff99e99799606441-README_db-4.7.25.NC-custom.txt"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/f3e2febd267c8e4b13df00dac211dd6d-flute.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/f7925ba8491fe570e5164d2c72791358-libfonts.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/fb7ba5c2182be4e73748859967455455-README_stax-api-1.0-2-sources.txt"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/fca8706f2c4619e2fa3f8f42f8fc1e9d-rasqal-0.9.16.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/fdb27bfe2dbe2e7b57ae194d9bf36bab-SampleICC-1.3.2.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/37282537d0ed1a087b1c8f050dc812d9-dejavu-fonts-ttf-2.32.zip"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/067201ea8b126597670b5eff72e1f66c-mythes-1.2.0.tar.gz"
ADDONS_SRC+=" http://hg.services.openoffice.org/binaries/cf8a6967f7de535ae257fa411c98eb88-mdds_0.3.0.tar.bz2"
ADDONS_SRC+=" http://download.go-oo.org/src/47e1edaa44269bc537ae8cabebb0f638-JLanguageTool-1.0.0.tar.bz2"
ADDONS_SRC+=" http://download.go-oo.org/src/90401bca927835b6fbae4a707ed187c8-nlpsolver-0.9.tar.bz2"
ADDONS_SRC+=" http://download.go-oo.org/src/0f63ee487fda8f21fafa767b3c447ac9-ixion-0.2.0.tar.gz"
ADDONS_SRC+=" http://download.go-oo.org/src/71474203939fafbe271e1263e61d083e-nss-3.12.8-with-nspr-4.8.6.tar.gz"
ADDONS_SRC+=" http://download.go-oo.org/extern/185d60944ea767075d27247c3162b3bc-unowinreg.dll"
ADDONS_SRC+=" http://www.numbertext.org/linux/881af2b7dca9b8259abbca00bbbc004d-LinLibertineG-20110101.zip"
SRC_URI+=" ${ADDONS_SRC}"
