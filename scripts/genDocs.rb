#!/usr/bin/env ruby
# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

require "json"
require "FileUtils"
require 'pathname'

kit = ARGV[0]

# Constants
CORE_KIT = 'FBSDKCoreKit'
LOGIN_KIT = 'FBSDKLoginKit'
SHARE_KIT = 'FBSDKShareKit'
GAMING_SERVICES_KIT = 'FBSDKGamingServicesKit'

HEADER_PATHS = {
  CORE_KIT => "FBSDKCoreKit/FBSDKCoreKit/include/FBSDKCoreKit.h",
  LOGIN_KIT => "FBSDKLoginKit/FBSDKLoginKit/FBSDKLoginKit.h",
  SHARE_KIT => "FBSDKShareKit/FBSDKShareKit/FBSDKShareKit.h",
  GAMING_SERVICES_KIT => "FBSDKGamingServicesKit/FacebookGamingServices/FacebookGamingServices.h",
}

def base_path
  Pathname.getwd
end

def path_name(kit)
  base_path  + "#{kit}"
end

def headerPathFor(kit)
  header_path = base_path + HEADER_PATHS[kit]

  if !header_path.exist?
    abort "*** ERROR: unable to document #{kit}. Missing header at #{header_path.to_s}"
  end

  return header_path
end

def rec_path(path)
  path.children.collect do |child|
    if child.directory?
      rec_path(child) + [child]
    end
  end.select { |x| x }.flatten(1)
end

def sdk_version
  "$(grep -Eo 'FBSDK_VERSION_STRING @\".*\"' \"FBSDKCoreKit/FBSDKCoreKit/include/FBSDKCoreKitVersions.h\" | awk -F'\"' '{print $2}')"
end

def generateSourceKittenOutputForObjC(kit)
  arguments = [
    'doc', '--objc', headerPathFor(kit).to_s, '--', '-x',
    'objective-c', '-isysroot',
    `xcrun --show-sdk-path --sdk iphonesimulator`.chomp,
    '-I', path_name(kit),
    '-fmodules'
  ]

  rec_path(path_name(kit)).collect do |child|
    if child.directory?
      arguments += ['-I', child.to_s]
    end
  end

  arguments += ['-I', base_path.join('FBSDKCoreKit').to_s]
  system "sourcekitten #{arguments.join(' ')} > tmpObjC"
end

def generateSourceKittenOutputForSwift(kit)
  File.delete("tmpSwift") if File.exist?("tmpSwift")
  system "sourcekitten doc -- -workspace FacebookSDK.xcworkspace -scheme #{kit}-Dynamic > tmpSwift"
end

def combineSourceKittenOutputFor(kit)
  puts "Generating documentation for #{kit}"

  if File.exist?('tmpSwift')
    sourcefiles = 'tmpSwift,tmpObjC'
  else
    sourcefiles = 'tmpObjC'
  end

  system "bundle exec jazzy \
    --config #{base_path + '.jazzy.yaml'} \
    --output docs/#{kit} \
    --module #{kit} \
    --module-version \"#{sdk_version}\" \
    --sourcekitten-sourcefile #{sourcefiles}"
end

case kit
when /#{CORE_KIT}|#{LOGIN_KIT}|#{SHARE_KIT}/
  generateSourceKittenOutputForSwift(kit)
  generateSourceKittenOutputForObjC(kit)
  combineSourceKittenOutputFor(kit)
else
  generateSourceKittenOutputForObjC(kit)
  combineSourceKittenOutputFor(kit)
end

File.delete("tmpSwift") if File.exist?("tmpSwift")
File.delete("tmpObjC") if File.exist?("tmpObjC")
