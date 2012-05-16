#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script builds the FBiOSSDK.framework, all samples, and the distribution package.

. ${FB_SDK_SCRIPT:-$(dirname $0)}/common.sh

# -----------------------------------------------------------------------------
# Call out to build .framework
#
. $FB_SDK_SCRIPT/build_framework.sh

# -----------------------------------------------------------------------------
# Build docs
#
. $FB_SDK_SCRIPT/build_documentation.sh

# -----------------------------------------------------------------------------
# Call out to build samples (suppress building framework)
#
. $FB_SDK_SCRIPT/build_samples.sh Release
. $FB_SDK_SCRIPT/build_samples.sh Debug

# -----------------------------------------------------------------------------
# Call out to build distribution (suppress building framework)
#
. $FB_SDK_SCRIPT/build_distribution.sh

common_success
