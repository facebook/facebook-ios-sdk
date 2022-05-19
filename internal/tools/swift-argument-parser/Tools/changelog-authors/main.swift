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

import ArgumentParser
import Foundation

// MARK: GitHub API response modeling

struct Comparison: Codable {
  var commits: [Commit]
}

struct Commit: Codable {
  var sha: String
  var author: Author
}

struct Author: Codable {
  var login: String
  var htmlURL: String
  
  enum CodingKeys: String, CodingKey {
    case login
    case htmlURL = "html_url"
  }
  
  var commitURL: String {
    "https://github.com/apple/swift-argument-parser/commits?author=\(login)"
  }
  
  var inlineLink: String {
    "[\(login)]"
  }
  
  var linkReference: String {
    "[\(login)]: \(commitURL)"
  }
}

// MARK: Helpers

extension Sequence {
  func uniqued<T: Hashable>(by transform: (Element) throws -> T) rethrows -> [Element] {
    var seen: Set<T> = []
    var result: [Element] = []
    
    for element in self {
      if try seen.insert(transform(element)).inserted {
        result.append(element)
      }
    }
    return result
  }
}

// MARK: Command

struct ChangelogAuthors: ParsableCommand {
  static var configuration: CommandConfiguration {
    CommandConfiguration(
      abstract: "A helper tool for generating author info for the changelog.",
      discussion: """
        Call this tool with a starting and ending tag to list authors of
        commits between those two releases. Provide only a single tag to
        list authors from that release up to the current top-of-tree.
        """)
  }
  
  @Argument(help: "The starting point for the comparison.")
  var startingTag: String
  
  @Argument(help: "The ending point for the comparison.")
  var endingTag: String?

  func validate() throws {
    func checkTag(_ tag: String) -> Bool {
      tag.allSatisfy {
        $0.isLetter || $0.isNumber || $0 == "."
      }
    }
    
    guard checkTag(startingTag) else {
      throw ValidationError("Invalid starting tag: \(startingTag)")
    }
    
    if let endingTag = endingTag {
      guard checkTag(endingTag) else {
        throw ValidationError("Invalid ending tag: \(endingTag)")
      }
    }
  }
  
  func links(for authors: [Author]) -> String {
    if authors.count <= 2 {
      return authors.map({ $0.inlineLink }).joined(separator: " and ")
    } else {
      let result = authors.dropLast()
        .map({ $0.inlineLink })
        .joined(separator: ", ")
      return "\(result), and \(authors.last!.inlineLink)"
    }
  }
  
  func references(for authors: [Author]) -> String {
    authors
      .map({ $0.linkReference })
      .joined(separator: "\n")
  }
  
  func comparisonURL() throws -> URL {
    guard let url = URL(
      string: "https://api.github.com/repos/apple/swift-argument-parser/compare/\(startingTag)...\(endingTag ?? "HEAD")")
    else {
      print("Couldn't create url string")
      throw ExitCode.failure
    }
    
    return url
  }
  
  mutating func run() throws {
    let data = try Data(contentsOf: try comparisonURL())
    let comparison = try JSONDecoder().decode(Comparison.self, from: data)
    let authors = comparison.commits.map({ $0.author })
      .uniqued(by: { $0.login })
      .sorted(by: { $0.login.lowercased() < $1.login.lowercased() })
    
    print(links(for: authors))
    print("---")
    print(references(for: authors))
  }
}

ChangelogAuthors.main()

