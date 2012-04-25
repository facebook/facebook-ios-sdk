#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# this script configures your iOS simulator for unit tests

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

if [ "$#" -ne 2 ]; then
      echo "Usage: $0 APP_ID APP_SECRET"
      die 'Arguments do not conform to usage'
fi

SIMULATOR_DIR=$HOME/Library/Application\ Support/iPhone\ Simulator

test -x "$SIMULATOR_DIR" || die 'Could not find simulator directory'

for VERSION_DIR in "${SIMULATOR_DIR}"/[45].*; do
      SIMULATOR_CONFIG_FILE="$VERSION_DIR/Documents/FBiOSSDK-UnitTestConfig.plist"

      # use heredoc syntax to output the plist
      cat > "$SIMULATOR_CONFIG_FILE" \
<<DELIMIT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>FacebookAppID</key>
	<string>$1</string>
	<key>FacebookAppSecret</key>
	<string>$2</string>
</dict>
</plist>
DELIMIT
# end heredoc

      echo "wrote unit test config file at $SIMULATOR_CONFIG_FILE"

done
