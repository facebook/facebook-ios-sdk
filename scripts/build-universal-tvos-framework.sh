#!/bin/sh

UNIVERSAL_OUTPUTFOLDER=../build/tv/

# make the output directory and delete the framework directory
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"
rm -rf "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework"

# Step 1. Build Device and Simulator versions
xcodebuild -target "${PROJECT_NAME}_TV" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk appletvos BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
xcodebuild -target "${PROJECT_NAME}_TV" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk appletvsimulator BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

# Step 2. Copy the framework structure to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-appletvos/${PROJECT_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"

# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
"${BUILD_DIR}/${CONFIGURATION}-appletvsimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" \
"${BUILD_DIR}/${CONFIGURATION}-appletvos/${PROJECT_NAME}.framework/${PROJECT_NAME}"


