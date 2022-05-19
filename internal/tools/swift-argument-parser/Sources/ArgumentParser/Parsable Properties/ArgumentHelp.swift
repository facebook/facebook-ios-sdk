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

/// Help information for a command-line argument.
public struct ArgumentHelp {
  /// A short description of the argument.
  public var abstract: String = ""
  
  /// An expanded description of the argument, in plain text form.
  public var discussion: String = ""
  
  /// An alternative name to use for the argument's value when showing usage
  /// information.
  ///
  /// - Note: This property is ignored when generating help for flags, since
  ///   flags don't include a value.
  public var valueName: String?
  
  /// A Boolean value indicating whether this argument should be shown in
  /// the extended help display.
  public var shouldDisplay: Bool = true
  
  /// Creates a new help instance.
  public init(
    _ abstract: String = "",
    discussion: String = "",
    valueName: String? = nil,
    shouldDisplay: Bool = true)
  {
    self.abstract = abstract
    self.discussion = discussion
    self.valueName = valueName
    self.shouldDisplay = shouldDisplay
  }
  
  /// A `Help` instance that hides an argument from the extended help display.
  public static var hidden: ArgumentHelp {
    ArgumentHelp(shouldDisplay: false)
  }
}

extension ArgumentHelp: ExpressibleByStringInterpolation {
  public init(stringLiteral value: String) {
    self.abstract = value
  }
}
