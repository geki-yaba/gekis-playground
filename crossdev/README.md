# Gentoo crossdev targeting MinGW-w64 - geki flavoured
Read the links referenced in *Resources* section below before continueing.

## Resources
* https://wiki.gentoo.org/wiki/Crossdev
* https://wiki.gentoo.org/wiki/Custom_ebuild_repository#Crossdev
* https://wiki.gentoo.org/wiki/Mingw

# Handy commands to get going quickly. Or not..? *e he he*
Here you find files generated by crossdev, recommended by wiki and tweaks by me. Read the files and get some basic understand of `CHOST` and `CBUILD` and what configuration files belong to which environment.

# Setup target
Bootstrapping out-of-the-box just failed happily here. Therefore, initialize environment first and adjust some configuration files for a better first-time experience.
```
$ crossdev --help|grep init-target
    --init-target            Setup config/overlay/etc... files only
```

## Upgrade setup of target
Check the files and adjust. Take care about the package.use files for cross-compiling. To bootstrap, copy corresponding package.use file.
```
$ cp -a /etc/portage/package.use/cross-x86_64-w64-mingw32.bootstrap~ /etc/portage/package.use/cross-x86_64-w64-mingw32
```

# Whenever you cross-compile, edit `CBUILD` make.conf
Feel free to skip and you be "vogelfrei".
```
# WHEN CROSS-COMPILING, DISABLE SPECIFIC CPU ARCH
# OTHERWISE YOU SEE FUNNY ERRORS, ICE'S OR MISCOMPILED FOO

$ grep CFLAGS etc/portage/make.conf 
CFLAGS="-O2 -march=x86-64 -mtune=generic -pipe -fomit-frame-pointer -funswitch-loops"
```
In case you have built CBUILD packages with generic CFLAGS, rebuild them with non-generic CFLAGS like so:
```
$ pushd /var/db/pkg
$ rm /tmp/rebuild_cflags

$ for pkg in $(grep -l "x86-64" */*/CFLAGS | grep -v cross)
$ do
$   echo "=${pkg%/*}" >> /tmp/rebuild_cflags
$ done

$ sed -e ':a;N;$!ba;s/\n/ /g' -i /tmp/rebuild_cflags
$ emerge --oneshot $(</tmp/rebuild_cflags)

$ rm /tmp/rebuild_cflags
$ popd
```

# Bootstrap cross-toolchain, no cxx
```
$ crossdev --target x86_64-w64-mingw32
```

# POSIX threads support
```
# Rebuild mingw64-runtime
$ USE="libraries idl tools" crossdev --ex-only --ex-pkg cross-x86_64-w64-mingw32/mingw64-runtime --target x86_64-w64-mingw32
```
Now, the package.use file `/etc/portage/package.use/cross-x86_64-w64-mingw32` is broken. Recover the file.
```
$ cp -a /etc/portage/package.use/cross-x86_64-w64-mingw32.bootstrap~ /etc/portage/package.use/cross-x86_64-w64-mingw32
```

## Rebuild gcc, then mingw64-runtime with winpthreads
```
# Rebuild gcc
$ EXTRA_ECONF="--enable-threads=posix" emerge --oneshot cross-x86_64-w64-mingw32/gcc

# Double-check useflags of mingw64-runtime
$ USE="libraries idl tools" emerge -v --oneshot cross-x86_64-w64-mingw32/mingw64-runtime

# Recover package.use file again
$ cp -a /etc/portage/package.use/cross-x86_64-w64-mingw32.bootstrap~ /etc/portage/package.use/cross-x86_64-w64-mingw32

# Verify that the compiler has the posix thread model
$ x86_64-w64-mingw32-gcc -v
[..] Thread model: posix 
```

# Rebuild gcc with cxx and ssp
```
# Update package.use file for cross-development
$ cp -a /etc/portage/package.use/cross-x86_64-w64-mingw32.crossdev~ /etc/portage/package.use/cross-x86_64-w64-mingw32

# Rebuild gcc
$ EXTRA_ECONF="--enable-threads=posix" emerge --oneshot cross-x86_64-w64-mingw32/gcc
```

# Heavy patching, happy matching
* See *patches* directory for my fixups.
* See *package.env* and corresponding configuration files for easy tweaks.

# Optional: Enable secure API
```
# CHOST make.conf
CPPFLAGS="${CPPFLAGS} -DMINGW_HAS_SECURE_API"
```
See https://bugs.gentoo.org/665512#c15.

# Remove crossdev target
```
$ crossdev -C x86_64-w64-mingw32

# Check stray directories and files
$ find / -type d -name '*w64*'
```

# Help me, help you
If you see anything to improve, please let me know. You help others get going quickly!
