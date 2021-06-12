#!/bin/bash

set -o pipefail

die()
{
	echo "[${1}] ${2}"

	exit ${1}
}

transcode_10to8_hardsubs()
{
	local b p d t f o r c s

	local src_fmt="mkv"
	local dst_fmt="mp4"
	local dst_crc

	b="$(basename ${0})"
	p="$(realpath "${1}")"
	d="${p//10bit/8bit}"
	t="$(printf '%q' "${d}")"

	ls -1 "${p}"/*.${src_fmt} \
		>/dev/null 2>&1
	r=${?}; [ ${r} -eq 0 ] || die ${r} \
		"no ${src_fmt} files found in directory: ${p}"

	mkdir -p "${d}"
	r=${?}; [ ${r} -eq 0 ] || die ${r} \
		"failed to create destination path: ${d}"

	mkdir -p "${d}/fonts" 
	r=${?}; [ ${r} -eq 0 ] || die ${r} \
		"failed to create destination fonts path: ${d}"

	# ship script with batch to recreate
	cp -v "${0}" "${d}/${b}"

	# log transcode
	ffmpeg -version \
		| tee -a "${d}/${b}.log"
	echo "" | tee -a "${d}/${b}.log"
	ls -1 "${p}"/*.${src_fmt} \
		| tee -a "${d}/${b}.log"
	echo "" | tee -a "${d}/${b}.log"

	for f in "${p}"/*.${src_fmt}
	do
		o="${f//10bit/8bit}"
		o="${o//${src_fmt}/${dst_fmt}}"
		s="$(printf '%q' "${f}")"

		# shell window title
		echo -ne "\033]0;Transcode to "$(basename "${o}")"\007"

		pushd "${d}/fonts" >/dev/null
		r=${?}; [ ${r} -eq 0 ] || die ${r} \
			"failed to push into destination fonts path"

		AV_LOG_FORCE_NOCOLOR=1 \
		ffmpeg -loglevel quiet \
			-y -dump_attachment:t "" \
			-i "${f}" \
			2>>"${d}/${b}.log"
		# error if no output file given,
		# we extract multiple output files indeed
		r=${?}; [ ${r} -eq 1 ] || die ${r} \
			"failed to extract fonts from file: ${f}"

		popd >/dev/null
		r=${?}; [ ${r} -eq 0 ] || die ${r} \
			"failed to pop out of destination fonts path"

		ffprobe "${f}" 2>&1 \
			| grep ": Video" \
			| tee -a "${d}/${b}.log"
		r=${?}; [ ${r} -eq 0 ] || die ${r} \
			"failed to probe video from file: ${f}"
		echo "" | tee -a "${d}/${b}.log"

		AV_LOG_FORCE_NOCOLOR=1 \
		ffmpeg -loglevel level+error \
			-stats -i "${f}" -c:a copy -c:v libx264 \
			-vf "subtitles=${s}:fontsdir=${t}/fonts,format=yuv420p" \
			-preset veryfast -tune animation -crf 23 \
			-vsync passthrough -map 0:a -map 0:v "${o}" 2>&1 \
			| tee >(grep -v -E "\r$" >> "${d}/${b}.log")
			# '-r 23.98' replaced by '-vsync passthrough'
		r=${?}; [ ${r} -eq 0 ] || die ${r} \
			"failed to transcode video from file: ${f}"

		# crc32 8-digit
		dst_crc="$(crc32 "${o}" | cut -f1 | tr '[a-z]' '[A-Z]')"
		c="${o:0:-14}[${dst_crc}].${dst_fmt}"

		echo "i: ${f}" \
			| tee -a "${d}/${b}.log"
		echo "o: ${c}" \
			| tee -a "${d}/${b}.log"

		mv "${o}" "${c}"
		r=${?}; [ ${r} -eq 0 ] || die ${r} \
			"failed to update crc32 verification of file: ${o}"
	done
}

validate_helper_commands()
{
	local cmd

	for cmd in basename crc32 cut grep ffmpeg \
		ffprobe ls mkdir realpath tee tr
	do
		if [ ! -x "$(which ${cmd})" ]
		then
			die 2 "${cmd} binary not found"
		fi
	done
}

if [ ! -d "${1}" ]
then
	die 1 "parameter not a directory: ${1}"
fi

validate_helper_commands
transcode_10to8_hardsubs "${1}"

exit 0
