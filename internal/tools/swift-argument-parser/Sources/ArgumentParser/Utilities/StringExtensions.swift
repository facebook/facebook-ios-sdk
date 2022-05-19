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

extension String {
  func wrapped(to columns: Int, wrappingIndent: Int = 0) -> String {
    let columns = columns - wrappingIndent
    var result: [Substring] = []
    
    var currentIndex = startIndex
    
    while true {
      let nextChunk = self[currentIndex...].prefix(columns)
      if let lastLineBreak = nextChunk.lastIndex(of: "\n") {
        result.append(contentsOf: self[currentIndex..<lastLineBreak].split(separator: "\n", omittingEmptySubsequences: false))
        currentIndex = index(after: lastLineBreak)
      } else if nextChunk.endIndex == self.endIndex {
        result.append(self[currentIndex...])
        break
      } else if let lastSpace = nextChunk.lastIndex(of: " ") {
        result.append(self[currentIndex..<lastSpace])
        currentIndex = index(after: lastSpace)
      } else if let nextSpace = self[currentIndex...].firstIndex(of: " ") {
        result.append(self[currentIndex..<nextSpace])
        currentIndex = index(after: nextSpace)
      } else {
        result.append(self[currentIndex...])
        break
      }
    }
    
    return result
      .map { $0.isEmpty ? $0 : String(repeating: " ", count: wrappingIndent) + $0 }
      .joined(separator: "\n")
  }
  
  /// Returns this string prefixed using a camel-case style.
  ///
  /// Example:
  ///
  ///     "hello".addingIntercappedPrefix("my")
  ///     // myHello
  func addingIntercappedPrefix(_ prefix: String) -> String {
    guard let firstChar = first else { return prefix }
    return "\(prefix)\(firstChar.uppercased())\(self.dropFirst())"
  }
  
  /// Returns this string prefixed using kebab-, snake-, or camel-case style
  /// depending on what can be detected from the string.
  ///
  /// Examples:
  ///
  ///     "hello".addingPrefixWithAutodetectedStyle("my")
  ///     // my-hello
  ///     "hello_there".addingPrefixWithAutodetectedStyle("my")
  ///     // my_hello_there
  ///     "hello-there".addingPrefixWithAutodetectedStyle("my")
  ///     // my-hello-there
  ///     "helloThere".addingPrefixWithAutodetectedStyle("my")
  ///     // myHelloThere
  func addingPrefixWithAutodetectedStyle(_ prefix: String) -> String {
    if contains("-") {
      return "\(prefix)-\(self)"
    } else if contains("_") {
      return "\(prefix)_\(self)"
    } else if first?.isLowercase == true && contains(where: { $0.isUppercase }) {
      return addingIntercappedPrefix(prefix)
    } else {
      return "\(prefix)-\(self)"
    }
  }
  
  /// Returns a new string with the camel-case-based words of this string
  /// split by the specified separator.
  ///
  /// Examples:
  ///
  ///     "myProperty".convertedToSnakeCase()
  ///     // my_property
  ///     "myURLProperty".convertedToSnakeCase()
  ///     // my_url_property
  ///     "myURLProperty".convertedToSnakeCase(separator: "-")
  ///     // my-url-property
  func convertedToSnakeCase(separator: Character = "_") -> String {
    guard !isEmpty else { return self }
    var result = ""
    // Whether we should append a separator when we see a uppercase character.
    var separateOnUppercase = true
    for index in indices {
      let nextIndex = self.index(after: index)
      let character = self[index]
      if character.isUppercase {
        if separateOnUppercase && !result.isEmpty {
          // Append the separator.
          result += "\(separator)"
        }
        // If the next character is uppercase and the next-next character is lowercase, like "L" in "URLSession", we should separate words.
        separateOnUppercase = nextIndex < endIndex && self[nextIndex].isUppercase && self.index(after: nextIndex) < endIndex && self[self.index(after: nextIndex)].isLowercase
      } else {
        // If the character is `separator`, we do not want to append another separator when we see the next uppercase character.
        separateOnUppercase = character != separator
      }
      // Append the lowercased character.
      result += character.lowercased()
    }
    return result
  }
  
  /// Returns the edit distance between this string and the provided target string.
  ///
  /// Uses the Levenshtein distance algorithm internally.
  ///
  /// See: https://en.wikipedia.org/wiki/Levenshtein_distance
  ///
  /// Examples:
  ///
  ///     "kitten".editDistance(to: "sitting")
  ///     // 3
  ///     "bar".editDistance(to: "baz")
  ///     // 1

  func editDistance(to target: String) -> Int {
    let rows = self.count
    let columns = target.count
    
    if rows <= 0 || columns <= 0 {
      return max(rows, columns)
    }
    
    var matrix = Array(repeating: Array(repeating: 0, count: columns + 1), count: rows + 1)
    
    for row in 1...rows {
      matrix[row][0] = row
    }
    for column in 1...columns {
      matrix[0][column] = column
    }
    
    for row in 1...rows {
      for column in 1...columns {
        let source = self[self.index(self.startIndex, offsetBy: row - 1)]
        let target = target[target.index(target.startIndex, offsetBy: column - 1)]
        let cost = source == target ? 0 : 1
        
        matrix[row][column] = Swift.min(
          matrix[row - 1][column] + 1,
          matrix[row][column - 1] + 1,
          matrix[row - 1][column - 1] + cost
        )
      }
    }
    
    return matrix.last!.last!
  }
  
  func indentingEachLine(by n: Int) -> String {
    let hasTrailingNewline = self.last == "\n"
    let lines = self.split(separator: "\n", omittingEmptySubsequences: false)
    if hasTrailingNewline && lines.last == "" {
      return lines.dropLast().map { String(repeating: " ", count: n) + $0 }
        .joined(separator: "\n") + "\n"
    } else {
      return lines.map { String(repeating: " ", count: n) + $0 }
        .joined(separator: "\n")
    }
  }
}
