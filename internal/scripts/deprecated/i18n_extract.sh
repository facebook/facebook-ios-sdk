#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

. ${FB_SDK_INTERNAL_SCRIPT:-$(dirname $0)}/common.sh

usage() {
  cat <<EOF
Usage: $0 -k keys

Extracts the specified keys from the strings files.

OPTIONS:
    -k  Keys to extract.
EOF
}

while getopts "hk:" OPTION; do
  case $OPTION in
  h)
    usage
    exit 0
    ;;
  k)
    KEYS="$OPTARG"
    ;;
  [?])
    usage
    exit 1
    ;;
  esac
done

if [ -z "$KEYS" ]; then
  fb_internal_warning "No keys specified."
  usage
  exit 1
fi

extract() {
  LOCALE_DIR=$1
  ${FB_SDK_INTERNAL_SCRIPT:-$(dirname $0)}/i18n_extract_ios.py -k "$KEYS" -i "$FB_SDK_ROOT"/AccountKit/AccountKitStrings.bundle/Resources/$LOCALE_DIR/AccountKit.strings -o "$FB_SDK_ROOT"/AccountKit/AccountKitAdditionalStrings.bundle/Resources/$LOCALE_DIR/AccountKit.strings
}

fb_internal_title "Extracting AccountKit strings for $KEYS..."

for LOCALE_DIR in $(ls -d1 "$FB_SDK_ROOT"/AccountKit/AccountKitStrings.bundle/Resources/*.lproj | awk -F / '{print $NF}'); do
  extract $LOCALE_DIR
done

# Done
common_success
