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

/// A specification for how to represent a property as a command-line argument
/// label.
public struct NameSpecification: ExpressibleByArrayLiteral {
  public enum Element: Hashable {
    /// Use the property's name, converted to lowercase with words separated by
    /// hyphens.
    ///
    /// For example, a property named `allowLongNames` would be converted to the
    /// label `--allow-long-names`.
    case long
    
    /// Use the given string instead of the property's name.
    ///
    /// To create a single-dash argument, pass `true` as `withSingleDash`. Note
    /// that combining single-dash options and options with short,
    /// single-character names can lead to ambiguities for the user.
    case customLong(_ name: String, withSingleDash: Bool = false)
    
    /// Use the first character of the property's name as a short option label.
    ///
    /// For example, a property named `verbose` would be converted to the
    /// label `-v`. Short labels can be combined into groups.
    case short
    
    /// Use the given character as a short option label.
    ///
    /// Short labels can be combined into groups.
    case customShort(Character)
  }
  var elements: [Element]
  
  public init<S>(_ sequence: S) where S : Sequence, Element == S.Element {
    self.elements = sequence.uniquing()
  }
  
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension NameSpecification {
  /// Use the property's name converted to lowercase with words separated by
  /// hyphens.
  ///
  /// For example, a property named `allowLongNames` would be converted to the
  /// label `--allow-long-names`.
  public static var long: NameSpecification { [.long] }
  
  /// Use the given string instead of the property's name.
  ///
  /// To create a single-dash argument, pass `true` as `withSingleDash`. Note
  /// that combining single-dash options and options with short,
  /// single-character names can lead to ambiguities for the user.
  public static func customLong(_ name: String, withSingleDash: Bool = false) -> NameSpecification {
    [.customLong(name, withSingleDash: withSingleDash)]
  }
  
  /// Use the first character of the property's name as a short option label.
  ///
  /// For example, a property named `verbose` would be converted to the
  /// label `-v`. Short labels can be combined into groups.
  public static var short: NameSpecification { [.short] }
  
  /// Use the given character as a short option label.
  ///
  /// Short labels can be combined into groups.
  public static func customShort(_ char: Character) -> NameSpecification {
    [.customShort(char)]
  }
  
  /// Combine the `.short` and `.long` specifications to allow both long
  /// and short labels.
  ///
  /// For example, a property named `verbose` would be converted to both the
  /// long `--verbose` and short `-v` labels.
  public static var shortAndLong: NameSpecification { [.long, .short] }
}

extension NameSpecification.Element {    
  /// Creates the argument name for this specification element.
  internal func name(for key: InputKey) -> Name? {
    switch self {
    case .long:
      return .long(key.rawValue.convertedToSnakeCase(separator: "-"))
    case .short:
      guard let c = key.rawValue.first else { fatalError("Key '\(key.rawValue)' has not characters to form short option name.") }
      return .short(c)
    case .customLong(let name, let withSingleDash):
      return withSingleDash
        ? .longWithSingleDash(name)
        : .long(name)
    case .customShort(let name):
      return .short(name)
    }
  }
}

extension NameSpecification {
  /// Creates the argument names for each element in the name specification.
  internal func makeNames(_ key: InputKey) -> [Name] {
    return elements.compactMap { $0.name(for: key) }
  }
}

extension FlagInversion {
  /// Creates the enable and disable name(s) for the given flag.
  internal func enableDisableNamePair(for key: InputKey, name: NameSpecification) -> ([Name], [Name]) {
    
    func makeNames(withPrefix prefix: String, includingShort: Bool) -> [Name] {
      return name.elements.compactMap { element -> Name? in
        switch element {
        case .short, .customShort:
          return includingShort ? element.name(for: key) : nil
        case .long:
          let modifiedKey = InputKey(rawValue: key.rawValue.addingIntercappedPrefix(prefix))
          return element.name(for: modifiedKey)
        case .customLong(let name, let withSingleDash):
          let modifiedName = name.addingPrefixWithAutodetectedStyle(prefix)
          let modifiedElement = NameSpecification.Element.customLong(modifiedName, withSingleDash: withSingleDash)
          return modifiedElement.name(for: key)
        }
      }
    }
    
    switch (self) {
    case .prefixedNo:
      return (
        name.makeNames(key),
        makeNames(withPrefix: "no", includingShort: false)
      )
    case .prefixedEnableDisable:
      return (
        makeNames(withPrefix: "enable", includingShort: true),
        makeNames(withPrefix: "disable", includingShort: false)
      )
    }
  }
}
