#/bin/bash

infile=$1

if [[ -r $infile ]]; then
  ffmpeg -i "$infile" -acodec mp3 -ac 2 -ab 192k "${infile%.*}.mp3"
else
  >&2 echo "Could not find $infile"
fi

