#!/bin/sh

die()
{
	local exit_code=${?}

	echo "${1}"

	exit ${exit_code}
}

transcode_videos()
{
	local p d f o s

	p="$(realpath "${1}")"
	d="${p//10bit/8bit}"

	ls -1 "${p}"/*.mkv \
		|| die "no mkv files found in directory: ${p}"

	mkdir -p "${d}" \
		|| die "failed to create destination path: ${o}"

	for f in "${p}"/*.mkv
	do
		o="${f//10bit/8bit}"
		s="$(printf '%q' "${f}")"

		ffmpeg -i "${f}" -map 0:v -map 0:a -vf subtitles="${s}" \
			-c:v libx264 -preset veryfast -tune animation -crf 23 -r 23.976 \
			-c:a copy -f matroska "${o}" \
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

transcode_videos "${1}"

exit ${?}
