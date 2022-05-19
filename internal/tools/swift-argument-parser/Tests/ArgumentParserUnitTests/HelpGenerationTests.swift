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
@testable import ArgumentParser

final class HelpGenerationTests: XCTestCase {
}

extension URL: ExpressibleByArgument {
  public init?(argument: String) {
    guard let url = URL(string: argument) else {
      return nil
    }
    self = url
  }

  public var defaultValueDescription: String {
    self.absoluteString == FileManager.default.currentDirectoryPath
      ? "current directory"
      : String(describing: self)
  }
}

// MARK: -

extension HelpGenerationTests {
  struct A: ParsableArguments {
    @Option(help: "Your name") var name: String
    @Option(help: "Your title") var title: String?
  }

  func testHelp() {
    AssertHelp(for: A.self, equals: """
            USAGE: a --name <name> [--title <title>]

            OPTIONS:
              --name <name>           Your name
              --title <title>         Your title
              -h, --help              Show help information.

            """)
  }

  struct B: ParsableArguments {
    @Option(help: "Your name") var name: String
    @Option(help: "Your title") var title: String?

    @Argument(help: .hidden) var hiddenName: String?
    @Option(help: .hidden) var hiddenTitle: String?
    @Flag(help: .hidden) var hiddenFlag: Bool = false
  }

  func testHelpWithHidden() {
    AssertHelp(for: B.self, equals: """
            USAGE: b --name <name> [--title <title>]

            OPTIONS:
              --name <name>           Your name
              --title <title>         Your title
              -h, --help              Show help information.

            """)
  }

  struct C: ParsableArguments {
    @Option(help: ArgumentHelp("Your name.",
                               discussion: "Your name is used to greet you and say hello."))
    var name: String
  }

  func testHelpWithDiscussion() {
    AssertHelp(for: C.self, equals: """
            USAGE: c --name <name>

            OPTIONS:
              --name <name>           Your name.
                    Your name is used to greet you and say hello.
              -h, --help              Show help information.

            """)
  }

  struct Issue27: ParsableArguments {
    @Option
    var two: String = "42"
    @Option(help: "The third option")
    var three: String
    @Option(help: "A fourth option")
    var four: String?
    @Option(help: "A fifth option")
    var five: String = ""
  }

  func testHelpWithDefaultValueButNoDiscussion() {
    AssertHelp(for: Issue27.self, equals: """
            USAGE: issue27 [--two <two>] --three <three> [--four <four>] [--five <five>]

            OPTIONS:
              --two <two>             (default: 42)
              --three <three>         The third option
              --four <four>           A fourth option
              --five <five>           A fifth option
              -h, --help              Show help information.

            """)
  }

  enum OptionFlags: String, EnumerableFlag { case optional, required }
  enum Degree {
    case bachelor, master, doctor
    static func degreeTransform(_ string: String) throws -> Degree {
      switch string {
      case "bachelor":
        return .bachelor
      case "master":
        return .master
      case "doctor":
        return .doctor
      default:
        throw ValidationError("Not a valid string for 'Degree'")
      }
    }
  }

  struct D: ParsableCommand {
    @Argument(help: "Your occupation.")
    var occupation: String = "--"

    @Option(help: "Your name.")
    var name: String = "John"

    @Option(default: "Winston", help: "Your middle name.")
    var middleName: String?

    @Option(help: "Your age.")
    var age: Int = 20

    @Option(help: "Whether logging is enabled.")
    var logging: Bool = false

    @Option(parsing: .upToNextOption, help: ArgumentHelp("Your lucky numbers.", valueName: "numbers"))
    var lucky: [Int] = [7, 14]

    @Flag(help: "Vegan diet.")
    var nda: OptionFlags = .optional

    @Option(help: "Your degree.", transform: Degree.degreeTransform)
    var degree: Degree = .bachelor

    @Option(help: "Directory.")
    var directory: URL = URL(string: FileManager.default.currentDirectoryPath)!
  }

  func testHelpWithDefaultValues() {
    AssertHelp(for: D.self, equals: """
            USAGE: d [<occupation>] [--name <name>] [--middle-name <middle-name>] [--age <age>] [--logging <logging>] [--lucky <numbers> ...] [--optional] [--required] [--degree <degree>] [--directory <directory>]

            ARGUMENTS:
              <occupation>            Your occupation. (default: --)

            OPTIONS:
              --name <name>           Your name. (default: John)
              --middle-name <middle-name>
                                      Your middle name. (default: Winston)
              --age <age>             Your age. (default: 20)
              --logging <logging>     Whether logging is enabled. (default: false)
              --lucky <numbers>       Your lucky numbers. (default: 7, 14)
              --optional/--required   Vegan diet. (default: optional)
              --degree <degree>       Your degree. (default: bachelor)
              --directory <directory> Directory. (default: current directory)
              -h, --help              Show help information.

            """)
  }

  struct E: ParsableCommand {
    enum OutputBehaviour: String, EnumerableFlag {
      case stats, count, list

      static func name(for value: OutputBehaviour) -> NameSpecification {
        .shortAndLong
      }
    }

    @Flag(help: "Change the program output")
    var behaviour: OutputBehaviour
  }

  struct F: ParsableCommand {
    enum OutputBehaviour: String, EnumerableFlag {
      case stats, count, list

      static func name(for value: OutputBehaviour) -> NameSpecification {
        .short
      }
    }

    @Flag(help: "Change the program output")
    var behaviour: OutputBehaviour = .list
  }

  struct G: ParsableCommand {
    @Flag(inversion: .prefixedNo, help: "Whether to flag")
    var flag: Bool = false
  }

  func testHelpWithMutuallyExclusiveFlags() {
    AssertHelp(for: E.self, equals: """
               USAGE: e --stats --count --list

               OPTIONS:
                 -s, --stats/-c, --count/-l, --list
                                         Change the program output
                 -h, --help              Show help information.

               """)

    AssertHelp(for: F.self, equals: """
               USAGE: f [-s] [-c] [-l]

               OPTIONS:
                 -s/-c/-l                Change the program output (default: list)
                 -h, --help              Show help information.

               """)

    AssertHelp(for: G.self, equals: """
               USAGE: g [--flag] [--no-flag]

               OPTIONS:
                 --flag/--no-flag        Whether to flag (default: false)
                 -h, --help              Show help information.

               """)
  }

  struct H: ParsableCommand {
    struct CommandWithVeryLongName: ParsableCommand {}
    struct ShortCommand: ParsableCommand {
      static var configuration: CommandConfiguration = CommandConfiguration(abstract: "Test short command name.")
    }
    struct AnotherCommandWithVeryLongName: ParsableCommand {
      static var configuration: CommandConfiguration = CommandConfiguration(abstract: "Test long command name.")
    }
    struct AnotherCommand: ParsableCommand {
      @Option()
      var someOptionWithVeryLongName: String?

      @Option()
      var option: String?

      @Argument(help: "This is an argument with a long name.")
      var argumentWithVeryLongNameAndHelp: String = ""

      @Argument
      var argumentWithVeryLongName: String = ""

      @Argument
      var argument: String = ""
    }
    static var configuration = CommandConfiguration(subcommands: [CommandWithVeryLongName.self,ShortCommand.self,AnotherCommandWithVeryLongName.self,AnotherCommand.self])
  }

  func testHelpWithSubcommands() {
    AssertHelp(for: H.self, equals: """
    USAGE: h <subcommand>

    OPTIONS:
      -h, --help              Show help information.

    SUBCOMMANDS:
      command-with-very-long-name
      short-command           Test short command name.
      another-command-with-very-long-name
                              Test long command name.
      another-command

      See 'h help <subcommand>' for detailed help.
    """)

    AssertHelp(for: H.AnotherCommand.self, root: H.self, equals: """
    USAGE: h another-command [--some-option-with-very-long-name <some-option-with-very-long-name>] [--option <option>] [<argument-with-very-long-name-and-help>] [<argument-with-very-long-name>] [<argument>]

    ARGUMENTS:
      <argument-with-very-long-name-and-help>
                              This is an argument with a long name.
      <argument-with-very-long-name>
      <argument>

    OPTIONS:
      --some-option-with-very-long-name <some-option-with-very-long-name>
      --option <option>
      -h, --help              Show help information.

    """)
  }

  struct I: ParsableCommand {
    static var configuration = CommandConfiguration(version: "1.0.0")
  }

  func testHelpWithVersion() {
    AssertHelp(for: I.self, equals: """
    USAGE: i

    OPTIONS:
      --version               Show the version.
      -h, --help              Show help information.

    """)

  }

  struct J: ParsableCommand {
    static var configuration = CommandConfiguration(discussion: "test")
  }

  func testOverviewButNoAbstractSpacing() {
    let renderedHelp = HelpGenerator(J.self).rendered()
    AssertEqualStringsIgnoringTrailingWhitespace(renderedHelp, """
    OVERVIEW:
    test

    USAGE: j

    OPTIONS:
      -h, --help              Show help information.

    """)
  }

  struct K: ParsableCommand {
    @Argument(help: "A list of paths.")
    var paths: [String] = []

    func validate() throws {
      if paths.isEmpty {
        throw ValidationError("At least one path must be specified.")
      }
    }
  }

  func testHelpWithNoValueForArray() {
    AssertHelp(for: K.self, equals: """
    USAGE: k [<paths> ...]

    ARGUMENTS:
      <paths>                 A list of paths.

    OPTIONS:
      -h, --help              Show help information.

    """)
  }

  struct L: ParsableArguments {
    @Option(
      name: [.short, .customLong("remote"), .customLong("remote"), .short, .customLong("when"), .long, .customLong("other", withSingleDash: true), .customLong("there"), .customShort("x"), .customShort("y")],
      help: "Help Message")
    var time: String?
  }

  func testHelpWithMultipleCustomNames() {
    AssertHelp(for: L.self, equals: """
    USAGE: l [--remote <remote>]

    OPTIONS:
      -t, -x, -y, --remote, --when, --time, -other, --there <remote>
                              Help Message
      -h, --help              Show help information.

    """)
  }

  struct M: ParsableCommand {
  }
  struct N: ParsableCommand {
    static var configuration = CommandConfiguration(subcommands: [M.self], defaultSubcommand: M.self)
  }

  func testHelpWithDefaultCommand() {
    AssertHelp(for: N.self, equals: """
    USAGE: n <subcommand>

    OPTIONS:
      -h, --help              Show help information.

    SUBCOMMANDS:
      m (default)

      See 'n help <subcommand>' for detailed help.
    """)
  }

  enum O: String, ExpressibleByArgument {
    case small
    case medium
    case large

    init?(argument: String) {
      guard let result = Self(rawValue: argument) else {
        return nil
      }
      self = result
    }
  }
  struct P: ParsableArguments {
    @Option(name: [.short], help: "Help Message")
    var o: [O] = [.small, .medium]

    @Argument(help: "Help Message")
    var remainder: [O] = [.large]
  }

  func testHelpWithDefaultValueForArray() {
    AssertHelp(for: P.self, equals: """
    USAGE: p [-o <o> ...] [<remainder> ...]

    ARGUMENTS:
      <remainder>             Help Message (default: large)

    OPTIONS:
      -o <o>                  Help Message (default: small, medium)
      -h, --help              Show help information.

    """)
  }
}
