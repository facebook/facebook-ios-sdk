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

/// A wrapper that represents a command-line option.
///
/// An option is a value that can be specified as a named value on the command
/// line. An option can have a default values specified as part of its
/// declaration; options with optional `Value` types implicitly have `nil` as
/// their default value.
///
///     struct Options: ParsableArguments {
///         @Option(default: "Hello") var greeting: String
///         @Option var name: String
///         @Option var age: Int?
///     }
///
/// `greeting` has a default value of `"Hello"`, which can be overridden by
/// providing a different string as an argument. `age` defaults to `nil`, while
/// `name` is a required argument because it is non-`nil` and has no default
/// value.
@propertyWrapper
public struct Option<Value>: Decodable, ParsedWrapper {
  internal var _parsedValue: Parsed<Value>
  
  internal init(_parsedValue: Parsed<Value>) {
    self._parsedValue = _parsedValue
  }
  
  public init(from decoder: Decoder) throws {
    try self.init(_decoder: decoder)
  }

  /// This initializer works around a quirk of property wrappers, where the
  /// compiler will not see no-argument initializers in extensions. Explicitly
  /// marking this initializer unavailable means that when `Value` conforms to
  /// `ExpressibleByArgument`, that overload will be selected instead.
  ///
  /// ```swift
  /// @Option() var foo: String // Syntax without this initializer
  /// @Option var foo: String   // Syntax with this initializer
  /// ```
  @available(*, unavailable, message: "A default value must be provided unless the value type conforms to ExpressibleByArgument.")
  public init() {
    fatalError("unavailable")
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

extension Option: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "Option(*definition*)"
    }
  }
}

extension Option: DecodableParsedWrapper where Value: Decodable {}

// MARK: Property Wrapper Initializers

extension Option where Value: ExpressibleByArgument {
  /// Creates a property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    name: NameSpecification,
    initial: Value?,
    parsingStrategy: SingleValueParsingStrategy,
    help: ArgumentHelp?,
    completion: CompletionKind?
  ) {
    self.init(_parsedValue: .init { key in
      ArgumentSet(
        key: key,
        kind: .name(key: key, specification: name),
        parsingStrategy: ArgumentDefinition.ParsingStrategy(parsingStrategy),
        parseType: Value.self,
        name: name,
        default: initial, help: help, completion: completion ?? Value.defaultCompletionKind)
     }
    )
  }

  /// Creates a property that reads its value from a labeled option.
  ///
  /// This method is deprecated, with usage split into two other methods below:
  /// - `init(wrappedValue:name:parsing:help:)` for properties with a default value
  /// - `init(name:parsing:help:)` for properties with no default value
  ///
  /// Existing usage of the `default` parameter should be replaced such as follows:
  /// ```diff
  /// -@Option(default: "bar")
  /// -var foo: String
  /// +@Option var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, this option and value are required from the user.
  ///   - parsingStrategy: The behavior to use when looking for this option's
  ///     value.
  ///   - help: Information about how to use this option.
  @available(*, deprecated, message: "Use regular property initialization for default values (`var foo: String = \"bar\"`)")
  public init(
    name: NameSpecification = .long,
    default initial: Value?,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      name: name,
      initial: initial,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: nil)
  }

  /// Creates a property with a default value provided by standard Swift default value syntax.
  ///
  /// This method is called to initialize an `Option` with a default value such as:
  /// ```swift
  /// @Option var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during propery wrapper initialization.
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  public init(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    completion: CompletionKind? = nil,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      name: name,
      initial: wrappedValue,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion)
  }

  /// Creates a property with no default value.
  ///
  /// This method is called to initialize an `Option` without a default value such as:
  /// ```swift
  /// @Option var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  public init(
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) {
    self.init(
      name: name,
      initial: nil,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion)
  }
}

/// The strategy to use when parsing a single value from `@Option` arguments.
///
/// - SeeAlso: `ArrayParsingStrategy``
public enum SingleValueParsingStrategy {
  /// Parse the input after the option. Expect it to be a value.
  ///
  /// For inputs such as `--foo foo`, this would parse `foo` as the
  /// value. However, the input `--foo --bar foo bar` would
  /// result in an error. Even though two values are provided, they don’t
  /// succeed each option. Parsing would result in an error such as the following:
  ///
  ///     Error: Missing value for '--foo <foo>'
  ///     Usage: command [--foo <foo>]
  ///
  /// This is the **default behavior** for `@Option`-wrapped properties.
  case next
  
  /// Parse the next input, even if it could be interpreted as an option or
  /// flag.
  ///
  /// For inputs such as `--foo --bar baz`, if `.unconditional` is used for `foo`,
  /// this would read `--bar` as the value for `foo` and would use `baz` as
  /// the next positional argument.
  ///
  /// This allows reading negative numeric values or capturing flags to be
  /// passed through to another program since the leading hyphen is normally
  /// interpreted as the start of another option.
  ///
  /// - Note: This is usually *not* what users would expect. Use with caution.
  case unconditional
  
  /// Parse the next input, as long as that input can't be interpreted as
  /// an option or flag.
  ///
  /// - Note: This will skip other options and _read ahead_ in the input
  /// to find the next available value. This may be *unexpected* for users.
  /// Use with caution.
  ///
  /// For example, if `--foo` takes a value, then the input `--foo --bar bar`
  /// would be parsed such that the value `bar` is used for `--foo`.
  case scanningForValue
}

/// The strategy to use when parsing multiple values from `@Option` arguments into an
/// array.
public enum ArrayParsingStrategy {
  /// Parse one value per option, joining multiple into an array.
  ///
  /// For example, for a parsable type with a property defined as
  /// `@Option(parsing: .singleValue) var read: [String]`,
  /// the input `--read foo --read bar` would result in the array
  /// `["foo", "bar"]`. The same would be true for the input
  /// `--read=foo --read=bar`.
  ///
  /// - Note: This follows the default behavior of differentiating between values and options. As
  ///     such, the value for this option will be the next value (non-option) in the input. For the
  ///     above example, the input `--read --name Foo Bar` would parse `Foo` into
  ///     `read` (and `Bar` into `name`).
  case singleValue
  
  /// Parse the value immediately after the option while allowing repeating options, joining multiple into an array.
  ///
  /// This is identical to `.singleValue` except that the value will be read
  /// from the input immediately after the option, even if it could be interpreted as an option.
  ///
  /// For example, for a parsable type with a property defined as
  /// `@Option(parsing: .unconditionalSingleValue) var read: [String]`,
  /// the input `--read foo --read bar` would result in the array
  /// `["foo", "bar"]` -- just as it would have been the case for `.singleValue`.
  ///
  /// - Note: However, the input `--read --name Foo Bar --read baz` would result in
  /// `read` being set to the array `["--name", "baz"]`. This is usually *not* what users
  /// would expect. Use with caution.
  case unconditionalSingleValue
  
  /// Parse all values up to the next option.
  ///
  /// For example, for a parsable type with a property defined as
  /// `@Option(parsing: .upToNextOption) var files: [String]`,
  /// the input `--files foo bar` would result in the array
  /// `["foo", "bar"]`.
  ///
  /// Parsing stops as soon as there’s another option in the input such that
  /// `--files foo bar --verbose` would also set `files` to the array
  /// `["foo", "bar"]`.
  case upToNextOption
  
  /// Parse all remaining arguments into an array.
  ///
  /// `.remaining` can be used for capturing pass-through flags. For example, for
  /// a parsable type defined as
  /// `@Option(parsing: .remaining) var passthrough: [String]`:
  ///
  ///     $ cmd --passthrough --foo 1 --bar 2 -xvf
  ///     ------------
  ///     options.passthrough == ["--foo", "1", "--bar", "2", "-xvf"]
  ///
  /// - Note: This will read all inputs following the option without attempting to do any parsing. This is
  /// usually *not* what users would expect. Use with caution.
  ///
  /// Consider using a trailing `@Argument` instead and letting users explicitly turn off parsing
  /// through the terminator `--`. That is the more common approach. For example:
  /// ```swift
  /// struct Options: ParsableArguments {
  ///     @Option var name: String
  ///     @Argument var remainder: [String]
  /// }
  /// ```
  /// would parse the input `--name Foo -- Bar --baz` such that the `remainder`
  /// would hold the value `["Bar", "--baz"]`.
  case remaining
}

extension Option {
  /// Creates a property that reads its value from a labeled option.
  ///
  /// If the property has an `Optional` type, or you provide a non-`nil`
  /// value for the `initial` parameter, specifying this option is not
  /// required.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's
  ///     value.
  ///   - help: Information about how to use this option.
  public init<T: ExpressibleByArgument>(
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Value == T? {
    self.init(_parsedValue: .init { key in
      var arg = ArgumentDefinition(
        key: key,
        kind: .name(key: key, specification: name),
        parsingStrategy: ArgumentDefinition.ParsingStrategy(parsingStrategy),
        parser: T.init(argument:),
        default: nil,
        completion: completion ?? T.defaultCompletionKind)
      arg.help.help = help
      return ArgumentSet(arg.optional)
    })
  }

  @available(*, deprecated, message: """
    Default values don't make sense for optional properties.
    Remove the 'default' parameter if its value is nil,
    or make your property non-optional if it's non-nil.
    """)
  public init<T: ExpressibleByArgument>(
    name: NameSpecification = .long,
    default initial: T?,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil
  ) where Value == T? {
    self.init(_parsedValue: .init { key in
      var arg = ArgumentDefinition(
        key: key,
        kind: .name(key: key, specification: name),
        parsingStrategy: ArgumentDefinition.ParsingStrategy(parsingStrategy),
        parser: T.init(argument:),
        default: initial,
        completion: T.defaultCompletionKind)
      arg.help.help = help
      return ArgumentSet(arg.optional)
    })
  }

  /// Creates a property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    name: NameSpecification,
    initial: Value?,
    parsingStrategy: SingleValueParsingStrategy,
    help: ArgumentHelp?,
    completion: CompletionKind?,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(_parsedValue: .init { key in
      let kind = ArgumentDefinition.Kind.name(key: key, specification: name)
      let help = ArgumentDefinition.Help(options: initial != nil ? .isOptional : [], help: help, key: key)
      var arg = ArgumentDefinition(kind: kind, help: help, completion: completion ?? .default, parsingStrategy: ArgumentDefinition.ParsingStrategy(parsingStrategy), update: .unary({
        (origin, name, valueString, parsedValues) in
        do {
          let transformedValue = try transform(valueString)
          parsedValues.set(transformedValue, forKey: key, inputOrigin: origin)
        } catch {
          throw ParserError.unableToParseValue(origin, name, valueString, forKey: key, originalError: error)
        }
      }), initial: { origin, values in
        if let v = initial {
          values.set(v, forKey: key, inputOrigin: origin)
        }
      })
      arg.help.options.formUnion(ArgumentDefinition.Help.Options(type: Value.self))
      arg.help.defaultValue = initial.map { "\($0)" }
      return ArgumentSet(arg)
      })
  }

  /// Creates a property that reads its value from a labeled option, parsing
  /// with the given closure.
  ///
  /// This method is deprecated, with usage split into two other methods below:
  /// - `init(wrappedValue:name:parsing:help:transform:)` for properties with a default value
  /// - `init(name:parsing:help:transform:)` for properties with no default value
  ///
  /// Existing usage of the `default` parameter should be replaced such as follows:
  /// ```diff
  /// -@Option(default: "bar", transform: baz)
  /// -var foo: String
  /// +@Option(transform: baz)
  /// +var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, this option and value are required from the user.
  ///   - parsingStrategy: The behavior to use when looking for this option's
  ///     value.
  ///   - help: Information about how to use this option.
  ///   - transform: A closure that converts a string into this property's
  ///     type or throws an error.
  @available(*, deprecated, message: "Use regular property initialization for default values (`var foo: String = \"bar\"`)")
  public init(
    name: NameSpecification = .long,
    default initial: Value?,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    transform: @escaping (String) throws -> Value
  ) {
     self.init(
      name: name,
      initial: initial,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: nil,
      transform: transform
    )
  }

  /// Creates a property with a default value provided by standard Swift default value syntax, parsing with the given closure.
  ///
  /// This method is called to initialize an `Option` with a default value such as:
  /// ```swift
  /// @Option(transform: baz)
  /// var foo: String = "bar"
  /// ```
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during property wrapper initialization.
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - transform: A closure that converts a string into this property's type or throws an error.
  public init(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(
      name: name,
      initial: wrappedValue,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion,
      transform: transform
    )
  }

  /// Creates a property with no default value, parsing with the given closure.
  ///
  /// This method is called to initialize an `Option` with no default value such as:
  /// ```swift
  /// @Option(transform: baz)
  /// var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - transform: A closure that converts a string into this property's type or throws an error.
  public init(
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(
      name: name,
      initial: nil,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion,
      transform: transform
    )
  }


  /// Creates an array property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init<Element>(
    initial: [Element]?,
    name: NameSpecification,
    parsingStrategy: ArrayParsingStrategy,
    help: ArgumentHelp?,
    completion: CompletionKind?
  ) where Element: ExpressibleByArgument, Value == Array<Element> {
    self.init(_parsedValue: .init { key in
      // Assign the initial-value setter and help text for default value based on if an initial value was provided.
      let setInitialValue: ArgumentDefinition.Initial
      let helpDefaultValue: String?
      if let initial = initial {
        setInitialValue = { origin, values in
          values.set(initial, forKey: key, inputOrigin: origin)
        }
        helpDefaultValue = !initial.isEmpty ? initial.defaultValueDescription : nil
      } else {
        setInitialValue = { _, _ in }
        helpDefaultValue = nil
      }

      let kind = ArgumentDefinition.Kind.name(key: key, specification: name)
      let help = ArgumentDefinition.Help(options: [.isOptional, .isRepeating], help: help, key: key)
      var arg = ArgumentDefinition(
        kind: kind,
        help: help,
        completion: completion ?? Element.defaultCompletionKind,
        parsingStrategy: ArgumentDefinition.ParsingStrategy(parsingStrategy),
        update: .appendToArray(forType: Element.self, key: key),
        initial: setInitialValue
      )
      arg.help.defaultValue = helpDefaultValue
      return ArgumentSet(arg)
    })
  }

  /// Creates an array property that reads its values from zero or more
  /// labeled options.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property.
  ///   - parsingStrategy: The behavior to use when parsing multiple values
  ///     from the command-line arguments.
  ///   - help: Information about how to use this option.
  public init<Element>(
    wrappedValue: [Element],
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Element: ExpressibleByArgument, Value == Array<Element> {
    self.init(
      initial: wrappedValue,
      name: name,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion
    )
  }

  /// Creates an array property with no default value that reads its values from zero or more labeled options.
  ///
  /// This method is called to initialize an array `Option` with no default value such as:
  /// ```swift
  /// @Option()
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when parsing multiple values from the command-line arguments.
  ///   - help: Information about how to use this option.
  public init<Element>(
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Element: ExpressibleByArgument, Value == Array<Element> {
    self.init(
      initial: nil,
      name: name,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion
    )
  }


  /// Creates an array property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init<Element>(
    initial: [Element]?,
    name: NameSpecification,
    parsingStrategy: ArrayParsingStrategy,
    help: ArgumentHelp?,
    completion: CompletionKind?,
    transform: @escaping (String) throws -> Element
  ) where Value == Array<Element> {
    self.init(_parsedValue: .init { key in
      // Assign the initial-value setter and help text for default value based on if an initial value was provided.
      let setInitialValue: ArgumentDefinition.Initial
      let helpDefaultValue: String?
      if let initial = initial {
        setInitialValue = { origin, values in
          values.set(initial, forKey: key, inputOrigin: origin)
        }
        helpDefaultValue = !initial.isEmpty ? "\(initial)" : nil
      } else {
        setInitialValue = { _, _ in }
        helpDefaultValue = nil
      }

      let kind = ArgumentDefinition.Kind.name(key: key, specification: name)
      let help = ArgumentDefinition.Help(options: [.isOptional, .isRepeating], help: help, key: key)
      var arg = ArgumentDefinition(
        kind: kind,
        help: help,
        completion: completion ?? .default,
        parsingStrategy: ArgumentDefinition.ParsingStrategy(parsingStrategy),
        update: .unary({ (origin, name, valueString, parsedValues) in
          do {
            let transformedElement = try transform(valueString)
            parsedValues.update(forKey: key, inputOrigin: origin, initial: [Element](), closure: {
                  $0.append(transformedElement)
            })
          } catch {
            throw ParserError.unableToParseValue(origin, name, valueString, forKey: key, originalError: error)
          }
        }),
        initial: setInitialValue
      )
      arg.help.defaultValue = helpDefaultValue
      return ArgumentSet(arg)
    })
  }

  /// Creates an array property that reads its values from zero or more
  /// labeled options, parsing with the given closure.
  ///
  /// This property defaults to an empty array if the `initial` parameter
  /// is not specified.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, this option defaults to an empty array.
  ///   - parsingStrategy: The behavior to use when parsing multiple values
  ///     from the command-line arguments.
  ///   - help: Information about how to use this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init<Element>(
    wrappedValue: [Element],
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Element
  ) where Value == Array<Element> {
    self.init(
      initial: wrappedValue,
      name: name,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion,
      transform: transform
    )
  }

  /// Creates an array property with no default value that reads its values from zero or more labeled options, parsing each element with the given closure.
  ///
  /// This method is called to initialize an array `Option` with no default value such as:
  /// ```swift
  /// @Option(transform: baz)
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when parsing multiple values from the command-line arguments.
  ///   - help: Information about how to use this option.
  ///   - transform: A closure that converts a string into this property's element type or throws an error.
  public init<Element>(
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Element
  ) where Value == Array<Element> {
    self.init(
      initial: nil,
      name: name,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion,
      transform: transform
    )
  }
}
