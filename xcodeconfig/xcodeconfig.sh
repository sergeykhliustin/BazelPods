#!/bin/bash

# Get the Xcode version and build number
XCODE_VERSION_FULL=$(xcodebuild -version)
XCODE_VERSION=$(echo "$XCODE_VERSION_FULL" | head -n 1 | awk '{ print $2 }')
XCODE_BUILD_NUMBER=$(echo "$XCODE_VERSION_FULL" | tail -n 1 | awk '{ print $3 }')

# If XCODE_VERSION has only 1 dot, append a ".0"
if [[ $XCODE_VERSION == *.* && ! $XCODE_VERSION == *.*.* ]]; then
    XCODE_VERSION_EXTENDED="$XCODE_VERSION.0"
    XCODE_ALIASES="['${XCODE_VERSION_EXTENDED}.${XCODE_BUILD_NUMBER}', '${XCODE_VERSION}', '${XCODE_VERSION_EXTENDED}', '${XCODE_BUILD_NUMBER}', '${XCODE_VERSION%%.*}'],"
else
    XCODE_VERSION_EXTENDED="$XCODE_VERSION"
    XCODE_ALIASES="['${XCODE_VERSION_EXTENDED}.${XCODE_BUILD_NUMBER}', '${XCODE_VERSION}', '${XCODE_BUILD_NUMBER}', '${XCODE_VERSION%%.*}'],"
fi

# Get the SDK versions
IOS_SDK_VERSION=$(xcodebuild -showsdks | grep -Eo 'iphoneos[0-9.]+' | grep -Eo '[0-9.]+[0-9]' | head -1)
MACOS_SDK_VERSION=$(xcodebuild -showsdks | grep -Eo 'macosx[0-9.]+' | grep -Eo '[0-9.]+[0-9]' | head -1)
TVOS_SDK_VERSION=$(xcodebuild -showsdks | grep -Eo 'appletvos[0-9.]+' | grep -Eo '[0-9.]+[0-9]' | head -1)
WATCHOS_SDK_VERSION=$(xcodebuild -showsdks | grep -Eo 'watchos[0-9.]+' | grep -Eo '[0-9.]+[0-9]' | head -1)

# Generate Bazel BUILD file
echo "xcode_version(
  name = 'version${XCODE_VERSION//./_}_${XCODE_BUILD_NUMBER//./_}',
  version = '${XCODE_VERSION_EXTENDED}.${XCODE_BUILD_NUMBER}',
  aliases = ${XCODE_ALIASES}
  default_ios_sdk_version = '$IOS_SDK_VERSION',
  default_tvos_sdk_version = '$TVOS_SDK_VERSION',
  default_macos_sdk_version = '$MACOS_SDK_VERSION',
  default_watchos_sdk_version = '$WATCHOS_SDK_VERSION',
)

xcode_config(
  name = 'host_xcodes',
  versions = [':version${XCODE_VERSION//./_}_${XCODE_BUILD_NUMBER//./_}'],
  default = ':version${XCODE_VERSION//./_}_${XCODE_BUILD_NUMBER//./_}',
)"
