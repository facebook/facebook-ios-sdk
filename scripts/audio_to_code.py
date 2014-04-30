#!/usr/bin/python

import sys
import getopt
import os

headerTemplate = """/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * This is is a generated file during the SDK build process.
 * Please do not hand edit this file.
 * It can be rebuilt by running 
 *
 *   ./audio_to_code.py %(args)s
 *
 */
"""

def bytes_from_file(filename, chunksize=8192):
  with open(filename, "rb") as f:
    while True:
      chunk = f.read(chunksize)
      if chunk:
        for b in chunk:
          yield b
      else:
        break

def write_header_file(header, className, outputFile):
  with open(outputFile, "w") as f:
    f.write(header)
    f.write("""
#import <Foundation/Foundation.h>

#import "FBAudioResourceLoader.h"

""")
    f.write("@interface " + className + " : FBAudioResourceLoader\n")
    f.write("@end")

def write_implementation_file(inputFile, header, className, outputFile):
  formattedBytes = ["0x{0:02x}".format(ord(x)) for x in bytes_from_file(inputFile)]
  with open(outputFile, "w") as f:
    f.write(header)
    f.write("\n")
    f.write("#import \"" + className + ".h\"\n\n")
    f.write("@implementation " + className + "\n\n")

    f.write("+ (NSString *)name\n");
    f.write("{\n");
    f.write("  return @\"" + os.path.basename(inputFile) + "\";\n")
    f.write("}\n\n");

    f.write("+ (NSData *)data\n")
    f.write("{\n")
    f.write("  const Byte bytes[] = {\n")
    f.write(", ".join(formattedBytes))
    f.write("  };\n")
    f.write("  NSUInteger length = sizeof(bytes) / sizeof(Byte);\n")
    f.write("  return [NSData dataWithBytesNoCopy:(void *)bytes length:length freeWhenDone:NO];\n")
    f.write("}\n\n")

    f.write("@end\n")

def usage(exitCode):
  print 'audio_to_code.py -i <inputFile> -c <class> -o <outputDir>'
  sys.exit(exitCode)

def main(argv):
  inputFile = ''
  outputClass = ''
  outputDir = ''

  try:
    opts, args = getopt.getopt(argv,"hi:c:o:")
  except getopt.GetoptError:
    usage(2)
  for opt, arg in opts:
    if opt == '-h':
      usage(0)
    elif opt == '-i':
      inputFile = arg
    elif opt == '-c':
      outputClass = arg
    elif opt in '-o':
      outputDir = arg

  if not inputFile:
    print 'inputFile is required.'
    usage(2)

  if not outputClass:
    print 'outputFile is required.'
    usage(2)

  if not outputDir:
    print 'outputDir is required.'
    usage(2)

  # Build file headers
  header = headerTemplate % {"args" : " ".join(argv)}

  # outputClass needs to add WAV as part of it
  outputClass = outputClass + "WAV"

  # Build the output base filename
  outputFileBase = outputDir + "/" + outputClass

  # Build .h file
  outputFile = outputFileBase + ".h"
  write_header_file(header, outputClass, outputFile)

  # Build .m file
  outputFile = outputFileBase + ".m"
  write_implementation_file(inputFile, header, outputClass, outputFile)

if __name__ == "__main__":
   main(sys.argv[1:])
