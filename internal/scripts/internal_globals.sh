#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

# --------------
# Constants
# --------------

if [ -z "${FB_INTERN_GRAPH_API:-}" ]; then
  # Facebook Intern Graph API
  export readonly FB_INTERN_GRAPH_API="https://interngraph.intern.facebook.com"

  # App ID & Token
  readonly SDK_FB_APP_ID="584194605123473"
  readonly SDK_FB_TOKEN="AeNwlq1Xg7CoDH2b910"

  # Phabricator SDK Project
  readonly FB_SDK_PROJECT="268235620580741"

  # CMS Documentation Folder IDs
  readonly DOCS_REFERENCE_ID="1111513138963800"
  readonly DOCS_MAIN_GUIDE_ID="1641372119445300"
  readonly DOCS_UPGRADE_GUIDE_ID="460058470846126"
  readonly DOCS_DOWNLOAD_GUIDE_ID="432928110227587"
  readonly DOCS_CHANGELOG_GUIDE_ID="1929572857267386"

  readonly SDK_TEST_FB_APP_ID="414221181947517"
  readonly SDK_TEST_FB_APP_SECRET="aaabff2ccdd32888e887d2ffc3e1bf4e"
  readonly SDK_TEST_FB_CLIENT_TOKEN="dd1aec0b479fa0856c57f345aafa517b"
fi
