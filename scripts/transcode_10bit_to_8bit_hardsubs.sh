#!/bin/bash

die()
{
	local exit_code=${?}

	echo "${1}"

	exit ${exit_code}
}

transcode_10to8_hardsubs()
{
	local b p d t f o c s

	local src_fmt="mkv"
	local dst_fmt="mp4"
	local dst_crc

	b="$(basename ${0})"
	p="$(realpath "${1}")"
	d="${p//10bit/8bit}"
	t="$(printf '%q' "${d}")"

	ls -1 "${p}"/*.${src_fmt} \
		|| die "no ${src_fmt} files found in directory: ${p}"

	mkdir -p "${d}" \
		|| die "failed to create destination path: ${d}"

	mkdir -p "${d}/fonts" \
		|| die "failed to create destination fonts path: ${d}"

	# ship script with batch to recreate
	cp -v "${0}" "${d}/${b}"

	# log transcode
	ffmpeg -version >"${d}/${b}.log"
	echo "" >"${d}/${b}.log"
	ls -1 "${p}"/*.${src_fmt} \
		>"${d}/${b}.log"
	echo "" >"${d}/${b}.log"

	for f in "${p}"/*.${src_fmt}
	do
		o="${f//10bit/8bit}"
		o="${o//${src_fmt}/${dst_fmt}}"
		s="$(printf '%q' "${f}")"

		# shell window title
		echo -ne "\033]0;Transcode to "$(basename "${o}")"\007"

		pushd "${d}/fonts" >/dev/null \
			|| die "failed to push into destination fonts path"
		AV_LOG_FORCE_NOCOLOR=1 \
		ffmpeg -loglevel quiet \
			-y -dump_attachment:t "" \
			-i "${f}" \
			2>"${d}/${b}.log"
		popd >/dev/null \
			|| die "failed to pop out of destination fonts path"

		AV_LOG_FORCE_NOCOLOR=1 \
		ffmpeg -loglevel level+warning \
			-stats \
			-i "${f}" \
			-c:a copy \
			-c:v libx264 \
			-vf "subtitles=${s}:fontsdir=${t}/fonts,format=yuv420p" \
			-preset veryfast -tune animation -crf 23 -r 23.98 \
			-map 0:a -map 0:v \
			"${o}" \
			2>"${d}/${b}.log" \
			|| die "failed to transcode video from file: ${f}"

		# crc32 8-digit
		dst_crc="$(crc32 "${o}" | cut -f1 | tr '[a-z]' '[A-Z]')"
		c="${o:0:-14}[${dst_crc}].${dst_fmt}"

		echo "i: ${f}" \
			| tee -a "${d}/${b}.log"
		echo "o: ${c}" \
			| tee -a "${d}/${b}.log"

		mv "${o}" "${c}" \
			|| die "failed to update crc32 verification of file: ${o}"
	done
}

validate_helper_commands()
{
	local cmd

	for cmd in basename crc32 cut ffmpeg ls mkdir realpath tee tr
	do
		if [ ! -x "$(which ${cmd})" ]
		then
			die "${cmd} binary not found"
		fi
	done
}

if [ ! -d "${1}" ]
then
	die "parameter not a directory: ${1}"
fi

validate_helper_commands
transcode_10to8_hardsubs "${1}"

exit ${?}
