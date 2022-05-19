//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import ArgumentParser
import ArgumentParserTestHelpers

final class HelpTests: XCTestCase {
}

func getErrorText<T: ParsableArguments>(_: T.Type, _ arguments: [String]) -> String {
  do {
    _ = try T.parse(arguments)
    XCTFail("Didn't generate a help error")
    return ""
  } catch {
    return T.message(for: error)
  }
}

func getErrorText<T: ParsableCommand>(_: T.Type, _ arguments: [String]) -> String {
  do {
    let command = try T.parseAsRoot(arguments)
    if let helpCommand = command as? HelpCommand {
      return helpCommand.generateHelp()
    } else {
      XCTFail("Didn't generate a help error")
      return ""
    }
  } catch {
    return T.message(for: error)
  }
}

extension HelpTests {
  func testGlobalHelp() throws {
    XCTAssertEqual(
      getErrorText(Package.self, ["help"]).trimmingLines(),
      """
                USAGE: package <subcommand>

                OPTIONS:
                  -h, --help              Show help information.

                SUBCOMMANDS:
                  clean
                  config
                  describe
                  generate-xcodeproj

                  See 'package help <subcommand>' for detailed help.
                """.trimmingLines())
  }

  func testGlobalHelp_messageForCleanExit_helpRequest() throws {
    XCTAssertEqual(
      Package.message(for: CleanExit.helpRequest()).trimmingLines(),
      """
                USAGE: package <subcommand>

                OPTIONS:
                  -h, --help              Show help information.

                SUBCOMMANDS:
                  clean
                  config
                  describe
                  generate-xcodeproj

                  See 'package help <subcommand>' for detailed help.
                """.trimmingLines()
    )
  }

  func testGlobalHelp_messageForCleanExit_message() throws {
    let expectedMessage = "Failure"
    XCTAssertEqual(
      Package.message(for: CleanExit.message(expectedMessage)).trimmingLines(),
      expectedMessage
    )
  }

  func testConfigHelp() throws {
    XCTAssertEqual(
      getErrorText(Package.self, ["help", "config"]).trimmingLines(),
      """
                USAGE: package config <subcommand>

                OPTIONS:
                  -h, --help              Show help information.

                SUBCOMMANDS:
                  get-mirror
                  set-mirror
                  unset-mirror

                  See 'package help config <subcommand>' for detailed help.
                """.trimmingLines())
  }

  func testGetMirrorHelp() throws {
    HelpGenerator._screenWidthOverride = 80
    defer { HelpGenerator._screenWidthOverride = nil }

    XCTAssertEqual(
      getErrorText(Package.self, ["help", "config",  "get-mirror"]).trimmingLines(),
      """
                USAGE: package config get-mirror <options>

                OPTIONS:
                  --build-path <build-path>
                                          Specify build/cache directory (default: ./.build)
                  -c, --configuration <configuration>
                                          Build with configuration (default: debug)
                  --enable-automatic-resolution/--disable-automatic-resolution
                                          Use automatic resolution if Package.resolved file is
                                          out-of-date (default: true)
                  --enable-index-store/--disable-index-store
                                          Use indexing-while-building feature (default: true)
                  --enable-package-manifest-caching/--disable-package-manifest-caching
                                          Cache Package.swift manifests (default: true)
                  --enable-prefetching/--disable-prefetching
                                          (default: true)
                  --enable-sandbox/--disable-sandbox
                                          Use sandbox when executing subprocesses (default:
                                          true)
                  --enable-pubgrub-resolver/--disable-pubgrub-resolver
                                          [Experimental] Enable the new Pubgrub dependency
                                          resolver (default: false)
                  --static-swift-stdlib/--no-static-swift-stdlib
                                          Link Swift stdlib statically (default: false)
                  --package-path <package-path>
                                          Change working directory before any other operation
                                          (default: .)
                  --sanitize              Turn on runtime checks for erroneous behavior
                  --skip-update           Skip updating dependencies from their remote during a
                                          resolution
                  -v, --verbose           Increase verbosity of informational output
                  -Xcc <c-compiler-flag>  Pass flag through to all C compiler invocations
                  -Xcxx <cxx-compiler-flag>
                                          Pass flag through to all C++ compiler invocations
                  -Xlinker <linker-flag>  Pass flag through to all linker invocations
                  -Xswiftc <swift-compiler-flag>
                                          Pass flag through to all Swift compiler invocations
                  --package-url <package-url>
                                          The package dependency URL
                  -h, --help              Show help information.

                """.trimmingLines())
  }
}

struct Simple: ParsableArguments {
  @Flag var verbose: Bool = false
  @Option() var min: Int?
  @Argument() var max: Int

  static var helpText = """
        USAGE: simple [--verbose] [--min <min>] <max>

        ARGUMENTS:
          <max>

        OPTIONS:
          --verbose
          --min <min>
          -h, --help              Show help information.

        """.trimmingLines()
}

extension HelpTests {
  func testSimpleHelp() throws {
    XCTAssertEqual(
      getErrorText(Simple.self, ["--help"]).trimmingLines(),
      Simple.helpText)
    XCTAssertEqual(
      getErrorText(Simple.self, ["-h"]).trimmingLines(),
      Simple.helpText)
  }
}

struct CustomHelp: ParsableCommand {
  static let configuration = CommandConfiguration(
    helpNames: [.customShort("?"), .customLong("show-help")]
  )
}

extension HelpTests {
  func testCustomHelpNames() {
    let names = CustomHelp.getHelpNames()
    XCTAssertEqual(names, [.short("?"), .long("show-help")])
  }
}

struct NoHelp: ParsableCommand {
  static let configuration = CommandConfiguration(
    helpNames: []
  )

  @Option(help: "How many florps?") var count: Int
}

extension HelpTests {
  func testNoHelpNames() {
    let names = NoHelp.getHelpNames()
    XCTAssertEqual(names, [])

    XCTAssertEqual(
      NoHelp.message(for: CleanExit.helpRequest()).trimmingLines(),
      """
            USAGE: no-help --count <count>

            OPTIONS:
              --count <count>         How many florps?

            """)
  }
}
