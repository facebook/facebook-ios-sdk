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

struct HelpCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "help",
    abstract: "Show subcommand help information.")
  
  @Argument var subcommands: [String] = []
  
  private(set) var commandStack: [ParsableCommand.Type] = []
  
  init() {}
  
  mutating func run() throws {
    throw CommandError(commandStack: commandStack, parserError: .helpRequested)
  }
  
  mutating func buildCommandStack(with parser: CommandParser) throws {
    commandStack = parser.commandStack(for: subcommands)
  }
  
  func generateHelp() -> String {
    return HelpGenerator(commandStack: commandStack).rendered()
  }
  
  enum CodingKeys: CodingKey {
    case subcommands
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self._subcommands = Argument(_parsedValue: .value(try container.decode([String].self, forKey: .subcommands)))
  }
  
  init(commandStack: [ParsableCommand.Type]) {
    self.commandStack = commandStack
    self._subcommands = Argument(_parsedValue: .value(commandStack.map { $0._commandName }))
  }
}
