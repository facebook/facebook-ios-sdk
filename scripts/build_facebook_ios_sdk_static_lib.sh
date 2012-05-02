#!/bin/sh
#
# Copyright 2004-present Facebook. All Rights Reserved.
#

# This script will build a static library version of the Facebook iOS SDK.
# You may want to use this script if you have a project that has the 
# Automatic Reference Counting feature turned on. Once you run this script
# you will get a directory under the iOS SDK project home path:
#    lib/facebook-ios-sdk
# You can drag the facebook-ios-sdk directory into your Xcode project and
# copy the contents over or include it as a reference.

# Function for handling errors
die() {
    echo ""
    echo "$*" >&2
    exit 1
}

# The Xcode bin path
if [ -d "/Developer/usr/bin" ]; then
   # < XCode 4.3.1
  XCODEBUILD_PATH=/Developer/usr/bin
else
  # >= XCode 4.3.1, or from App store
  XCODEBUILD_PATH=/Applications/XCode.app/Contents/Developer/usr/bin
fi
XCODEBUILD=$XCODEBUILD_PATH/xcodebuild
test -x "$XCODEBUILD" || die "Could not find xcodebuild in $XCODEBUILD_PATH"

# Get the script path and set the relative directories used
# for compilation
cd $(dirname $0)
SCRIPTPATH=`pwd`
cd $SCRIPTPATH/../

# The home directory where the SDK is installed
PROJECT_HOME=`pwd`

echo "Project Home: $PROJECT_HOME"

# The facebook-ios-sdk src directory path
SRCPATH=$PROJECT_HOME/src

# The directory where the target is built
BUILDDIR=$PROJECT_HOME/build

# The directory where the library output will be placed
LIBOUTPUTDIR=$PROJECT_HOME/lib/facebook-ios-sdk

echo "Start Universal facebook-ios-sdk SDK Generation"

echo "Step 1 : facebook-ios-sdk SDK Build Library for simulator and device architecture"

cd $SRCPATH

$XCODEBUILD -target "facebook-ios-sdk" -sdk "iphonesimulator" -configuration "Release" SYMROOT=$BUILDDIR clean build || die "iOS Simulator build failed"
$XCODEBUILD -target "facebook-ios-sdk" -sdk "iphoneos" -configuration "Release" SYMROOT=$BUILDDIR clean build || die "iOS Device build failed"

echo "Step 2 : Remove older SDK Directory"

\rm -rf $LIBOUTPUTDIR

echo "Step 3 : Create new SDK Directory Version"

mkdir -p $LIBOUTPUTDIR

echo "Step 4 : Create combine lib files for various platforms into one"

# combine lib files for various platforms into one
lipo -create $BUILDDIR/Release-iphonesimulator/libfacebook_ios_sdk.a $BUILDDIR/Release-iphoneos/libfacebook_ios_sdk.a -output $LIBOUTPUTDIR/libfacebook_ios_sdk.a || die "Could not create static output library"

echo "Step 5 : Copy headers Needed"
\cp $SRCPATH/*.h $LIBOUTPUTDIR/
\cp $SRCPATH/JSON/*.h $LIBOUTPUTDIR/

echo "Step 6 : Copy other file needed like bundle"
\cp -r $SRCPATH/*.bundle $LIBOUTPUTDIR

echo "Finished Universal facebook-ios-sdk SDK Generation"
echo ""
echo "You can now use the static library that can be found at:"
echo ""
echo $LIBOUTPUTDIR
echo ""
echo "Just drag the facebook-ios-sdk directory into your project to include the Facebook iOS SDK static library"
echo ""
echo ""

exit 0
