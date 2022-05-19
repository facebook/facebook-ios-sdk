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


import Foundation

protocol TemplateTokenConsumer {
    func parser(_ parser:TemplateParser, shouldContinueAfterParsingToken token:TemplateToken) -> Bool
    func parser(_ parser:TemplateParser, didFailWithError error:Error)
}

final class TemplateParser {
    let tokenConsumer: TemplateTokenConsumer
    fileprivate let tagDelimiterPair: TagDelimiterPair
    
    init(tokenConsumer: TemplateTokenConsumer, tagDelimiterPair: TagDelimiterPair) {
        self.tokenConsumer = tokenConsumer
        self.tagDelimiterPair = tagDelimiterPair
    }
    
    func parse(_ templateString:String, templateID: TemplateID?) {
        var currentDelimiters = ParserTagDelimiters(tagDelimiterPair: tagDelimiterPair)
        
        var state: State = .start
        var lineNumber = 1
        var i = templateString.startIndex
        let end = templateString.endIndex
        
        while i < end {
            let c = templateString[i]
            
            switch state {
            case .start:
                if c == "\n" {
                    state = .text(startIndex: i, startLineNumber: lineNumber)
                    lineNumber += 1
                } else if index(i, isAt: currentDelimiters.unescapedTagStart, in: templateString) {
                    state = .unescapedTag(startIndex: i, startLineNumber: lineNumber)
                    i = templateString.index(i, offsetBy: currentDelimiters.unescapedTagStartLength)
                    i = templateString.index(before: i)
                } else if index(i, isAt: currentDelimiters.setDelimitersStart, in: templateString) {
                    state = .setDelimitersTag(startIndex: i, startLineNumber: lineNumber)
                    i = templateString.index(i, offsetBy: currentDelimiters.setDelimitersStartLength)
                    i = templateString.index(before: i)
                } else if index(i, isAt: currentDelimiters.tagDelimiterPair.0, in: templateString) {
                    state = .tag(startIndex: i, startLineNumber: lineNumber)
                    i = templateString.index(i, offsetBy: currentDelimiters.tagStartLength)
                    i = templateString.index(before: i)
                } else {
                    state = .text(startIndex: i, startLineNumber: lineNumber)
                }
            case .text(let startIndex, let startLineNumber):
                if c == "\n" {
                    lineNumber += 1
                } else if index(i, isAt: currentDelimiters.unescapedTagStart, in: templateString) {
                    if startIndex != i {
                        let range = startIndex..<i
                        let token = TemplateToken(
                            type: .text(text: String(templateString[range])),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: startIndex..<i)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    state = .unescapedTag(startIndex: i, startLineNumber: lineNumber)
                    i = templateString.index(i, offsetBy: currentDelimiters.unescapedTagStartLength)
                    i = templateString.index(before: i)
                } else if index(i, isAt: currentDelimiters.setDelimitersStart, in: templateString) {
                    if startIndex != i {
                        let range = startIndex..<i
                        let token = TemplateToken(
                            type: .text(text: String(templateString[range])),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: startIndex..<i)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    state = .setDelimitersTag(startIndex: i, startLineNumber: lineNumber)
                    i = templateString.index(i, offsetBy: currentDelimiters.setDelimitersStartLength)
                    i = templateString.index(before: i)
                } else if index(i, isAt: currentDelimiters.tagDelimiterPair.0, in: templateString) {
                    if startIndex != i {
                        let range = startIndex..<i
                        let token = TemplateToken(
                            type: .text(text: String(templateString[range])),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: startIndex..<i)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    state = .tag(startIndex: i, startLineNumber: lineNumber)
                    i = templateString.index(i, offsetBy: currentDelimiters.tagStartLength)
                    i = templateString.index(before: i)
                }
            case .tag(let startIndex, let startLineNumber):
                if c == "\n" {
                    lineNumber += 1
                } else if index(i, isAt: currentDelimiters.tagDelimiterPair.1, in: templateString) {
                    let tagInitialIndex = templateString.index(startIndex, offsetBy: currentDelimiters.tagStartLength)
                    let tagInitial = templateString[tagInitialIndex]
                    let tokenRange = startIndex..<templateString.index(i, offsetBy: currentDelimiters.tagEndLength)
                    switch tagInitial {
                    case "!":
                        let token = TemplateToken(
                            type: .comment,
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "#":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .section(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "^":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .invertedSection(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "$":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .block(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "/":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .close(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case ">":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .partial(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "<":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .partialOverride(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "&":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .unescapedVariable(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    case "%":
                        let content = String(templateString[templateString.index(after: tagInitialIndex)..<i])
                        let token = TemplateToken(
                            type: .pragma(content: content),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    default:
                        let content = String(templateString[tagInitialIndex..<i])
                        let token = TemplateToken(
                            type: .escapedVariable(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                            lineNumber: startLineNumber,
                            templateID: templateID,
                            templateString: templateString,
                            range: tokenRange)
                        if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                            return
                        }
                    }
                    state = .start
                    i = templateString.index(i, offsetBy: currentDelimiters.tagEndLength)
                    i = templateString.index(before: i)
                }
                break
            case .unescapedTag(let startIndex, let startLineNumber):
                if c == "\n" {
                    lineNumber += 1
                } else if index(i, isAt: currentDelimiters.unescapedTagEnd, in: templateString) {
                    let tagInitialIndex = templateString.index(startIndex, offsetBy: currentDelimiters.unescapedTagStartLength)
                    let content = String(templateString[tagInitialIndex..<i])
                    let token = TemplateToken(
                        type: .unescapedVariable(content: content, tagDelimiterPair: currentDelimiters.tagDelimiterPair),
                        lineNumber: startLineNumber,
                        templateID: templateID,
                        templateString: templateString,
                        range: startIndex..<templateString.index(i, offsetBy: currentDelimiters.unescapedTagEndLength))
                    if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                        return
                    }
                    state = .start
                    i = templateString.index(i, offsetBy: currentDelimiters.unescapedTagEndLength)
                    i = templateString.index(before: i)
                }
            case .setDelimitersTag(let startIndex, let startLineNumber):
                if c == "\n" {
                    lineNumber += 1
                } else if index(i, isAt: currentDelimiters.setDelimitersEnd, in: templateString) {
                    let tagInitialIndex = templateString.index(startIndex, offsetBy: currentDelimiters.setDelimitersStartLength)
                    let content = String(templateString[tagInitialIndex..<i])
                    let newDelimiters = content.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { $0.count > 0 }
                    if (newDelimiters.count != 2) {
                        let error = MustacheError(kind: .parseError, message: "Invalid set delimiters tag", templateID: templateID, lineNumber: startLineNumber)
                        tokenConsumer.parser(self, didFailWithError: error)
                        return;
                    }
                    
                    let token = TemplateToken(
                        type: .setDelimiters,
                        lineNumber: startLineNumber,
                        templateID: templateID,
                        templateString: templateString,
                        range: startIndex..<templateString.index(i, offsetBy: currentDelimiters.setDelimitersEndLength))
                    if !tokenConsumer.parser(self, shouldContinueAfterParsingToken: token) {
                        return
                    }
                    
                    state = .start
                    i = templateString.index(i, offsetBy: currentDelimiters.setDelimitersEndLength)
                    i = templateString.index(before: i)
                    currentDelimiters = ParserTagDelimiters(tagDelimiterPair: (newDelimiters[0], newDelimiters[1]))
                }
            }
            
            i = templateString.index(after: i)
        }
        
        
        // EOF
        
        switch state {
        case .start:
            break
        case .text(let startIndex, let startLineNumber):
            let range = startIndex..<end
            let token = TemplateToken(
                type: .text(text: String(templateString[range])),
                lineNumber: startLineNumber,
                templateID: templateID,
                templateString: templateString,
                range: range)
            _ = tokenConsumer.parser(self, shouldContinueAfterParsingToken: token)
        case .tag(_, let startLineNumber):
            let error = MustacheError(kind: .parseError, message: "Unclosed Mustache tag", templateID: templateID, lineNumber: startLineNumber)
            tokenConsumer.parser(self, didFailWithError: error)
        case .unescapedTag(_, let startLineNumber):
            let error = MustacheError(kind: .parseError, message: "Unclosed Mustache tag", templateID: templateID, lineNumber: startLineNumber)
            tokenConsumer.parser(self, didFailWithError: error)
        case .setDelimitersTag(_, let startLineNumber):
            let error = MustacheError(kind: .parseError, message: "Unclosed Mustache tag", templateID: templateID, lineNumber: startLineNumber)
            tokenConsumer.parser(self, didFailWithError: error)
        }
    }
    
    private func index(_ index: String.Index, isAt string: String?, in templateString: String) -> Bool {
        guard let string = string else {
            return false
        }
        return templateString[index...].hasPrefix(string)
    }
    
    // MARK: - Private
    
    fileprivate enum State {
        case start
        case text(startIndex: String.Index, startLineNumber: Int)
        case tag(startIndex: String.Index, startLineNumber: Int)
        case unescapedTag(startIndex: String.Index, startLineNumber: Int)
        case setDelimitersTag(startIndex: String.Index, startLineNumber: Int)
    }
    
    fileprivate struct ParserTagDelimiters {
        let tagDelimiterPair : TagDelimiterPair
        let tagStartLength: Int
        let tagEndLength: Int
        let unescapedTagStart: String?
        let unescapedTagStartLength: Int
        let unescapedTagEnd: String?
        let unescapedTagEndLength: Int
        let setDelimitersStart: String
        let setDelimitersStartLength: Int
        let setDelimitersEnd: String
        let setDelimitersEndLength: Int
        
        init(tagDelimiterPair : TagDelimiterPair) {
            self.tagDelimiterPair = tagDelimiterPair
            
            tagStartLength = tagDelimiterPair.0.distance(from: tagDelimiterPair.0.startIndex, to: tagDelimiterPair.0.endIndex)
            tagEndLength = tagDelimiterPair.1.distance(from: tagDelimiterPair.1.startIndex, to: tagDelimiterPair.1.endIndex)
            
            let usesStandardDelimiters = (tagDelimiterPair.0 == "{{") && (tagDelimiterPair.1 == "}}")
            unescapedTagStart = usesStandardDelimiters ? "{{{" : nil
            unescapedTagStartLength = unescapedTagStart != nil ? unescapedTagStart!.distance(from: unescapedTagStart!.startIndex, to: unescapedTagStart!.endIndex) : 0
            unescapedTagEnd = usesStandardDelimiters ? "}}}" : nil
            unescapedTagEndLength = unescapedTagEnd != nil ? unescapedTagEnd!.distance(from: unescapedTagEnd!.startIndex, to: unescapedTagEnd!.endIndex) : 0
            
            setDelimitersStart = "\(tagDelimiterPair.0)="
            setDelimitersStartLength = setDelimitersStart.distance(from: setDelimitersStart.startIndex, to: setDelimitersStart.endIndex)
            setDelimitersEnd = "=\(tagDelimiterPair.1)"
            setDelimitersEndLength = setDelimitersEnd.distance(from: setDelimitersEnd.startIndex, to: setDelimitersEnd.endIndex)
        }
    }
}
