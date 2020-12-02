diff --git a/media-libs/fontconfig/fontconfig-2.13.1-r2.ebuild b/media-libs/fontconfig/fontconfig-2.13.1-r2.ebuild
index 70a15b893a0f..2d8426561d42 100644
--- a/media-libs/fontconfig/fontconfig-2.13.1-r2.ebuild
+++ b/media-libs/fontconfig/fontconfig-2.13.1-r2.ebuild
@@ -36,7 +36,7 @@ BDEPEND="dev-util/gperf
 # default and used by every distro.  See bug #283191.
 RDEPEND=">=dev-libs/expat-2.1.0-r3[${MULTILIB_USEDEP}]
 	>=media-libs/freetype-2.9[${MULTILIB_USEDEP}]
-	!elibc_Darwin? ( !elibc_SunOS? ( sys-apps/util-linux[${MULTILIB_USEDEP}] ) )
+	!elibc_Darwin? ( !elibc_SunOS? ( !elibc_mingw? ( sys-apps/util-linux[${MULTILIB_USEDEP}] ) ) )
 	elibc_Darwin? ( sys-libs/native-uuid )
 	elibc_SunOS? ( sys-libs/libuuid )
 	virtual/libintl[${MULTILIB_USEDEP}]"
@@ -54,7 +54,7 @@ PATCHES=(
 	"${FILESDIR}"/${P}-proper_homedir.patch
 )
 
-MULTILIB_CHOST_TOOLS=( /usr/bin/fc-cache$(get_exeext) )
+#MULTILIB_CHOST_TOOLS=( /usr/bin/fc-cache$(get_exeext) )
 
 pkg_setup() {
 	DOC_CONTENTS="Please make fontconfig configuration changes using
@@ -91,7 +91,7 @@ multilib_src_configure() {
 	local myeconfargs=(
 		$(use_enable doc docbook)
 		$(use_enable static-libs static)
-		--enable-docs
+		$(use_enable !elibc_mingw docs)
 		--localstatedir="${EPREFIX}"/var
 		--with-default-fonts="${EPREFIX}"/usr/share/fonts
 		--with-add-fonts="${EPREFIX}/usr/local/share/fonts${addfonts}"
@@ -105,7 +105,7 @@ multilib_src_install() {
 	default
 
 	# avoid calling this multiple times, bug #459210
-	if multilib_is_native_abi; then
+	if multilib_is_native_abi && ! use elibc_mingw; then
 		# stuff installed from build-dir
 		emake -C doc DESTDIR="${D}" install-man
 
@@ -115,6 +115,8 @@ multilib_src_install() {
 }
 
 multilib_src_install_all() {
+	use elibc_mingw && return;
+
 	einstalldocs
 	find "${ED}" -name "*.la" -delete || die
 
@@ -168,6 +170,7 @@ pkg_postinst() {
 	einfo "Cleaning broken symlinks in ${EROOT}/etc/fonts/conf.d/"
 	find -L "${EROOT}"/etc/fonts/conf.d/ -type l -delete
 
+	use elibc_mingw && return;
 	readme.gentoo_print_elog
 
 	if [[ ${ROOT} == "" ]]; then
