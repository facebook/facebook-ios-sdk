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

#if canImport(Glibc)
import Glibc
let _exit: (Int32) -> Never = Glibc.exit
#elseif canImport(Darwin)
import Darwin
let _exit: (Int32) -> Never = Darwin.exit
#elseif canImport(MSVCRT)
import MSVCRT
let _exit: (Int32) -> Never = ucrt._exit
#endif

/// A type that can be parsed from a program's command-line arguments.
///
/// When you implement a `ParsableArguments` type, all properties must be declared with
/// one of the four property wrappers provided by the `ArgumentParser` library.
public protocol ParsableArguments: Decodable {
  /// Creates an instance of this parsable type using the definitions
  /// given by each property's wrapper.
  init()
  
  /// Validates the properties of the instance after parsing.
  ///
  /// Implement this method to perform validation or other processing after
  /// creating a new instance from command-line arguments.
  mutating func validate() throws
  
  /// The label to use for "Error: ..." messages from this type. (experimental)
  static var _errorLabel: String { get }
}

/// A type that provides the `ParsableCommand` interface to a `ParsableArguments` type.
struct _WrappedParsableCommand<P: ParsableArguments>: ParsableCommand {
  static var _commandName: String {
    let name = String(describing: P.self).convertedToSnakeCase()
    
    // If the type is named something like "TransformOptions", we only want
    // to use "transform" as the command name.
    if let optionsRange = name.range(of: "_options"),
      optionsRange.upperBound == name.endIndex
    {
      return String(name[..<optionsRange.lowerBound])
    } else {
      return name
    }
  }
  
  @OptionGroup var options: P
}

struct StandardError: TextOutputStream {
  mutating func write(_ string: String) {
    for byte in string.utf8 { putc(numericCast(byte), stderr) }
  }
}

var standardError = StandardError()

extension ParsableArguments {
  public mutating func validate() throws {}
  
  /// This type as-is if it conforms to `ParsableCommand`, or wrapped in the
  /// `ParsableCommand` wrapper if not.
  internal static var asCommand: ParsableCommand.Type {
    self as? ParsableCommand.Type ?? _WrappedParsableCommand<Self>.self
  }
  
  public static var _errorLabel: String {
    "Error"
  }
}

// MARK: - API

extension ParsableArguments {
  /// Parses a new instance of this type from command-line arguments.
  ///
  /// - Parameter arguments: An array of arguments to use for parsing. If
  ///   `arguments` is `nil`, this uses the program's command-line arguments.
  /// - Returns: A new instance of this type.
  public static func parse(
    _ arguments: [String]? = nil
  ) throws -> Self {
    // Parse the command and unwrap the result if necessary.
    switch try self.asCommand.parseAsRoot(arguments) {
    case is HelpCommand:
      throw ParserError.helpRequested
    case let result as _WrappedParsableCommand<Self>:
      return result.options
    case var result as Self:
      do {
        try result.validate()
      } catch {
        throw ParserError.userValidationError(error)
      }
      return result
    default:
      // TODO: this should be a "wrong command" message
      throw ParserError.invalidState
    }
  }
  
  /// Returns a brief message for the given error.
  ///
  /// - Parameter error: An error to generate a message for.
  /// - Returns: A message that can be displayed to the user.
  public static func message(
    for error: Error
  ) -> String {
    MessageInfo(error: error, type: self).message
  }
  
  /// Returns a full message for the given error, including usage information,
  /// if appropriate.
  ///
  /// - Parameter error: An error to generate a message for.
  /// - Returns: A message that can be displayed to the user.
  public static func fullMessage(
    for error: Error
  ) -> String {
    MessageInfo(error: error, type: self).fullText(for: self)
  }
  
  /// Returns the text of the help screen for this type.
  ///
  /// - Parameter columns: The column width to use when wrapping long lines in
  ///   the help screen. If `columns` is `nil`, uses the current terminal width,
  ///   or a default value of `80` if the terminal width is not available.
  /// - Returns: The full help screen for this type.
  public static func helpMessage(columns: Int? = nil) -> String {
    HelpGenerator(self).rendered(screenWidth: columns)
  }

  /// Returns the exit code for the given error.
  ///
  /// The returned code is the same exit code that is used if `error` is passed
  /// to `exit(withError:)`.
  ///
  /// - Parameter error: An error to generate an exit code for.
  /// - Returns: The exit code for `error`.
  public static func exitCode(
    for error: Error
  ) -> ExitCode {
    MessageInfo(error: error, type: self).exitCode
  }
    
  /// Returns a shell completion script for the specified shell.
  ///
  /// - Parameter shell: The shell to generate a completion script for.
  /// - Returns: The completion script for `shell`.
  public static func completionScript(for shell: CompletionShell) -> String {
    let completionsGenerator = try! CompletionsGenerator(command: self.asCommand, shell: shell)
    return completionsGenerator.generateCompletionScript()
  }

  /// Terminates execution with a message and exit code that is appropriate
  /// for the given error.
  ///
  /// If the `error` parameter is `nil`, this method prints nothing and exits
  /// with code `EXIT_SUCCESS`. If `error` represents a help request or
  /// another `CleanExit` error, this method prints help information and
  /// exits with code `EXIT_SUCCESS`. Otherwise, this method prints a relevant
  /// error message and exits with code `EX_USAGE` or `EXIT_FAILURE`.
  ///
  /// - Parameter error: The error to use when exiting, if any.
  public static func exit(
    withError error: Error? = nil
  ) -> Never {
    guard let error = error else {
      _exit(ExitCode.success.rawValue)
    }
    
    let messageInfo = MessageInfo(error: error, type: self)
    let fullText = messageInfo.fullText(for: self)
    if !fullText.isEmpty {
      if messageInfo.shouldExitCleanly {
        print(fullText)
      } else {
        print(fullText, to: &standardError)
      }
    }
    _exit(messageInfo.exitCode.rawValue)
  }
  
  /// Parses a new instance of this type from command-line arguments or exits
  /// with a relevant message.
  ///
  /// - Parameter arguments: An array of arguments to use for parsing. If
  ///   `arguments` is `nil`, this uses the program's command-line arguments.
  public static func parseOrExit(
    _ arguments: [String]? = nil
  ) -> Self {
    do {
      return try parse(arguments)
    } catch {
      exit(withError: error)
    }
  }
}

protocol ArgumentSetProvider {
  func argumentSet(for key: InputKey) -> ArgumentSet
}

extension ArgumentSet {
  init(_ type: ParsableArguments.Type) {
    
    #if DEBUG
    do {
      try type._validate()
    } catch {
      assertionFailure("\(error)")
    }
    #endif
    
    let a: [ArgumentSet] = Mirror(reflecting: type.init())
      .children
      .compactMap { child in
        guard
          var codingKey = child.label,
          let parsed = child.value as? ArgumentSetProvider
          else { return nil }
        
        // Property wrappers have underscore-prefixed names
        codingKey = String(codingKey.first == "_" ? codingKey.dropFirst(1) : codingKey.dropFirst(0))
        
        let key = InputKey(rawValue: codingKey)
        return parsed.argumentSet(for: key)
    }
    self.init(sets: a)
  }
}

/// The fatal error message to display when someone accesses a
/// `ParsableArguments` type after initializing it directly.
internal let directlyInitializedError = """

  --------------------------------------------------------------------
  Can't read a value from a parsable argument definition.

  This error indicates that a property declared with an `@Argument`,
  `@Option`, `@Flag`, or `@OptionGroup` property wrapper was neither
  initialized to a value nor decoded from command-line arguments.

  To get a valid value, either call one of the static parsing methods
  (`parse`, `parseAsRoot`, or `main`) or define an initializer that
  initializes _every_ property of your parsable type.
  --------------------------------------------------------------------

  """
