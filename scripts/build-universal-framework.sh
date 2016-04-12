#!/bin/sh

UNIVERSAL_OUTPUT_FOLDER=../build/

# make the output directory and delete the framework directory
mkdir -p "${UNIVERSAL_OUTPUT_FOLDER}"
rm -rf "${UNIVERSAL_OUTPUT_FOLDER}/${PROJECT_NAME}.framework"

# Step 1. Build Device and Simulator versions
xcodebuild -target "${PROJECT_NAME}" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphoneos  BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
xcodebuild -target "${PROJECT_NAME}" ONLY_ACTIVE_ARCH=NO -configuration ${CONFIGURATION} -sdk iphonesimulator BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

# Step 2. Copy the framework structure to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework" "${UNIVERSAL_OUTPUT_FOLDER}/"

# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUT_FOLDER}/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${PROJECT_NAME}.framework/${PROJECT_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${PROJECT_NAME}.framework/${PROJECT_NAME}"

# Step 4. Copy strings bundle if exists
STRINGS_INPUT_FOLDER="${PROJECT_NAME}Strings.bundle"
if [ -d "${STRINGS_INPUT_FOLDER}" ]; then
  STRINGS_OUTPUT_FOLDER="${UNIVERSAL_OUTPUT_FOLDER}/${PROJECT_NAME}Strings.bundle"
  rm -rf "${STRINGS_OUTPUT_FOLDER}"
  cp -R "${STRINGS_INPUT_FOLDER}" "${STRINGS_OUTPUT_FOLDER}"
fi
