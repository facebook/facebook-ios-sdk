#!/usr/bin/env ruby

require 'json'
require "net/http"
require 'open-uri'
require 'zip'

require 'byebug'

class GitHubConstants
  Name = 'name'
  DownloadURL = 'browser_download_url'
  ReleaseURL = 'https://api.github.com/repos/facebook/facebook-objc-sdk/releases/latest'
end

class Filenames
  DynamicFrameworks = 'FacebookSDK_Dynamic.framework.zip'
  SwiftDynamicFrameworks = 'Swift.zip'

  ObjcDynamicFrameworksZip = 'objcDynamicFrameworks.zip'
  SwiftDynamicFrameworksZip = 'swiftDynamicFrameworks.zip'
end

# Fetch the latest release from github
url = GitHubConstants::ReleaseURL
uri = URI(url)
response = Net::HTTP.get(uri)

json = JSON.parse(response)
assets = json['assets']

# Get the asset with the name FacebookSDK_Dynamic.framework.zip
objcDynamicFrameworksAsset = assets.find{ |asset|
  asset[GitHubConstants::Name] == Filenames::DynamicFrameworks
}
objcDynamicFrameworksURL = objcDynamicFrameworksAsset[GitHubConstants::DownloadURL]
objcDynamicFrameworksZip = open(objcDynamicFrameworksURL)

# Get the swift dynamic frameworks (need to change this to the correct path before checking in)
swiftDynamicFrameworksAsset = assets.find{ |asset|
  asset[GitHubConstants::Name] == Filenames::SwiftDynamicFrameworks
}
swiftDynamicFrameworksURL = swiftDynamicFrameworksAsset[GitHubConstants::DownloadURL]
swiftDynamicFrameworksZip = open(swiftDynamicFrameworksURL)

# Renaming the Tempfile format provided by the `open` method to be human readable
FileUtils.mv(objcDynamicFrameworksZip.path, Filenames::ObjcDynamicFrameworksZip)
FileUtils.mv(swiftDynamicFrameworksZip.path, Filenames::SwiftDynamicFrameworksZip)

# Extract objc dynamic frameworks
Zip::File.open(Filenames::ObjcDynamicFrameworksZip) do |zip_file|
  # Handle entries one by one
  zip_file.each do |entry|
    puts "Extracting #{entry.name}"
    entry.extract("Artifacts/#{entry.name}")
  end
end

# Extract swift dynamic frameworks
Zip::File.open(Filenames::SwiftDynamicFrameworksZip) do |zip_file|
  # Handle entries one by one
  zip_file.each do |entry|
    # Extract to file/directory/symlink
    puts "Extracting #{entry.name}"
    entry.extract("Artifacts/#{entry.name}")
  end
end

system "zip -r -m Artifacts.zip Artifacts"
system 'rm -rf Artifacts'
system "mv Artifacts.zip build/Release/#{Filenames::DynamicFrameworks}"

FileUtils.rm_f("Artifacts")
FileUtils.rm_f(Filenames::ObjcDynamicFrameworksZip)
FileUtils.rm_f(Filenames::SwiftDynamicFrameworksZip)
