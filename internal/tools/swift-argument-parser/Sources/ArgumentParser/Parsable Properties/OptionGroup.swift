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

/// A wrapper that transparently includes a parsable type.
///
/// Use an option group to include a group of options, flags, or arguments
/// declared in a parsable type.
///
///     struct GlobalOptions: ParsableArguments {
///         @Flag(name: .shortAndLong)
///         var verbose: Bool
///
///         @Argument var values: [Int]
///     }
///
///     struct Options: ParsableArguments {
///         @Option var name: String
///         @OptionGroup var globals: GlobalOptions
///     }
///
/// The flag and positional arguments declared as part of `GlobalOptions` are
/// included when parsing `Options`.
@propertyWrapper
public struct OptionGroup<Value: ParsableArguments>: Decodable, ParsedWrapper {
  internal var _parsedValue: Parsed<Value>
  
  internal init(_parsedValue: Parsed<Value>) {
    self._parsedValue = _parsedValue
  }
  
  public init(from decoder: Decoder) throws {
    if let d = decoder as? SingleValueDecoder,
      let value = try? d.previousValue(Value.self)
    {
      self.init(_parsedValue: .value(value))
    } else {
      try self.init(_decoder: decoder)
      if let d = decoder as? SingleValueDecoder {
        d.saveValue(wrappedValue)
      }
    }
    
    do {
      try wrappedValue.validate()
    } catch {
      throw ParserError.userValidationError(error)
    }
  }

  /// Creates a property that represents another parsable type.
  public init() {
    self.init(_parsedValue: .init { _ in
      ArgumentSet(Value.self)
    })
  }

  /// The value presented by this property wrapper.
  public var wrappedValue: Value {
    get {
      switch _parsedValue {
      case .value(let v):
        return v
      case .definition:
        fatalError(directlyInitializedError)
      }
    }
    set {
      _parsedValue = .value(newValue)
    }
  }
}

extension OptionGroup: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "OptionGroup(*definition*)"
    }
  }
}
