#!/usr/bin/env python3
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

import codecs
import getopt
import os
import re
import sys
import xml.dom.minidom


def main(argv):
    inputFile = None
    additionalInputFile = None
    outputFile = None
    try:
        opts, args = getopt.getopt(
            argv, "hi:a:o:", ["input=", "additional-input=", "output="]
        )
    except getopt.GetoptError:
        showUsage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-h":
            showUsage()
            sys.exit()
        elif opt in ("-i", "--input"):
            inputFile = arg
        elif opt in ("-a", "--additional-input"):
            additionalInputFile = arg
        elif opt in ("-o", "--output"):
            outputFile = arg

    if inputFile == None or outputFile == None:
        showUsage()
        sys.exit(2)

    convertStrings(inputFile, additionalInputFile, outputFile)


def showUsage(message):
    if message != None:
        print("")
        print("ERROR:", message)
        print("")

    print(
        "Usage:",
        os.path.basename(__file__),
        "-i <input_path> [-a <additional_input_file>] -o <output_path>",
    )
    print("")
    print("Exports Android strings to iOS strings.")
    print("")
    print("OPTIONS:")
    print("    -i  Path for the input strings.xml file")
    print("    -a  Path for an additional input strings file")
    print("    -o  Path for the output strings file")
    print("")


def convertStrings(inputFile, additionalInputFile, outputFile):
    if not os.path.exists(additionalInputFile):
        additionalInputFile = None
    if additionalInputFile == None:
        print("Converting string from", inputFile, "to", outputFile)
    else:
        print(
            "Converting string from",
            inputFile,
            "and",
            additionalInputFile,
            "to",
            outputFile,
        )

    strings = readStrings(inputFile)
    strings.update(readStrings(additionalInputFile))

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


def readStrings(inputFile):
    if inputFile == None:
        return {}
    elif inputFile.endswith(".xml"):
        return readAndroidStrings(inputFile)
    elif inputFile.endswith(".strings"):
        return readIOSStrings(inputFile)
    else:
        showUsage("input must be either a .xml or .strings file")
        sys.exit(2)


def readAndroidStrings(inputFile):
    strings = {}
    inputXML = xml.dom.minidom.parse(inputFile)
    nodes = inputXML.documentElement.getElementsByTagName("string")
    for node in nodes:
        strings[convertValue(node.getAttribute("name"))] = convertNodes(node.childNodes)
    return strings


def readIOSStrings(inputFile):
    strings = {}
    with codecs.open(inputFile, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith('"'):
                line = rtrim(line.strip(), ";")
                parts = line.split("=", 1)
                strings[parts[0].strip()] = parts[1].strip()
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


def convertNodes(nodes):
    s = ""
    for node in nodes:
        s += node.toxml()
    return convertValue(s)


def convertValue(value):
    value = (
        value.strip()
        .replace("\u2026", "\\U2026")
        .replace("$s", "$@")
        .replace("\\'", "'")
        .replace('"', '\\"')
        .replace("<![CDATA[", "")
        .replace("]]>", "")
        .replace("\&quot;", "'")
        .replace("&quot;", '\\"')
        .replace("&lt;a href=", '<a href=\\"')
        .replace("@&gt;", '@\\">')
        .replace("&lt;/a&gt;", "</a>")
        .replace("</xliff:g>", "")
    )

    value = re.sub("<xliff:g(.*?)>", "", value)

    return '"' + value + '"'


if __name__ == "__main__":
    main(sys.argv[1:])
