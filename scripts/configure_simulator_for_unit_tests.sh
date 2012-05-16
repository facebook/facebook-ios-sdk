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

function write_plist {
      SIMULATOR_CONFIG_DIR="$1"/Documents
      SIMULATOR_CONFIG_FILE="$SIMULATOR_CONFIG_DIR"/FBiOSSDK-UnitTestConfig.plist

      if [ ! -d "$SIMULATOR_CONFIG_DIR" ]; then
            mkdir "$SIMULATOR_CONFIG_DIR"
      fi

      # use heredoc syntax to output the plist
      cat > "$SIMULATOR_CONFIG_FILE" \
<<DELIMIT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>FacebookAppID</key>
        <string>$2</string>
        <key>FacebookAppSecret</key>
        <string>$3</string>
</dict>
</plist>
DELIMIT
# end heredoc

      echo "wrote unit test config file at $SIMULATOR_CONFIG_FILE" 
}

SIMULATOR_DIR=$HOME/Library/Application\ Support/iPhone\ Simulator

test -x "$SIMULATOR_DIR" || die 'Could not find simulator directory'

write_plist "$SIMULATOR_DIR" $1 $2

for VERSION_DIR in "${SIMULATOR_DIR}"/[45].*; do
      write_plist "$VERSION_DIR" $1 $2
done
