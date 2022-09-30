#!/bin/sh
#
# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.


# This script runs a few shell commands for additional code formatting cleanup

# cd up one level if run from the scripts dir
CURRENT_DIR_NAME="${PWD##*/}"
if [ "$CURRENT_DIR_NAME" = "scripts" ]; then
  cd ..
fi

# Remove UIColor prefix. (Note: Dosen't work for .cgColor ones ex: "layer.shadowColor = UIColor.black.cgColor")
git ls-files '*.swift' -z | xargs -0 perl -pi -e 's/(\.(?:background|text)Color) = UIColor(\.\w+)/\1 = \2/'
