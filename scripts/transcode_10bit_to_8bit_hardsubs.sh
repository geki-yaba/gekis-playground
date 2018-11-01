#!/bin/sh

die()
{
	local exit_code=${?}

	echo "${1}"

	exit ${exit_code}
}

create_destination_paths()
{
	local p d

	p="$(realpath "${1}")"
	d="${p//10bit/8bit}"

	mkdir -p "${d}" \
		|| die "failed to create destination path: ${o}"

	for f in "${p}"/*.mkv
	do
		d="${f//10bit/8bit}"
		d="${d/mkv/tmp}"

		mkdir -p "${d}" \
			|| die "failed to create temporary subtitle data path: ${d}"
	done
}

extract_subs()
{
	local p f d o

	p="$(realpath "${1}")"

	for f in "${p}"/*.mkv
	do
		d="${f//10bit/8bit}"
		d="${d/mkv/tmp}"

		o="${d}/subtitles.ass"

		ffmpeg -i "${f}" -map 0:s -c:s ass "${o}" \
			|| die "failed to extract subtitle from file: ${f}"
	done
}

extract_attachments()
{
	local p f d o

	p="$(realpath "${1}")"

	for f in "${p}"/*.mkv
	do
		d="${f//10bit/8bit}"
		d="${d/mkv/tmp}"

		o="${d}/subtitles.mkv"

		pushd "${d}" >/dev/null 2>&1 \
			|| die "failed to change to temporary subtitle data path: ${d}"

		ffmpeg -dump_attachment:t "" -i "${f}" \
			-map 0:s -map 0:t \
			-f matroska "${o}" \
			|| die "failed to extract subtitle fonts from file: ${f}"

		popd
	done
}

transcode_videos()
{
	local p f d o s

	p="$(realpath "${1}")"

	for f in "${p}"/*.mkv
	do
		d="${f//10bit/8bit}"
		d="$(printf '%q' "${d/mkv/tmp}")"

		o="${f//10bit/8bit}"
		s="$(printf '%q' "${d}/subtitles.ass")"

		ffmpeg -i "${f}" -map 0:v -map 0:a \
			-vf ass="${s}":fontsdir="${d}" \
			-c:v libx264 -preset veryfast -tune animation -crf 23 -r 23.976 \
			-c:a copy \
			-f matroska "${o}" \
			|| die "failed to transcode video from file: ${f}"
	done
}

if [ ! -d "${1}" ]
then
	die "parameter not a directory: ${1}"
fi

if [ ! -x "$(which realpath)" ]
then
	die "realpath binary not found"
fi

if [ ! -x "$(which ffmpeg)" ]
then
	die "ffmpeg binary not found"
fi

create_destination_paths "${1}"

extract_subs "${1}"

extract_attachments "${1}"

transcode_videos "${1}"

exit ${?}
