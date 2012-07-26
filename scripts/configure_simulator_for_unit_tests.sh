#!/bin/sh
#
# Copyright 2012 Facebook
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# this script configures your iOS simulator for unit tests
# Note: On Mac OS X, an easy way to generate a MACHINE_UNIQUE_USER_TAG is with the following:
#   system_profiler SPHardwareDataType | grep -i "Serial Number (system):" | awk '{print $4}'

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

if [ "$#" -lt 2 ]; then
      echo "Usage: $0 APP_ID APP_SECRET [MACHINE_UNIQUE_USER_KEY]"
      echo "  APP_ID                   your unit-testing Facebook application's App ID"
      echo "  APP_SECRET               your unit-testing Facebook application's App Secret"
      echo "  MACHINE_UNIQUE_USER_TAG  optional text used to ensure this machine will use its own set of test users rather than sharing"
      die 'Arguments do not conform to usage'
fi

function write_plist {
      SIMULATOR_CONFIG_DIR="$1"/Documents
      SIMULATOR_CONFIG_FILE="$SIMULATOR_CONFIG_DIR"/FacebookSDK-UnitTestConfig.plist

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
        <key>UniqueUserTag</key>
        <string>$4</string>
</dict>
</plist>
DELIMIT
# end heredoc

      echo "wrote unit test config file at $SIMULATOR_CONFIG_FILE" 
}

SIMULATOR_DIR=$HOME/Library/Application\ Support/iPhone\ Simulator

test -x "$SIMULATOR_DIR" || die 'Could not find simulator directory'

write_plist "$SIMULATOR_DIR" $1 $2 $3

for VERSION_DIR in "${SIMULATOR_DIR}"/[45].*; do
      write_plist "$VERSION_DIR" $1 $2 $3
done
