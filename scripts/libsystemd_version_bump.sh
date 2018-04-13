#!/bin/sh

do_diff()
{
	local dest file www="/var/www/geki/htdocs/hacks"

	for file in meson.build src/systemd/meson.build src/libsystemd/meson.build src/libsystemd/libsystemd.sym
	do
		dest="${www}/libsystemd_${1}_${2}-${file}.patch"

		git diff ${1}..${2} ${file} >> ${dest}

		chmod 640 ${dest}
		chown root:apache ${dest}
	done
}

if [ "$(pwd)" != "/usr/local/src/systemd" ]
then
	echo "boo"
	exit 1
fi

if [ "${1}" != "" -a "${2}" != "" ]
then
	git pull -r || exit 1

	do_diff "${1}" "${2}"
fi

exit 0
