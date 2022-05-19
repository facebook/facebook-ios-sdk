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

/// A type that can be executed as part of a nested tree of commands.
public protocol ParsableCommand: ParsableArguments {
  /// Configuration for this command, including subcommands and custom help
  /// text.
  static var configuration: CommandConfiguration { get }
  
  /// *For internal use only:* The name for the command on the command line.
  ///
  /// This is generated from the configuration, if given, or from the type
  /// name if not. This is a customization point so that a WrappedParsable
  /// can pass through the wrapped type's name.
  static var _commandName: String { get }
  
  /// Runs this command.
  ///
  /// After implementing this method, you can run your command-line
  /// application by calling the static `main()` method on the root type.
  /// This method has a default implementation that prints help text
  /// for this command.
  mutating func run() throws
}

extension ParsableCommand {
  public static var _commandName: String {
    configuration.commandName ??
      String(describing: Self.self).convertedToSnakeCase(separator: "-")
  }
  
  public static var configuration: CommandConfiguration {
    CommandConfiguration()
  }
  
  public mutating func run() throws {
    throw CleanExit.helpRequest(self)
  }
}

// MARK: - API

extension ParsableCommand {
  /// Parses an instance of this type, or one of its subcommands, from
  /// command-line arguments.
  ///
  /// - Parameter arguments: An array of arguments to use for parsing. If
  ///   `arguments` is `nil`, this uses the program's command-line arguments.
  /// - Returns: A new instance of this type, one of its subcommands, or a
  ///   command type internal to the `ArgumentParser` library.
  public static func parseAsRoot(
    _ arguments: [String]? = nil
  ) throws -> ParsableCommand {
    var parser = CommandParser(self)
    let arguments = arguments ?? Array(CommandLine.arguments.dropFirst())
    return try parser.parse(arguments: arguments).get()
  }
  
  /// Returns the text of the help screen for the given subcommand of this
  /// command.
  ///
  /// - Parameters:
  ///   - subcommand: The subcommand to generate the help screen for.
  ///     `subcommand` must be declared in the subcommand tree of this
  ///     command.
  ///   - columns: The column width to use when wrapping long line in the
  ///     help screen. If `columns` is `nil`, uses the current terminal
  ///     width, or a default value of `80` if the terminal width is not
  ///     available.
  public static func helpMessage(
    for subcommand: ParsableCommand.Type,
    columns: Int? = nil
  ) -> String { 
    let stack = CommandParser(self).commandStack(for: subcommand)
    return HelpGenerator(commandStack: stack).rendered(screenWidth: columns)
  }

  /// Parses an instance of this type, or one of its subcommands, from
  /// the given arguments and calls its `run()` method, exiting with a
  /// relevant error message if necessary.
  ///
  /// - Parameter arguments: An array of arguments to use for parsing. If
  ///   `arguments` is `nil`, this uses the program's command-line arguments.
  public static func main(_ arguments: [String]?) {
    do {
      var command = try parseAsRoot(arguments)
      try command.run()
    } catch {
      exit(withError: error)
    }
  }

  /// Parses an instance of this type, or one of its subcommands, from
  /// command-line arguments and calls its `run()` method, exiting with a
  /// relevant error message if necessary.
  public static func main() {
    self.main(nil)
  }
}
