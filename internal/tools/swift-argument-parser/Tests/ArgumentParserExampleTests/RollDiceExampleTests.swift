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
import ArgumentParser
import ArgumentParserTestHelpers

final class RollDiceExampleTests: XCTestCase {
  func testRollDice() throws {
    AssertExecuteCommand(command: "roll --times 6")
  }
  
  func testRollDice_Help() throws {
    let helpText = """
        USAGE: roll [--times <n>] [--sides <m>] [--seed <seed>] [--verbose]

        OPTIONS:
          --times <n>             Rolls the dice <n> times. (default: 1)
          --sides <m>             Rolls an <m>-sided dice. (default: 6)
                Use this option to override the default value of a six-sided die.
          --seed <seed>           A seed to use for repeatable random generation.
          -v, --verbose           Show all roll results.
          -h, --help              Show help information.
        """
    
    AssertExecuteCommand(command: "roll -h", expected: helpText)
    AssertExecuteCommand(command: "roll --help", expected: helpText)
  }
  
  func testRollDice_Fail() throws {
    AssertExecuteCommand(
      command: "roll --times",
      expected: """
            Error: Missing value for '--times <n>'
            Usage: roll [--times <n>] [--sides <m>] [--seed <seed>] [--verbose]
              See 'roll --help' for more information.
            """,
      exitCode: .validationFailure)
    
    AssertExecuteCommand(
      command: "roll --times ZZZ",
      expected: """
            Error: The value 'ZZZ' is invalid for '--times <n>'
            Usage: roll [--times <n>] [--sides <m>] [--seed <seed>] [--verbose]
              See 'roll --help' for more information.
            """,
      exitCode: .validationFailure)
  }
}
