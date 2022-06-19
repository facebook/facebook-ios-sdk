#!/usr/bin/env ruby
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

require 'fileutils'

hooksLocation = File.expand_path(File.dirname(__FILE__))
installPath = File.expand_path(`git rev-parse --show-cdup`).sub(/\s+\Z/, "") + ".git/hooks"

if File.symlink?(installPath)
  exit 0
end

puts "Installing into " + installPath + " ..."

if File.directory? installPath
  if Dir.entries(installPath).size == 2 # . and ..
    puts "Removing empty hooks directory."
    FileUtils.rm_rf installPath
  elsif Dir.entries(installPath).size - 2 == Dir.glob(installPath + '/*.sample').size
    puts "Removing sample hooks directory."
    FileUtils.rm_rf installPath
  else
    puts "There are existing hooks! This is not supported :( Sad Panda..."
    exit 1
  end
end

File.symlink(hooksLocation, installPath)

