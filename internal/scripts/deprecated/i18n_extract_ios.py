#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import codecs
import getopt
import os
import sys
import xml.dom.minidom


def main(argv):
    keys = []
    inputFile = None
    outputFile = None
    try:
        opts, args = getopt.getopt(argv, "hk:i:o:", ["keys=", "input=", "output="])
    except getopt.GetoptError:
        showUsage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-h":
            showUsage()
            sys.exit()
        elif opt in ("-k", "--keys"):
            keys = map(str.strip, arg.split(","))
        elif opt in ("-i", "--input"):
            inputFile = arg
        elif opt in ("-o", "--output"):
            outputFile = arg

    if inputFile == None or outputFile == None:
        showUsage()
        sys.exit(2)

    convertStrings(keys, inputFile, outputFile)


def showUsage(message):
    if message != None:
        print("")
        print("ERROR:", message)
        print("")

    print("Usage:", os.path.basename(__file__), "-i <input_path> -o <output_path>")
    print("")
    print("Extracts the specified keys from the iOS strings file")
    print("")
    print("OPTIONS:")
    print("    -k  Keys to extract (comma-separated list)")
    print("    -i  Path for the input strings file")
    print("    -o  Path for the output strings file")
    print("")


def convertStrings(keys, inputFile, outputFile):
    print("Extracting", ", ".join(keys), "strings from", inputFile, "to", outputFile)

    strings = readIOSStrings(keys, inputFile)

    outputDir = os.path.dirname(outputFile)
    if not os.path.exists(outputDir):
        os.makedirs(outputDir)
    writeIOSStrings(strings, outputFile)


def getCopyrightLines():
    return [
        "Copyright (c) Meta Platforms, Inc. and affiliates. All rights reserved.",
        "",
        "You are hereby granted a non-exclusive, worldwide, royalty-free license to use,",
        "copy, modify, and distribute this software in source code or binary form for use",
        "in connection with the web services and APIs provided by Facebook.",
        "",
        "As with any software that integrates with the Facebook platform, your use of",
        "this software is subject to the Facebook Platform Policy",
        "[http://developers.facebook.com/policy/]. This copyright notice shall be",
        "included in all copies or substantial portions of the software.",
        "",
        'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR',
        "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS",
        "FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR",
        "COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER",
        "IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN",
        "CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.",
        "",
        "\x40generated",
        "",
    ]


def getIOSCopyright():
    lines = getCopyrightLines()
    copyright = ""
    for line in lines:
        copyright += ("// " + line).strip() + "\n"
    return copyright


def readIOSStrings(keys, inputFile):
    strings = {}
    with codecs.open(inputFile, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith('"'):
                line = rtrim(line.strip(), ";")
                parts = [p.strip() for p in line.split("=", 1)]
                if parts[0].strip('"') in keys:
                    strings[parts[0]] = parts[1]
    return strings


def rtrim(string, suffix):
    if string.endswith(suffix):
        return string[0 : len(string) - len(suffix)]
    return string


def writeIOSStrings(strings, outputFile):
    with codecs.open(outputFile, "w", encoding="utf-8") as f:
        f.write(getIOSCopyright())
        f.write("\n")

        keys = strings.keys()
        keys.sort()
        for key in keys:
            f.write(key + " = " + strings[key] + ";\n")


if __name__ == "__main__":
    main(sys.argv[1:])
