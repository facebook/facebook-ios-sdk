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

fileprivate protocol ParsableArgumentsValidator {
  static func validate(_ type: ParsableArguments.Type) -> ParsableArgumentsValidatorError?
}

enum ValidatorErrorKind {
  case warning
  case failure
}

protocol ParsableArgumentsValidatorError: Error {
  var kind: ValidatorErrorKind { get }
}

struct ParsableArgumentsValidationError: Error, CustomStringConvertible {
  let parsableArgumentsType: ParsableArguments.Type
  let underlayingErrors: [Error]
  var description: String {
    """
    Validation failed for `\(parsableArgumentsType)`:

    \(underlayingErrors.map({"- \($0)"}).joined(separator: "\n"))
    
    
    """
  }
}

extension ParsableArguments {
  static func _validate() throws {
    let validators: [ParsableArgumentsValidator.Type] = [
      PositionalArgumentsValidator.self,
      ParsableArgumentsCodingKeyValidator.self,
      ParsableArgumentsUniqueNamesValidator.self,
      NonsenseFlagsValidator.self,
    ]
    let errors = validators.compactMap { validator in
      validator.validate(self)
    }
    if errors.count > 0 {
      throw ParsableArgumentsValidationError(parsableArgumentsType: self, underlayingErrors: errors)
    }
  }
}

fileprivate extension ArgumentSet {
  var firstPositionalArgument: ArgumentDefinition? {
    content.first(where: { $0.isPositional })
  }
  
  var firstRepeatedPositionalArgument: ArgumentDefinition? {
    content.first(where: { $0.isRepeatingPositional })
  }
}

/// For positional arguments to be valid, there must be at most one
/// positional array argument, and it must be the last positional argument
/// in the argument list. Any other configuration leads to ambiguity in
/// parsing the arguments.
struct PositionalArgumentsValidator: ParsableArgumentsValidator {
  
  struct Error: ParsableArgumentsValidatorError, CustomStringConvertible {
    let repeatedPositionalArgument: String

    let positionalArgumentFollowingRepeated: String

    var description: String {
      "Can't have a positional argument `\(positionalArgumentFollowingRepeated)` following an array of positional arguments `\(repeatedPositionalArgument)`."
    }

    var kind: ValidatorErrorKind { .failure }
  }
  
  static func validate(_ type: ParsableArguments.Type) -> ParsableArgumentsValidatorError? {
    let sets: [ArgumentSet] = Mirror(reflecting: type.init())
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
    
    guard let repeatedPositional = sets.firstIndex(where: { $0.firstRepeatedPositionalArgument != nil })
      else { return nil }
    guard let positionalFollowingRepeated = sets[repeatedPositional...]
      .dropFirst()
      .first(where: { $0.firstPositionalArgument != nil })
    else { return nil }
    
    let firstRepeatedPositionalArgument: ArgumentDefinition = sets[repeatedPositional].firstRepeatedPositionalArgument!
    let positionalFollowingRepeatedArgument: ArgumentDefinition = positionalFollowingRepeated.firstPositionalArgument!
    return Error(
      repeatedPositionalArgument: firstRepeatedPositionalArgument.help.keys.first!.rawValue,
      positionalArgumentFollowingRepeated: positionalFollowingRepeatedArgument.help.keys.first!.rawValue)
  }
}

/// Ensure that all arguments have corresponding coding keys
struct ParsableArgumentsCodingKeyValidator: ParsableArgumentsValidator {
  
  private struct Validator: Decoder {
    let argumentKeys: [String]
    
    enum ValidationResult: Swift.Error {
      case success
      case missingCodingKeys([String])
    }
    
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey : Any] = [:]
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
      fatalError()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
      fatalError()
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
      let missingKeys = argumentKeys.filter { Key(stringValue: $0) == nil }
      if missingKeys.isEmpty {
        throw ValidationResult.success
      } else {
        throw ValidationResult.missingCodingKeys(missingKeys)
      }
    }
  }
  
  /// This error indicates that an option, a flag, or an argument of
  /// a `ParsableArguments` is defined without a corresponding `CodingKey`.
  struct Error: ParsableArgumentsValidatorError, CustomStringConvertible {
    let missingCodingKeys: [String]
    
    var description: String {
      if missingCodingKeys.count > 1 {
        return "Arguments \(missingCodingKeys.map({ "`\($0)`" }).joined(separator: ",")) are defined without corresponding `CodingKey`s."
      } else {
        return "Argument `\(missingCodingKeys[0])` is defined without a corresponding `CodingKey`."
      }
    }
    
    var kind: ValidatorErrorKind {
      .failure
    }
  }
  
  static func validate(_ type: ParsableArguments.Type) -> ParsableArgumentsValidatorError? {
    let argumentKeys: [String] = Mirror(reflecting: type.init())
      .children
      .compactMap { child in
        guard
          let codingKey = child.label,
          let _ = child.value as? ArgumentSetProvider
          else { return nil }
        
        // Property wrappers have underscore-prefixed names
        return String(codingKey.first == "_" ? codingKey.dropFirst(1) : codingKey.dropFirst(0))
    }
    guard argumentKeys.count > 0 else {
      return nil
    }
    do {
      let _ = try type.init(from: Validator(argumentKeys: argumentKeys))
      fatalError("The validator should always throw.")
    } catch let result as Validator.ValidationResult {
      switch result {
      case .missingCodingKeys(let keys):
        return Error(missingCodingKeys: keys)
      case .success:
        return nil
      }
    } catch {
      fatalError("Unexpected validation error: \(error)")
    }
  }
}

/// Ensure argument names are unique within a `ParsableArguments` or `ParsableCommand`.
struct ParsableArgumentsUniqueNamesValidator: ParsableArgumentsValidator {
  struct Error: ParsableArgumentsValidatorError, CustomStringConvertible {
    var duplicateNames: [String: Int] = [:]

    var description: String {
      duplicateNames.map { entry in
        "Multiple (\(entry.value)) `Option` or `Flag` arguments are named \"\(entry.key)\"."
      }.joined(separator: "\n")
    }
    
    var kind: ValidatorErrorKind { .failure }
  }

  static func validate(_ type: ParsableArguments.Type) -> ParsableArgumentsValidatorError? {
    let argSets: [ArgumentSet] = Mirror(reflecting: type.init())
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

    let countedNames: [String: Int] = argSets.reduce(into: [:]) { countedNames, args in
      for name in args.content.flatMap({ $0.names }) {
        countedNames[name.synopsisString, default: 0] += 1
      }
    }

    let duplicateNames = countedNames.filter { $0.value > 1 }
    return duplicateNames.isEmpty
      ? nil
      : Error(duplicateNames: duplicateNames)
  }
}

struct NonsenseFlagsValidator: ParsableArgumentsValidator {
  struct Error: ParsableArgumentsValidatorError, CustomStringConvertible {
    var names: [String]
    
    var description: String {
      """
      One or more Boolean flags is declared with an initial value of `true`.
      This results in the flag always being `true`, no matter whether the user
      specifies the flag or not. To resolve this error, change the default to
      `false`, provide a value for the `inversion:` parameter, or remove the
      `@Flag` property wrapper altogether.

      Affected flag(s):
      \(names.joined(separator: "\n"))
      """
    }
    
    var kind: ValidatorErrorKind { .warning }
  }

  static func validate(_ type: ParsableArguments.Type) -> ParsableArgumentsValidatorError? {
    let argSets: [ArgumentSet] = Mirror(reflecting: type.init())
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

    let nonsenseFlags: [String] = argSets.flatMap { args -> [String] in
      args.compactMap { def in
        if case .nullary = def.update,
           !def.help.isComposite,
           def.help.options.contains(.isOptional),
           def.help.defaultValue == "true"
        {
          return def.unadornedSynopsis
        } else {
          return nil
        }
      }
    }
    
    return nonsenseFlags.isEmpty
      ? nil
      : Error(names: nonsenseFlags)
  }
}
