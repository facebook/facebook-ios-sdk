#!/bin/sh
#
# Copyright 2010-present Facebook.
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

# This script builds the FacebookSDK.framework, all samples, and the distribution package.

. "${FB_SDK_SCRIPT:-$(dirname "$0")}/common.sh"

# -----------------------------------------------------------------------------
# Call out to build .framework
#
. "$FB_SDK_SCRIPT/build_framework.sh"

# -----------------------------------------------------------------------------
# Build docs
#
. "$FB_SDK_SCRIPT/build_documentation.sh"

# -----------------------------------------------------------------------------
# Call out to build samples (suppress building framework)
#
. "$FB_SDK_SCRIPT/build_samples.sh" Release
. "$FB_SDK_SCRIPT/build_samples.sh" Debug

# -----------------------------------------------------------------------------
# Call out to build distribution (suppress building framework)
#
. "$FB_SDK_SCRIPT/build_distribution.sh"

common_success
