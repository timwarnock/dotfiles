#!/bin/bash

if [ -e "$1" ]; then
  output=`basename $1 .pdf`
  ebook-convert "$1" "$output.epub" --enable-heuristics
else
  echo "must provide a file to convert"
fi
