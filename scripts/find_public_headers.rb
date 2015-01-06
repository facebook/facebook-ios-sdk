#!/usr/bin/env ruby

require 'pathname'
require 'xcodeproj'

ROOT = Pathname.new(File.expand_path('../../', __FILE__))

separator = ARGV.shift || "\n"

project = Xcodeproj::Project.open(ROOT + 'src/facebook-ios-sdk.xcodeproj')
target = project.targets.find { |t| t.symbol_type == :static_library && t.name == 'facebook-ios-sdk' }
public_headers = target.headers_build_phase.files.select do |build_file|
  settings = build_file.settings
  settings && settings['ATTRIBUTES'].include?('Public')
end

puts public_headers.map { |build_file|
  build_file.file_ref.real_path.relative_path_from ROOT
}.to_a.join(separator)
