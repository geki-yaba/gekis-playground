#!/bin/bash

die()
{
	local exit_code=${?}

	echo "${1}"

	exit ${exit_code}
}

transcode_10to8_hardsubs()
{
	local p d f o s t

	p="$(realpath "${1}")"
	d="${p//10bit/8bit}"

	ls -1 "${p}"/*.mkv \
		|| die "no mkv files found in directory: ${p}"

	mkdir -p "${d}" \
		|| die "failed to create destination path: ${d}"

	mkdir -p "${d}/fonts" \
		|| die "failed to create destination fonts path: ${d}"

	for f in "${p}"/*.mkv
	do
		o="${f//10bit/8bit}"
		s="$(printf '%q' "${f}")"
		t="$(printf '%q' "${d}")"

		# shell window title
		echo -ne "\033]0;Transcode "$(basename "${f}")"\007"

		pushd "${d}/fonts" \
			|| die "failed to push into destination fonts path"
		ffmpeg -y -dump_attachment:t "" -i "${f}"
		popd \
			|| die "failed to pop out of destination fonts path"

		ffmpeg -i "${f}" \
			-c:a copy \
			-c:v libx264 -vf "subtitles=${s}:fontsdir=${t}/fonts,format=yuv420p" \
			-preset veryfast -tune animation -crf 23 -r 23.98 \
			-map 0:a -map 0:v \
			"${o}" \
			|| die "failed to transcode video from file: ${f}"
	done
}

if [ ! -d "${1}" ]
then
	die "parameter not a directory: ${1}"
fi

if [ ! -x "$(which ls)" ]
then
	die "ls binary not found"
fi

if [ ! -x "$(which realpath)" ]
then
	die "realpath binary not found"
fi

if [ ! -x "$(which ffmpeg)" ]
then
	die "ffmpeg binary not found"
fi

transcode_10to8_hardsubs "${1}"

exit ${?}
