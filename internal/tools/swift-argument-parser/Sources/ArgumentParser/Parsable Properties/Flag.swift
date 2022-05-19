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

/// A wrapper that represents a command-line flag.
///
/// A flag is a defaulted Boolean or integer value that can be changed by
/// specifying the flag on the command line. For example:
///
///     struct Options: ParsableArguments {
///         @Flag var verbose: Bool
///     }
///
/// `verbose` has a default value of `false`, but becomes `true` if `--verbose`
/// is provided on the command line.
///
/// A flag can have a value that is a `Bool`, an `Int`, or any `EnumerableFlag`
/// type. When using an `EnumerableFlag` type as a flag, the individual cases
/// form the flags that are used on the command line.
///
///     struct Options {
///         enum Operation: EnumerableFlag {
///             case add
///             case multiply
///         }
///
///         @Flag var operation: Operation
///     }
///
///     // usage: command --add
///     //    or: command --multiply
@propertyWrapper
public struct Flag<Value>: Decodable, ParsedWrapper {
  internal var _parsedValue: Parsed<Value>
  
  internal init(_parsedValue: Parsed<Value>) {
    self._parsedValue = _parsedValue
  }
  
  public init(from decoder: Decoder) throws {
    try self.init(_decoder: decoder)
  }

  /// This initializer works around a quirk of property wrappers, where the
  /// compiler will not see no-argument initializers in extensions. Explicitly
  /// marking this initializer unavailable means that when `Value` is a type
  /// supported by `Flag` like `Bool` or `EnumerableFlag`, the appropriate
  /// overload will be selected instead.
  ///
  /// ```swift
  /// @Flag() var flag: Bool  // Syntax without this initializer
  /// @Flag var flag: Bool    // Syntax with this initializer
  /// ```
  @available(*, unavailable, message: "A default value must be provided unless the value type is supported by Flag.")
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

extension Flag: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "Flag(*definition*)"
    }
  }
}

extension Flag: DecodableParsedWrapper where Value: Decodable {}

/// The options for converting a Boolean flag into a `true`/`false` pair.
public enum FlagInversion {
  /// Adds a matching flag with a `no-` prefix to represent `false`.
  ///
  /// For example, the `shouldRender` property in this declaration is set to
  /// `true` when a user provides `--render` and to `false` when the user
  /// provides `--no-render`:
  ///
  ///     @Flag(name: .customLong("render"), inversion: .prefixedNo)
  ///     var shouldRender: Bool
  case prefixedNo
  
  /// Uses matching flags with `enable-` and `disable-` prefixes.
  ///
  /// For example, the `extraOutput` property in this declaration is set to
  /// `true` when a user provides `--enable-extra-output` and to `false` when
  /// the user provides `--disable-extra-output`:
  ///
  ///     @Flag(inversion: .prefixedEnableDisable)
  ///     var extraOutput: Bool
  case prefixedEnableDisable
}

/// The options for treating enumeration-based flags as exclusive.
public enum FlagExclusivity {
  /// Only one of the enumeration cases may be provided.
  case exclusive
  
  /// The first enumeration case that is provided is used.
  case chooseFirst
  
  /// The last enumeration case that is provided is used.
  case chooseLast
}

extension Flag where Value == Optional<Bool> {
  /// Creates a Boolean property that reads its value from the presence of
  /// one or more inverted flags.
  ///
  /// Use this initializer to create an optional Boolean flag with an on/off
  /// pair. With the following declaration, for example, the user can specify
  /// either `--use-https` or `--no-use-https` to set the `useHTTPS` flag to
  /// `true` or `false`, respectively. If neither is specified, the resulting
  /// flag value would be `nil`.
  ///
  ///     @Flag(inversion: .prefixedNo)
  ///     var useHTTPS: Bool?
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - inversion: The method for converting this flags name into an on/off
  ///     pair.
  ///   - exclusivity: The behavior to use when an on/off pair of flags is
  ///     specified.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    inversion: FlagInversion,
    exclusivity: FlagExclusivity = .chooseLast,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      .flag(key: key, name: name, default: nil, inversion: inversion, exclusivity: exclusivity, help: help)
    })
  }
}

extension Flag where Value == Bool {
  /// Creates a Boolean property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    name: NameSpecification,
    initial: Bool?,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      .flag(key: key, name: name, default: initial, help: help)
    })
  }

  /// Creates a Boolean property that reads its value from the presence of a
  /// flag.
  ///
  /// This property defaults to a value of `false`.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  @available(*, deprecated, message: "Provide an explicit default value of `false` for this flag (`@Flag var foo: Bool = false`)")
  public init(
    name: NameSpecification = .long,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      name: name,
      initial: false,
      help: help
    )
  }

  /// Creates a Boolean property with default value provided by standard Swift default value syntax that reads its value from the presence of a flag.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during propery wrapper initialization.
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  public init(
    wrappedValue: Bool,
    name: NameSpecification = .long,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      name: name,
      initial: wrappedValue,
      help: help
    )
  }

  /// Creates a property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    name: NameSpecification,
    initial: Bool?,
    inversion: FlagInversion,
    exclusivity: FlagExclusivity,
    help: ArgumentHelp?
  ) {
    self.init(_parsedValue: .init { key in
      .flag(key: key, name: name, default: initial, inversion: inversion, exclusivity: exclusivity, help: help)
      })
  }

  /// Creates a Boolean property that reads its value from the presence of
  /// one or more inverted flags.
  ///
  /// /// This method is deprecated, with usage split into two other methods below:
  /// - `init(wrappedValue:name:inversion:exclusivity:help:)` for properties with a default value
  /// - `init(name:inversion:exclusivity:help:)` for properties with no default value
  ///
  /// Existing usage of the `default` parameter should be replaced such as follows:
  /// ```diff
  /// -@Flag(default: true)
  /// -var foo: Bool
  /// +@Flag var foo: Bool = true
  /// ```
  ///
  /// Use this initializer to create a Boolean flag with an on/off pair. With
  /// the following declaration, for example, the user can specify either
  /// `--use-https` or `--no-use-https` to set the `useHTTPS` flag to `true`
  /// or `false`, respectively.
  ///
  ///     @Flag(inversion: .prefixedNo)
  ///     var useHTTPS: Bool
  ///
  /// To customize the names of the two states further, define a
  /// `CaseIterable` enumeration with a case for each state, and use that
  /// as the type for your flag. In this case, the user can specify either
  /// `--use-production-server` or `--use-development-server` to set the
  /// flag's value.
  ///
  ///     enum ServerChoice {
  ///         case useProductionServer
  ///         case useDevelopmentServer
  ///     }
  ///
  ///     @Flag var serverChoice: ServerChoice
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, one of the flags declared by this `@Flag` attribute is required
  ///     from the user.
  ///   - inversion: The method for converting this flag's name into an on/off
  ///     pair.
  ///   - exclusivity: The behavior to use when an on/off pair of flags is
  ///     specified.
  ///   - help: Information about how to use this flag.
  @available(*, deprecated, message: "Use regular property initialization for default values (`var foo: Bool = false`)")
  public init(
    name: NameSpecification = .long,
    default initial: Bool?,
    inversion: FlagInversion,
    exclusivity: FlagExclusivity = .chooseLast,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      name: name,
      initial: initial,
      inversion: inversion,
      exclusivity: exclusivity,
      help: help
    )
  }

  /// Creates a Boolean property with default value provided by standard Swift default value syntax that reads its value from the presence of one or more inverted flags.
  ///
  /// Use this initializer to create a Boolean flag with an on/off pair.
  /// With the following declaration, for example, the user can specify either `--use-https` or `--no-use-https` to set the `useHTTPS` flag to `true` or `false`, respectively.
  ///
  /// ```swift
  /// @Flag(inversion: .prefixedNo)
  /// var useHTTPS: Bool = true
  /// ````
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during propery wrapper initialization.
  ///   - inversion: The method for converting this flag's name into an on/off pair.
  ///   - exclusivity: The behavior to use when an on/off pair of flags is specified.
  ///   - help: Information about how to use this flag.
  public init(
    wrappedValue: Bool,
    name: NameSpecification = .long,
    inversion: FlagInversion,
    exclusivity: FlagExclusivity = .chooseLast,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      name: name,
      initial: wrappedValue,
      inversion: inversion,
      exclusivity: exclusivity,
      help: help
    )
  }

  /// Creates a Boolean property with no default value that reads its value from the presence of one or more inverted flags.
  ///
  /// Use this initializer to create a Boolean flag with an on/off pair.
  /// With the following declaration, for example, the user can specify either `--use-https` or `--no-use-https` to set the `useHTTPS` flag to `true` or `false`, respectively.
  ///
  /// ```swift
  /// @Flag(inversion: .prefixedNo)
  /// var useHTTPS: Bool
  /// ````
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during propery wrapper initialization.
  ///   - inversion: The method for converting this flag's name into an on/off pair.
  ///   - exclusivity: The behavior to use when an on/off pair of flags is specified.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    inversion: FlagInversion,
    exclusivity: FlagExclusivity = .chooseLast,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      name: name,
      initial: nil,
      inversion: inversion,
      exclusivity: exclusivity,
      help: help
    )
  }
}

extension Flag where Value == Int {
  /// Creates an integer property that gets its value from the number of times
  /// a flag appears.
  ///
  /// This property defaults to a value of zero.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      .counter(key: key, name: name, help: help)
    })
  }
}

// - MARK: EnumerableFlag

extension Flag where Value: EnumerableFlag {
  /// Creates a property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    initial: Value?,
    exclusivity: FlagExclusivity,
    help: ArgumentHelp?
  ) {
    self.init(_parsedValue: .init { key in
      // This gets flipped to `true` the first time one of these flags is
      // encountered.
      var hasUpdated = false
      let defaultValue = initial.map(String.init(describing:))

      let caseHelps = Value.allCases.map { Value.help(for: $0) }
      let hasCustomCaseHelp = caseHelps.contains(where: { $0 != nil })
      
      let args = Value.allCases.enumerated().map { (i, value) -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: String(describing: value))
        let name = Value.name(for: value)
        let helpForCase = hasCustomCaseHelp ? (caseHelps[i] ?? help) : help
        let help = ArgumentDefinition.Help(options: initial != nil ? .isOptional : [], help: helpForCase, defaultValue: defaultValue, key: key, isComposite: !hasCustomCaseHelp)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: initial, update: .nullary({ (origin, name, values) in
          hasUpdated = try ArgumentSet.updateFlag(key: key, value: value, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
        }))
      }
      return ArgumentSet(args)
      })
  }

  /// Creates a property that gets its value from the presence of a flag,
  /// where the allowed flags are defined by an `EnumerableFlag` type.
  ///
  /// This method is deprecated, with usage split into two other methods below:
  /// - `init(wrappedValue:exclusivity:help:)` for properties with a default value
  /// - `init(exclusivity:help:)` for properties with no default value
  ///
  /// Existing usage of the `default` parameter should be replaced such as follows:
  /// ```diff
  /// -@Flag(default: .baz)
  /// -var foo: Bar
  /// +@Flag var foo: Bar = baz
  /// ```
  ///
  /// - Parameters:
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, one of the flags declared by this `@Flag` attribute is required
  ///     from the user.
  ///   - exclusivity: The behavior to use when multiple flags are specified.
  ///   - help: Information about how to use this flag.
  @available(*, deprecated, message: "Use regular property initialization for default values (`var foo: Bar = .baz`)")
  public init(
    default initial: Value?,
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      initial: initial,
      exclusivity: exclusivity,
      help: help
    )
  }

  /// Creates a property with a default value provided by standard Swift default value syntax that gets its value from the presence of a flag.
  ///
  /// Use this initializer to customize the name and number of states further than using a `Bool`.
  /// To use, define an `EnumerableFlag` enumeration with a case for each state, and use that as the type for your flag.
  /// In this case, the user can specify either `--use-production-server` or `--use-development-server` to set the flag's value.
  ///
  /// ```swift
  /// enum ServerChoice: EnumerableFlag {
  ///   case useProductionServer
  ///   case useDevelopmentServer
  /// }
  ///
  /// @Flag var serverChoice: ServerChoice = .useProductionServer
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during propery wrapper initialization.
  ///   - exclusivity: The behavior to use when multiple flags are specified.
  ///   - help: Information about how to use this flag.
  public init(
    wrappedValue: Value,
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      initial: wrappedValue,
      exclusivity: exclusivity,
      help: help
    )
  }

  /// Creates a property with no default value that gets its value from the presence of a flag.
  ///
  /// Use this initializer to customize the name and number of states further than using a `Bool`.
  /// To use, define an `EnumerableFlag` enumeration with a case for each state, and use that as the type for your flag.
  /// In this case, the user can specify either `--use-production-server` or `--use-development-server` to set the flag's value.
  ///
  /// ```swift
  /// enum ServerChoice: EnumerableFlag {
  ///   case useProductionServer
  ///   case useDevelopmentServer
  /// }
  ///
  /// @Flag var serverChoice: ServerChoice
  /// ```
  ///
  /// - Parameters:
  ///   - exclusivity: The behavior to use when multiple flags are specified.
  ///   - help: Information about how to use this flag.
  public init(
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      initial: nil,
      exclusivity: exclusivity,
      help: help
    )
  }
}

extension Flag {
  /// Creates a property that gets its value from the presence of a flag,
  /// where the allowed flags are defined by an `EnumerableFlag` type.
  public init<Element>(
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) where Value == Element?, Element: EnumerableFlag {
    self.init(_parsedValue: .init { key in
      // This gets flipped to `true` the first time one of these flags is
      // encountered.
      var hasUpdated = false
      
      let caseHelps = Element.allCases.map { Element.help(for: $0) }
      let hasCustomCaseHelp = caseHelps.contains(where: { $0 != nil })

      let args = Element.allCases.enumerated().map { (i, value) -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: String(describing: value))
        let name = Element.name(for: value)
        let helpForCase = hasCustomCaseHelp ? (caseHelps[i] ?? help) : help
        let help = ArgumentDefinition.Help(options: .isOptional, help: helpForCase, key: key, isComposite: !hasCustomCaseHelp)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: nil as Element?, update: .nullary({ (origin, name, values) in
          hasUpdated = try ArgumentSet.updateFlag(key: key, value: value, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
        }))

      }
      return ArgumentSet(args)
      })
  }

  /// Creates an array property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init<Element>(
    initial: [Element]?,
    help: ArgumentHelp? = nil
  ) where Value == Array<Element>, Element: EnumerableFlag {
    self.init(_parsedValue: .init { key in
      let caseHelps = Element.allCases.map { Element.help(for: $0) }
      let hasCustomCaseHelp = caseHelps.contains(where: { $0 != nil })

      let args = Element.allCases.enumerated().map { (i, value) -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: String(describing: value))
        let name = Element.name(for: value)
        let helpForCase = hasCustomCaseHelp ? (caseHelps[i] ?? help) : help
        let help = ArgumentDefinition.Help(options: .isOptional, help: helpForCase, key: key, isComposite: !hasCustomCaseHelp)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: initial, update: .nullary({ (origin, name, values) in
          values.update(forKey: key, inputOrigin: origin, initial: [Element](), closure: {
            $0.append(value)
          })
        }))
      }
      return ArgumentSet(args)
    })
  }

  /// Creates an array property that gets its values from the presence of
  /// zero or more flags, where the allowed flags are defined by an
  /// `EnumerableFlag` type.
  ///
  /// This property has an empty array as its default value.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  public init<Element>(
    wrappedValue: [Element],
    help: ArgumentHelp? = nil
  ) where Value == Array<Element>, Element: EnumerableFlag {
    self.init(
      initial: wrappedValue,
      help: help
    )
  }

  /// Creates an array property with no default value that gets its values from the presence of zero or more flags, where the allowed flags are defined by an `EnumerableFlag` type.
  ///
  /// This method is called to initialize an array `Flag` with no default value such as:
  /// ```swift
  /// @Flag
  /// var foo: [CustomFlagType]
  /// ```
  ///
  /// - Parameters:
  ///   - help: Information about how to use this flag.
  public init<Element>(
    help: ArgumentHelp? = nil
  ) where Value == Array<Element>, Element: EnumerableFlag {
    self.init(
      initial: nil,
      help: help
    )
  }
}

// - MARK: Unavailable CaseIterable/RawValue == String

extension Flag where Value: CaseIterable, Value: RawRepresentable, Value: Equatable, Value.RawValue == String {
  /// Creates a property that gets its value from the presence of a flag,
  /// where the allowed flags are defined by a case-iterable type.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, this flag is required.
  ///   - exclusivity: The behavior to use when multiple flags are specified.
  ///   - help: Information about how to use this flag.
  @available(*, unavailable, message: "Add 'EnumerableFlag' conformance to your value type and, if needed, specify the 'name' of each case there.")
  public init(
    name: NameSpecification = .long,
    default initial: Value? = nil,
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      // This gets flipped to `true` the first time one of these flags is
      // encountered.
      var hasUpdated = false
      let defaultValue = initial.map(String.init(describing:))

      let args = Value.allCases.map { value -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: value.rawValue)
        let help = ArgumentDefinition.Help(options: initial != nil ? .isOptional : [], help: help, defaultValue: defaultValue, key: key, isComposite: true)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: initial, update: .nullary({ (origin, name, values) in
          hasUpdated = try ArgumentSet.updateFlag(key: key, value: value, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
        }))
      }
      return ArgumentSet(args)
      })
  }
}

extension Flag {
  /// Creates a property that gets its value from the presence of a flag,
  /// where the allowed flags are defined by a case-iterable type.
  @available(*, unavailable, message: "Add 'EnumerableFlag' conformance to your value type and, if needed, specify the 'name' of each case there.")
  public init<Element>(
    name: NameSpecification = .long,
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) where Value == Element?, Element: CaseIterable, Element: Equatable, Element: RawRepresentable, Element.RawValue == String {
    self.init(_parsedValue: .init { key in
      // This gets flipped to `true` the first time one of these flags is
      // encountered.
      var hasUpdated = false
      
      let args = Element.allCases.map { value -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: value.rawValue)
        let help = ArgumentDefinition.Help(options: .isOptional, help: help, key: key, isComposite: true)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: nil as Element?, update: .nullary({ (origin, name, values) in
          hasUpdated = try ArgumentSet.updateFlag(key: key, value: value, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
        }))
      }
      return ArgumentSet(args)
    })
  }
  
  /// Creates an array property that gets its values from the presence of
  /// zero or more flags, where the allowed flags are defined by a
  /// `CaseIterable` type.
  ///
  /// This property has an empty array as its default value.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  @available(*, unavailable, message: "Add 'EnumerableFlag' conformance to your value type and, if needed, specify the 'name' of each case there.")
  public init<Element>(
    name: NameSpecification = .long,
    help: ArgumentHelp? = nil
  ) where Value == Array<Element>, Element: CaseIterable, Element: RawRepresentable, Element.RawValue == String {
    self.init(_parsedValue: .init { key in
      let args = Element.allCases.map { value -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: value.rawValue)
        let help = ArgumentDefinition.Help(options: .isOptional, help: help, key: key, isComposite: true)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: [Element](), update: .nullary({ (origin, name, values) in
          values.update(forKey: key, inputOrigin: origin, initial: [Element](), closure: {
            $0.append(value)
          })
        }))
      }
      return ArgumentSet(args)
    })
  }
}

extension ArgumentDefinition {
  static func flag<V>(name: NameSpecification, key: InputKey, caseKey: InputKey, help: Help, parsingStrategy: ArgumentDefinition.ParsingStrategy, initialValue: V?, update: Update) -> ArgumentDefinition {
    return ArgumentDefinition(kind: .name(key: caseKey, specification: name), help: help, completion: .default, parsingStrategy: parsingStrategy, update: update, initial: { origin, values in
      if let initial = initialValue {
        values.set(initial, forKey: key, inputOrigin: origin)
      }
    })
  }
}
