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
require 'pathname'

kit = ARGV[0]

# Constants
CORE_KIT = 'FBSDKCoreKit'
LOGIN_KIT = 'FBSDKLoginKit'
SHARE_KIT = 'FBSDKShareKit'
GAMING_SERVICES_KIT = 'FBSDKGamingServicesKit'

def base_path
  Pathname.getwd
end

def path_name(kit)
  base_path  + "#{kit}"
end

def headerPathFor(kit)
  header_path = base_path + "#{kit}/#{kit}/#{kit}.h"

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
  "$(grep -Eo 'FBSDK_VERSION_STRING @\".*\"' \"FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit.h\" | awk -F'\"' '{print $2}')"
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
  system "sourcekitten doc -- -workspace FacebookSDK.xcworkspace -scheme #{kit} > tmpSwift"
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
