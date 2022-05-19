// The MIT License
//
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


/// GRMustache distinguishes Text from HTML.
///
/// Content type applies to both *templates*, and *renderings*:
///
/// - In a HTML template, `{{name}}` tags escape Text renderings, but do not
///   escape HTML renderings.
///
/// - In a Text template, `{{name}}` tags do not escape anything.
///
/// The content type of a template comes from `Configuration.contentType` or
/// `{{% CONTENT_TYPE:... }}` pragma tags. See the documentation of
/// `Configuration.contentType` for a full discussion.
///
/// The content type of rendering is discussed with the `Rendering` type.
///
/// - seealso: Configuration.contentType
/// - seealso: Rendering
public enum ContentType {
    case text
    case html
}


/// The errors thrown by Mustache.swift
public struct MustacheError : Error {
    
    /// MustacheError types
    public enum Kind : Int {
        case templateNotFound
        case parseError
        case renderError
    }
    
    /// The error type
    public let kind: Kind
    
    /// Eventual error message
    public let message: String?
    
    /// TemplateID of the eventual template at the origin of the error
    public let templateID: String?
    
    /// Eventual line number where the error occurred.
    public let lineNumber: Int?
    
    /// Eventual underlying error
    public let underlyingError: Error?
    
    /// Returns self.description
    public var localizedDescription: String {
        return description
    }
    
    
    // Not public
    
    public init(kind: Kind, message: String? = nil, templateID: TemplateID? = nil, lineNumber: Int? = nil, underlyingError: Error? = nil) {
        self.kind = kind
        self.message = message
        self.templateID = templateID
        self.lineNumber = lineNumber
        self.underlyingError = underlyingError
    }
    
    func errorWith(message: String? = nil, templateID: TemplateID? = nil, lineNumber: Int? = nil, underlyingError: Error? = nil) -> MustacheError {
        return MustacheError(
            kind: self.kind,
            message: message ?? self.message,
            templateID: templateID ?? self.templateID,
            lineNumber: lineNumber ?? self.lineNumber,
            underlyingError: underlyingError ?? self.underlyingError)
    }
}

extension MustacheError : CustomStringConvertible {
    
    var locationDescription: String? {
        if let templateID = templateID {
            if let lineNumber = lineNumber {
                return "line \(lineNumber) of template \(templateID)"
            } else {
                return "template \(templateID)"
            }
        } else {
            if let lineNumber = lineNumber {
                return "line \(lineNumber)"
            } else {
                return nil
            }
        }
    }
    
    /// A textual representation of `self`.
    public var description: String {
        var description: String
        switch kind {
        case .templateNotFound:
            description = ""
        case .parseError:
            if let locationDescription = locationDescription {
                description = "Parse error at \(locationDescription)"
            } else {
                description = "Parse error"
            }
        case .renderError:
            if let locationDescription = locationDescription {
                description = "Rendering error at \(locationDescription)"
            } else {
                description = "Rendering error"
            }
        }
        
        if let message = message {
            if description.count > 0 {
                description += ": \(message)"
            } else {
                description = message
            }
        }
        
        if let underlyingError = underlyingError {
            description += " (\(underlyingError))"
        }
        
        return description
    }
}


/// A pair of tag delimiters, such as `("{{", "}}")`.
///
/// - seealso: Configuration.tagDelimiterPair
/// - seealso: Tag.tagDelimiterPair
public typealias TagDelimiterPair = (String, String)


/// HTML-escapes a string by replacing `<`, `> `, `&`, `'` and `"` with
/// HTML entities.
///
/// - parameter string: A string.
/// - returns: The HTML-escaped string.
public func escapeHTML(_ string: String) -> String {
    let escapeTable: [Character: String] = [
        "<": "&lt;",
        ">": "&gt;",
        "&": "&amp;",
        "'": "&apos;",
        "\"": "&quot;",
    ]
    var escaped = ""
    for c in string {
        if let escapedString = escapeTable[c] {
            escaped += escapedString
        } else {
            escaped.append(c)
        }
    }
    return escaped
}
