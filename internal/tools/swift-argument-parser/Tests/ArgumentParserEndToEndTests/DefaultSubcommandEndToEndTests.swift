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
import ArgumentParserTestHelpers
import ArgumentParser

final class DefaultSubcommandEndToEndTests: XCTestCase {
}

// MARK: -

private struct Main: ParsableCommand {
  static var configuration = CommandConfiguration(
    subcommands: [Default.self, Foo.self, Bar.self],
    defaultSubcommand: Default.self
  )
}

private struct Default: ParsableCommand {
  enum Mode: String, CaseIterable, ExpressibleByArgument {
    case foo, bar, baz
  }

  @Option var mode: Mode = .foo
}

private struct Foo: ParsableCommand {}
private struct Bar: ParsableCommand {}

extension DefaultSubcommandEndToEndTests {
  func testDefaultSubcommand() {
    AssertParseCommand(Main.self, Default.self, []) { def in
      XCTAssertEqual(.foo, def.mode)
    }

    AssertParseCommand(Main.self, Default.self, ["--mode=bar"]) { def in
      XCTAssertEqual(.bar, def.mode)
    }

    AssertParseCommand(Main.self, Default.self, ["--mode", "bar"]) { def in
      XCTAssertEqual(.bar, def.mode)
    }

    AssertParseCommand(Main.self, Default.self, ["--mode", "baz"]) { def in
      XCTAssertEqual(.baz, def.mode)
    }
  }

  func testNonDefaultSubcommand() {
    AssertParseCommand(Main.self, Foo.self, ["foo"]) { _ in }
    AssertParseCommand(Main.self, Bar.self, ["bar"]) { _ in }

    AssertParseCommand(Main.self, Default.self, ["default", "--mode", "bar"]) { def in
      XCTAssertEqual(.bar, def.mode)
    }
  }

  func testParsingFailure() {
    XCTAssertThrowsError(try Main.parseAsRoot(["--mode", "qux"]))
    XCTAssertThrowsError(try Main.parseAsRoot(["qux"]))
  }
}
