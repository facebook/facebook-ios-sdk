# Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

require 'mkmf'
require 'json'

# Make FileUtils less verbose aka not log anything when running `mkdir_p`
Rake::FileUtilsExt.verbose(false)

WORKSPACE = 'FacebookSwift.xcworkspace'
SCHEMES = [
  'FacebookCore',
  'FacebookLogin',
  'FacebookShare',
]

DOCS_FOLDER = '.docs'
JAZZY_CONFIG = '.jazzy.json'

def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    }
  end
  return nil
end

desc 'Generate API Reference'
task :docs do
  unless which('sourcekitten') && which('jazzy')
    puts 'Can\'t find sourcekitten and jazzy in $PATH.'
    puts 'Install them with \'brew install sourcekitten\' and \'gem install jazzy\'.'
    exit 1
  end

  declarations = []
  SCHEMES.each do |scheme|
    json_string = `sourcekitten doc -- -scheme #{scheme} -workspace #{WORKSPACE}`
    json = JSON.parse(json_string)

    json = json.map do |element|
       element.map do |key,value|
           value["key.substructure"] = value["key.substructure"].select do |element|
               element["key.name"] != "==(_:_:)"
           end
           [key, value]
       end.to_h
    end
    declarations.concat json
  end

  mkdir_p '.docs'

  sourcekit_file = File.join(DOCS_FOLDER, 'source.json')
  File.open(sourcekit_file, 'w') do |f|
    f.write(declarations.to_json)
  end

  `jazzy --config #{JAZZY_CONFIG} --sourcekitten-sourcefile #{sourcekit_file} --output #{DOCS_FOLDER}`
end
