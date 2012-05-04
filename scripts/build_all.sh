#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script builds the FBiOSSDK.framework, all samples, and the distribution package.

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

# -----------------------------------------------------------------------------
# Call out to build .framework
#
echo "Building framework."
. $FB_SDK_SCRIPT/build_framework.sh

# -----------------------------------------------------------------------------
# Call out to build samples (suppress building framework)
#
echo "Building samples."
. $FB_SDK_SCRIPT/build_samples.sh Release
. $FB_SDK_SCRIPT/build_samples.sh Debug

# -----------------------------------------------------------------------------
# Call out to build distribution (suppress building framework)
echo "Building distribution."
. $FB_SDK_SCRIPT/build_distribution.sh

common_success
