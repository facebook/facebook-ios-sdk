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

enum Name: Hashable {
  /// A name (usually multi-character) prefixed with `--` (2 dashes) or equivalent.
  case long(String)
  /// A single character name prefixed with `-` (1 dash) or equivalent.
  ///
  /// Usually supports mixing multiple short names with a single dash, i.e. `-ab` is equivalent to `-a -b`.
  case short(Character)
  /// A name (usually multi-character) prefixed with `-` (1 dash).
  case longWithSingleDash(String)
  
  init(_ baseName: Substring) {
    assert(baseName.first == "-", "Attempted to create name for unprefixed argument")
    if baseName.hasPrefix("--") {
      self = .long(String(baseName.dropFirst(2)))
    } else if baseName.count == 2 { // single character "-x" style
      self = .short(baseName.last!)
    } else { // long name with single dash
      self = .longWithSingleDash(String(baseName.dropFirst()))
    }
  }
}

extension Name {
  var synopsisString: String {
    switch self {
    case .long(let n):
      return "--\(n)"
    case .short(let n):
      return "-\(n)"
    case .longWithSingleDash(let n):
      return "-\(n)"
    }
  }
  
  var valueString: String {
    switch self {
    case .long(let n):
      return n
    case .short(let n):
      return String(n)
    case .longWithSingleDash(let n):
      return n
    }
  }
  
  var isShort: Bool {
    switch self {
    case .short:
      return true
    default:
      return false
    }
  }
}

// short argument names based on the synopsisString
// this will put the single - options before the -- options
extension Name: Comparable {
  static func < (lhs: Name, rhs: Name) -> Bool {
    return lhs.synopsisString < rhs.synopsisString
  }
}
