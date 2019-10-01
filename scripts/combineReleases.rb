#!/usr/bin/env ruby

require 'json'
require "net/http"
require 'open-uri'
require 'zip'

class GitHubConstants
  Name = 'name'
  DownloadURL = 'browser_download_url'
  BaseURL = 'https://api.github.com/repos/facebook/facebook-ios-sdk/releases/'
end

class Filenames
  RemoteObjCFrameworks = 'FacebookSDK_Dynamic.framework.zip'
  RemoteSwiftFrameworks = 'SwiftDynamic.zip'

  ObjcFrameworks = 'objcDynamicFrameworks.zip'
  SwiftFrameworks = 'swiftDynamicFrameworks.zip'
end

# Fetch the latest release from github
url = GitHubConstants::BaseURL + "latest"
uri = URI(url)
response = Net::HTTP.get(uri)

json = JSON.parse(response)
assets = json['assets']

# Get the asset with the name FacebookSDK_Dynamic.framework.zip
objcAsset = assets.find{ |asset|
  asset[GitHubConstants::Name] == Filenames::RemoteObjCFrameworks
}
objcURL = objcAsset[GitHubConstants::DownloadURL]
objcTempFile = open(objcURL)

# Get the swift dynamic frameworks (need to change this to the correct path before checking in)
swiftAsset = assets.find{ |asset|
  asset[GitHubConstants::Name] == Filenames::RemoteSwiftFrameworks
}
swiftURL = swiftAsset[GitHubConstants::DownloadURL]
swiftTempFile = open(swiftURL)

# Renaming the Tempfile format provided by the `open` method to be human readable
FileUtils.mv(objcTempFile.path, Filenames::ObjcFrameworks)
FileUtils.mv(swiftTempFile.path, Filenames::SwiftFrameworks)

# Extract objc dynamic frameworks
Zip::File.open(Filenames::ObjcFrameworks) do |zip_file|
  # Handle entries one by one
  zip_file.each do |entry|
    puts "Extracting #{entry.name}"
    entry.extract("Artifacts/#{entry.name}")
  end
end

# Extract swift dynamic frameworks
Zip::File.open(Filenames::SwiftFrameworks) do |zip_file|
  # Handle entries one by one
  zip_file.each do |entry|
    # Extract to file/directory/symlink
    puts "Extracting #{entry.name}"
    entry.extract("Artifacts/#{entry.name}")
  end
end

system "zip -r -m Artifacts.zip Artifacts"
system 'rm -rf Artifacts'

# Use the same name as the original release to preserve CI for existing users.
system "mv Artifacts.zip build/Release/#{Filenames::RemoteObjCFrameworks}"
