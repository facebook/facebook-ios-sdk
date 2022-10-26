#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

# --------------
# Imports
# --------------

# shellcheck source=./internal_globals.sh
. "$PWD/internal/scripts/internal_globals.sh"

# --------------
# APIs
# --------------

api_create_sitevar_diff() {
  # $1="{\"$SDK_DOWNLOAD_IOS\": \"$HANDLER_IOS\"}"
  curl \
    -L \
    -X POST \
    -F app="$SDK_FB_APP_ID" \
    -F token="$SDK_FB_TOKEN" \
    -F unixname="$USER" \
    -F sdk_version="v$SDK_CURRENT_VERSION" \
    -F sdk_language=ios \
    -F reviewers="$FB_SDK_PROJECT" \
    -F new_handlers="$1" \
    "$FB_INTERN_GRAPH_API/fbsdk/create_sitevar_diff"
}

api_update_reference_doc() {
  # $1= Kit e.g. "FBSDKCoreKit"
  curl \
    -i \
    -L \
    -X POST \
    -F app="$SDK_FB_APP_ID" \
    -F token="$SDK_FB_TOKEN" \
    -F unixname="$USER" \
    -F sdk_language=ios \
    -F parent_folder_id="$DOCS_REFERENCE_ID" \
    -F folder_name="$SDK_CURRENT_VERSION" \
    -F is_test_mode=0 \
    -F kit="$1" \
    -F reference_docs_package="@/$SDK_DIR/docs/$1.zip" \
    "$FB_INTERN_GRAPH_API/fbsdk/publish_reference_doc"
}

api_update_guide_doc() {
  # $1= $CHANGELOG
  curl \
    -L \
    -X POST \
    -F app="$SDK_FB_APP_ID" \
    -F token="$SDK_FB_TOKEN" \
    -F unixname="$USER" \
    -F sdk_version="v$SDK_CURRENT_VERSION" \
    -F sdk_language=ios \
    -F main_guide="$DOCS_MAIN_GUIDE_ID" \
    -F upgrade_guide="$DOCS_UPGRADE_GUIDE_ID" \
    -F download_guide="$DOCS_DOWNLOAD_GUIDE_ID" \
    -F changelog_guide="$DOCS_CHANGELOG_GUIDE_ID" \
    -F is_test_mode=0 \
    -F changelog="$1" \
    "$FB_INTERN_GRAPH_API/fbsdk/update_doc"
}

api_upload_sdk() {
  # $1= $path/to/file.zip
  curl \
    -i \
    -L \
    -X POST \
    -F app="$SDK_FB_APP_ID" \
    -F token="$SDK_FB_TOKEN" \
    -F unixname="$USER" \
    -F sdk_version="v$SDK_CURRENT_VERSION" \
    -F sdk_language=ios \
    -F is_test_mode=0 \
    -F upload="@$1" \
    "$FB_INTERN_GRAPH_API/fbsdk/upload"
}
