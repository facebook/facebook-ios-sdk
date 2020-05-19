#!/usr/bin/env ruby
# Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
#
# You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
# copy, modify, and distribute this software in source code or binary form for use
# in connection with the web services and APIs provided by Facebook.
#
# As with any software that integrates with the Facebook platform, your use of
# this software is subject to the Facebook Developer Principles and Policies
# [http://developers.facebook.com/policy/]. This copyright notice shall be
# included in all copies or substantial portions of the software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "json"
require "FileUtils"

kit = ARGV[0]

# Constants
CORE_KIT = 'FBSDKCoreKit'
LOGIN_KIT = 'FBSDKLoginKit'
SHARE_KIT = 'FBSDKShareKit'

def generateSourceKittenOutputForSwift(kit)
  swiftKit = "#{kit}Swift"

  File.delete("tmpSwift") if File.exist?("tmpSwift")

  # Moves the scheme back to the shareddata directory where it can be found by the xcodebuild tool
  # keeping it there from the beginning breaks Carthage when building on Xcode 10.2
  # The scheme can be moved permanently and this line deleted when we drop support for Xcode 10.2
  #
  FileUtils.mv("#{kit}/#{kit}/Swift/#{swiftKit}.xcscheme", "#{kit}/#{kit}.xcodeproj/xcshareddata/xcschemes/")

  system "bundle exec sourcekitten doc -- -workspace FacebookSDK.xcworkspace -scheme #{swiftKit} > tmpSwift"
end

def scriptsDirectory
  File.dirname(__FILE__)
end

def parentDirectory
  File.dirname(scriptsDirectory)
end

def headerFileFor(kit)
  header_file = "#{parentDirectory}/#{kit}/#{kit}/#{kit}.h"

  if !File.exist?(header_file)
    abort "*** ERROR: unable to document #{kit}. Missing header at #{header_file}"
  end

  return header_file
end

def generateSourceKittenOutputForObjC(kit)
  header_file = headerFileFor(kit)

  # hacky fix because of https://github.com/realm/jazzy/issues/667:
  FileUtils.cp_r(
    "#{parentDirectory}/FBSDKCoreKit/FBSDKCoreKit/AppEvents/.",
    "#{parentDirectory}/FBSDKCoreKit/FBSDKCoreKit"
  )
  FileUtils.cp_r(
    "#{parentDirectory}/FBSDKCoreKit/FBSDKCoreKit/AppLink/.",
    "#{parentDirectory}/FBSDKCoreKit/FBSDKCoreKit"
  )
  FileUtils.cp_r(
    "#{parentDirectory}/FBSDKCoreKit/FBSDKCoreKit/GraphAPI/.",
    "#{parentDirectory}/FBSDKCoreKit/FBSDKCoreKit"
  )

  # This is a little weird. We need to include paths to the FBSDKCoreKit headers in order for sourcekitten to
  # include the symbols in the output for FBSDKLoginKit and FBSDKShareKit
  # However, if you include the header path in the command for FBSDKCoreKit itself
  # then it won't include Swift definitions. Hence the need to have a separate commend for FBSDKCoreKit.
  #
  if kit == CORE_KIT
    system "bundle exec sourcekitten doc --objc #{header_file} \
      -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \
      -I #{parentDirectory}/#{kit} > tmpObjC"
  else
    system "bundle exec sourcekitten doc --objc #{header_file} \
    -- -x objective-c  -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) \
    -I #{parentDirectory}/FBSDKCoreKit \
    -I #{parentDirectory}/#{kit} > tmpObjC"
  end
end

def combineSourceKittenOutputFor(kit)
  puts "Generating source kitten output for #{kit}"

  swiftSourceKittenOutput = File.open "tmpSwift"
  swiftSourceKittenJSON = JSON.load swiftSourceKittenOutput

  objCSourceKittenOutput = File.open "tmpObjC"
  objCSourceKittenJSON = JSON.load objCSourceKittenOutput

  puts "Generating documentation for #{kit}"

  system "bundle exec jazzy \
    --config #{parentDirectory}/.jazzy.yaml \
    --output docs/#{kit} \
    --sourcekitten-sourcefile tmpSwift,tmpObjC"
end

case kit
when /#{CORE_KIT}|#{LOGIN_KIT}|#{SHARE_KIT}/
  generateSourceKittenOutputForSwift(kit)
  generateSourceKittenOutputForObjC(kit)
  combineSourceKittenOutputFor(kit)

else
  header_file = headerFileFor(kit)

  system "bundle exec jazzy \
    --framework-root #{prefixFor(kit)}#{kit} \
    --output docs/#{kit} \
    --umbrella-header #{header_file}"
end

File.delete("tmpSwift") if File.exist?("tmpSwift")
File.delete("tmpObjC") if File.exist?("tmpObjC")
