#!/bin/bash
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

# Helper for the pngcrush-compression.sh script.

dir=$(dirname $0)

if [[ $# != 1 ]];then
  echo "Error: $0 requires a png file as an argument."
  exit 0
fi

# Skip files that have been pngcrushed by the apple
# pngcrush program since the generic pngcrush program
# will fail on them.
file "$1" | grep -q '0-bit grayscale' && {
    exit 0
}

$dir/pngcheck -t "$1" | grep -q pngcrush && {
    exit 0
}

# pngcrush version 1.7.22 added the overwrite (ow) option so we
# don't need to create a temp copy and move it.

$dir/pngcrush -q -text b "Software" "pngcrush" -brute -rem alla "$1" "${1}_tmp"

# pngcrush always exits 0 (idiots) so check for the existence for
# the outfile.
if [ -f "${1}_tmp" ];then
  xcrun --sdk iphoneos pngcrush -q -iphone "${1}_tmp" "$1"
  rm -rf "${1}_tmp"
fi
