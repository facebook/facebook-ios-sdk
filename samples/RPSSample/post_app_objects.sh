#!/bin/sh
#
# Copyright (c) Facebook, Inc. and its affiliates. All rights reserved.
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
# copy, modify, and distribute this software in source code or binary form for use
# in connection with the web services and APIs provided by Facebook.
#
# As with any software that integrates with the Facebook platform, your use of
# this software is subject to the Facebook Platform Policy
# [http://developers.facebook.com/policy/]. This copyright notice shall be
# included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Note: Use of this script requires Perl

# @lint-ignore-every LICENSELINT

#
# step 1 - confirm we have an app id and app secret to work with
#

if [ -z "$APPID" ]
then
  echo '$APPID must be exported and set to the application id for the sample before running this script'
  exit 1
fi

if [ -z "$APPSECRET" ]
then
  echo '$APPSECRET must be exported set to the app secret for the sample before running this script'
  exit 1
fi

#
# step 2 - stage images and capture their URIs in variables
#

echo curling...

ROCK_IMAGE_URI=` \
  curl -s -k -X POST https://graph.facebook.com/$APPID/staging_resources -F access_token="$APPID|$APPSECRET" -F 'file=@RPSSample/left-rock-128.png;type=image/png' \
  | perl -ne '/"uri":"(.*)"}/ && print $1' `

PAPER_IMAGE_URI=` \
  curl -s -k -X POST https://graph.facebook.com/$APPID/staging_resources -F access_token="$APPID|$APPSECRET" -F 'file=@RPSSample/left-paper-128.png;type=image/png' \
  | perl -ne '/"uri":"(.*)"}/ && print $1' `

SCISSORS_IMAGE_URI=` \
  curl -s -k -X POST https://graph.facebook.com/$APPID/staging_resources -F access_token="$APPID|$APPSECRET" -F 'file=@RPSSample/left-scissors-128.png;type=image/png' \
  | perl -ne '/"uri":"(.*)"}/ && print $1' `

echo "created staged resources..."
echo "  rock=$ROCK_IMAGE_URI"
echo "  paper=$PAPER_IMAGE_URI"
echo "  scissors=$SCISSORS_IMAGE_URI"

# step 3 - create facebook host applink page for the app:
# For mobile only app, facebook provide applink host service to generate a page: https://developers.facebook.com/docs/graph-api/reference/v2.0/app/app_link_hosts

echo "creating facebook host applink page for mobile-only app:"

FB_APPLINK_HOST_ID=` \
curl https://graph.facebook.com/app/app_link_hosts -F access_token="$APPID|$APPSECRET" -F pretty=true -F name="RPSSample" \
-F ios='[
    {
      "url" : "rps-sample-applink-example://",
      "app_store_id" : 794163692,
      "app_name" : "RPS Sample",
    },
  ]' \
-F android=' [
    {
      "package" : "com.facebook.samples.rps",
      "app_name" : "RPS Sample",
    },
  ]' \
-F web=' {
    "should_fallback" : false,
  }' \
| perl -ne '/"id":\s*"(.*)"/ && print $1'`

FB_APPLINK_HOST_URL=` \
curl -X GET https://graph.facebook.com/v2.0/$FB_APPLINK_HOST_ID?access_token="$APPID|$APPSECRET" \
| perl -ne '/"canonical_url":\s*"(.*)"/ && print $1' `

echo "  applink host url id: $FB_APPLINK_HOST_ID"
echo "  applink host url: $FB_APPLINK_HOST_URL"

#
# step 4 - create objects and capture their IDs in variables
#

# rock
ROCK_OBJID=` \
  curl -s -X POST -F "object={\"title\":\"Rock\",\"description\":\"Breaks scissors, alas is covered by paper.\",\"image\":\"$ROCK_IMAGE_URI\",\"url\":\"$FB_APPLINK_HOST_URL?gesture=rock\"}" "https://graph.facebook.com/$APPID/objects/fb_sample_rps:gesture?access_token=$APPID|$APPSECRET" \
  | perl -ne '/"id":"(.*)"}/ && print $1' `

# paper
PAPER_OBJID=` \
  curl -s -X POST -F "object={\"title\":\"Paper\",\"description\":\"Covers rock, sadly scissors cut it.\",\"image\":\"$PAPER_IMAGE_URI\",\"url\":\"$FB_APPLINK_HOST_URL?gesture=paper\"}" "https://graph.facebook.com/$APPID/objects/fb_sample_rps:gesture?access_token=$APPID|$APPSECRET" \
  | perl -ne '/"id":"(.*)"}/ && print $1' `

# scissors
SCISSORS_OBJID=` \
  curl -s -X POST -F "object={\"title\":\"Scissors\",\"description\":\"Cuts paper, broken by rock -- bother.\",\"image\":\"$SCISSORS_IMAGE_URI\",\"url\":\"$FB_APPLINK_HOST_URL?gesture=scissors\"}" "https://graph.facebook.com/$APPID/objects/fb_sample_rps:gesture?access_token=$APPID|$APPSECRET" \
  | perl -ne '/"id":"(.*)"}/ && print $1' `


#
# step 5 - echo progress
#

echo "created application objects..."
echo "  rock=$ROCK_OBJID"
echo "  paper=$PAPER_OBJID"
echo "  scissors=$SCISSORS_OBJID"

#
# step 6 - write .m file for common objects
#

MFILE=RPSSample/RPSCommonObjects.m

cat > $MFILE << EOF
// Copyright (c) Facebook, Inc. and its affiliates. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Platform Policy
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

NSString *builtInOpenGraphObjects[3] = {
                                        @"$ROCK_OBJID",      // rock
                                        @"$PAPER_OBJID",      // paper
                                        @"$SCISSORS_OBJID"};     // scissors
EOF

echo "created $MFILE ..."
echo done.
