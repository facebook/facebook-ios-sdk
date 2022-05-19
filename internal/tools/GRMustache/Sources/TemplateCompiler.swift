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

final class TemplateCompiler: TemplateTokenConsumer {
    fileprivate var state: CompilerState
    fileprivate let repository: TemplateRepository
    fileprivate let templateID: TemplateID?
    
    init(contentType: ContentType, repository: TemplateRepository, templateID: TemplateID?) {
        self.state = .compiling(CompilationState(contentType: contentType))
        self.repository = repository
        self.templateID = templateID
    }
    
    func templateAST() throws -> TemplateAST {
        switch(state) {
        case .compiling(let compilationState):
            switch compilationState.currentScope.type {
            case .root:
                return TemplateAST(nodes: compilationState.currentScope.templateASTNodes, contentType: compilationState.contentType)
            case .section(openingToken: let openingToken, expression: _):
                throw MustacheError(kind: .parseError, message: "Unclosed Mustache tag", templateID: openingToken.templateID, lineNumber: openingToken.lineNumber)
            case .invertedSection(openingToken: let openingToken, expression: _):
                throw MustacheError(kind: .parseError, message: "Unclosed Mustache tag", templateID: openingToken.templateID, lineNumber: openingToken.lineNumber)
            case .partialOverride(openingToken: let openingToken, parentPartialName: _):
                throw MustacheError(kind: .parseError, message: "Unclosed Mustache tag", templateID: openingToken.templateID, lineNumber: openingToken.lineNumber)
            case .block(openingToken: let openingToken, blockName: _):
                throw MustacheError(kind: .parseError, message: "Unclosed Mustache tag", templateID: openingToken.templateID, lineNumber: openingToken.lineNumber)
            }
        case .error(let compilationError):
            throw compilationError
        }
    }
    
    
    // MARK: - TemplateTokenConsumer
    
    func parser(_ parser: TemplateParser, didFailWithError error: Error) {
        state = .error(error)
    }
    
    func parser(_ parser: TemplateParser, shouldContinueAfterParsingToken token: TemplateToken) -> Bool {
        switch(state) {
        case .error:
            return false
        case .compiling(let compilationState):
            do {
                switch(token.type) {
                    
                case .setDelimiters:
                    // noop
                    break
                    
                case .comment:
                    // noop
                    break
                    
                case .pragma(content: let content):
                    let pragma = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    if (try! NSRegularExpression(pattern: "^CONTENT_TYPE\\s*:\\s*TEXT$", options: NSRegularExpression.Options(rawValue: 0))).firstMatch(in: pragma, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (pragma as NSString).length)) != nil {
                        switch compilationState.compilerContentType {
                        case .unlocked:
                            compilationState.compilerContentType = .unlocked(.text)
                        case .locked(_):
                            throw MustacheError(kind: .parseError, message:"CONTENT_TYPE:TEXT pragma tag must prepend any Mustache variable, section, or partial tag.", templateID: token.templateID, lineNumber: token.lineNumber)
                        }
                    } else if (try! NSRegularExpression(pattern: "^CONTENT_TYPE\\s*:\\s*HTML$", options: NSRegularExpression.Options(rawValue: 0))).firstMatch(in: pragma, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (pragma as NSString).length)) != nil {
                        switch compilationState.compilerContentType {
                        case .unlocked:
                            compilationState.compilerContentType = .unlocked(.html)
                        case .locked(_):
                            throw MustacheError(kind: .parseError, message:"CONTENT_TYPE:HTML pragma tag must prepend any Mustache variable, section, or partial tag.", templateID: token.templateID, lineNumber: token.lineNumber)
                        }
                    }
                    
                case .text(text: let text):
                    switch compilationState.currentScope.type {
                    case .partialOverride:
                        // Text inside a partial override tag is not rendered.
                        //
                        // We could throw an error, like we do for illegal tags
                        // inside a partial override tag.
                        //
                        // But Hogan.js has an explicit test for "successfully"
                        // ignored text. So let's not throw.
                        //
                        // Ignore text inside a partial override tag:
                        break
                    default:
                        compilationState.currentScope.appendNode(TemplateASTNode.text(text: text))
                    }
                    
                case .escapedVariable(content: let content, tagDelimiterPair: _):
                    switch compilationState.currentScope.type {
                    case .partialOverride:
                        throw MustacheError(kind: .parseError, message:"Illegal tag inside a partial override tag.", templateID: token.templateID, lineNumber: token.lineNumber)
                    default:
                        var empty = false
                        do {
                            let expression = try ExpressionParser().parse(content, empty: &empty)
                            compilationState.currentScope.appendNode(TemplateASTNode.variable(expression: expression, contentType: compilationState.contentType, escapesHTML: true, token: token))
                            compilationState.compilerContentType = .locked(compilationState.contentType)
                        } catch let error as MustacheError {
                            throw error.errorWith(templateID: token.templateID, lineNumber: token.lineNumber)
                        } catch {
                            throw MustacheError(kind: .parseError, templateID: token.templateID, lineNumber: token.lineNumber, underlyingError: error)
                        }
                    }
                    
                case .unescapedVariable(content: let content, tagDelimiterPair: _):
                    switch compilationState.currentScope.type {
                    case .partialOverride:
                        throw MustacheError(kind: .parseError, message: "Illegal tag inside a partial override tag: \(token.templateSubstring)", templateID: token.templateID, lineNumber: token.lineNumber)
                    default:
                        var empty = false
                        do {
                            let expression = try ExpressionParser().parse(content, empty: &empty)
                            compilationState.currentScope.appendNode(TemplateASTNode.variable(expression: expression, contentType: compilationState.contentType, escapesHTML: false, token: token))
                            compilationState.compilerContentType = .locked(compilationState.contentType)
                        } catch let error as MustacheError {
                            throw error.errorWith(templateID: token.templateID, lineNumber: token.lineNumber)
                        } catch {
                            throw MustacheError(kind: .parseError, templateID: token.templateID, lineNumber: token.lineNumber, underlyingError: error)
                        }
                    }
                    
                case .section(content: let content, tagDelimiterPair: _):
                    switch compilationState.currentScope.type {
                    case .partialOverride:
                        throw MustacheError(kind: .parseError, message: "Illegal tag inside a partial override tag: \(token.templateSubstring)", templateID: token.templateID, lineNumber: token.lineNumber)
                    default:
                        var empty = false
                        do {
                            let expression = try ExpressionParser().parse(content, empty: &empty)
                            compilationState.pushScope(Scope(type: .section(openingToken: token, expression: expression)))
                            compilationState.compilerContentType = .locked(compilationState.contentType)
                        } catch let error as MustacheError {
                            throw error.errorWith(templateID: token.templateID, lineNumber: token.lineNumber)
                        } catch {
                            throw MustacheError(kind: .parseError, templateID: token.templateID, lineNumber: token.lineNumber, underlyingError: error)
                        }
                    }
                    
                case .invertedSection(content: let content, tagDelimiterPair: _):
                    switch compilationState.currentScope.type {
                    case .partialOverride:
                        throw MustacheError(kind: .parseError, message: "Illegal tag inside a partial override tag: \(token.templateSubstring)", templateID: token.templateID, lineNumber: token.lineNumber)
                    default:
                        var empty = false
                        do {
                            let expression = try ExpressionParser().parse(content, empty: &empty)
                            compilationState.pushScope(Scope(type: .invertedSection(openingToken: token, expression: expression)))
                            compilationState.compilerContentType = .locked(compilationState.contentType)
                        } catch let error as MustacheError {
                            throw error.errorWith(templateID: token.templateID, lineNumber: token.lineNumber)
                        } catch {
                            throw MustacheError(kind: .parseError, templateID: token.templateID, lineNumber: token.lineNumber, underlyingError: error)
                        }
                    }
                    
                case .block(content: let content):
                    var empty: Bool = false
                    let blockName = try blockNameFromString(content, inToken: token, empty: &empty)
                    compilationState.pushScope(Scope(type: .block(openingToken: token, blockName: blockName)))
                    compilationState.compilerContentType = .locked(compilationState.contentType)
                    
                case .partialOverride(content: let content):
                    var empty: Bool = false
                    let parentPartialName = try partialNameFromString(content, inToken: token, empty: &empty)
                    compilationState.pushScope(Scope(type: .partialOverride(openingToken: token, parentPartialName: parentPartialName)))
                    compilationState.compilerContentType = .locked(compilationState.contentType)
                    
                case .close(content: let content):
                    switch compilationState.currentScope.type {
                    case .root:
                        throw MustacheError(kind: .parseError, message: "Unmatched closing tag", templateID: token.templateID, lineNumber: token.lineNumber)
                        
                    case .section(openingToken: let openingToken, expression: let closedExpression):
                        var empty: Bool = false
                        var expression: Expression?
                        do {
                            expression = try ExpressionParser().parse(content, empty: &empty)
                        } catch let error as MustacheError {
                            if empty == false {
                                throw error.errorWith(templateID: token.templateID, lineNumber: token.lineNumber)
                            }
                        } catch {
                            throw MustacheError(kind: .parseError, templateID: token.templateID, lineNumber: token.lineNumber, underlyingError: error)
                        }
                        if expression != nil && expression != closedExpression {
                            throw MustacheError(kind: .parseError, message: "Unmatched closing tag", templateID: token.templateID, lineNumber: token.lineNumber)
                        }
                        
                        let templateASTNodes = compilationState.currentScope.templateASTNodes
                        let templateAST = TemplateAST(nodes: templateASTNodes, contentType: compilationState.contentType)

//                        // TODO: uncomment and make it compile
//                        if token.templateString !== openingToken.templateString {
//                            fatalError("Not implemented")
//                        }
                        let templateString = token.templateString
                        let innerContentRange = openingToken.range.upperBound..<token.range.lowerBound
                        let sectionTag = TemplateASTNode.section(templateAST: templateAST, expression: closedExpression, inverted: false, openingToken: openingToken, innerTemplateString: String(templateString[innerContentRange]))

                        compilationState.popCurrentScope()
                        compilationState.currentScope.appendNode(sectionTag)
                        
                    case .invertedSection(openingToken: let openingToken, expression: let closedExpression):
                        var empty: Bool = false
                        var expression: Expression?
                        do {
                            expression = try ExpressionParser().parse(content, empty: &empty)
                        } catch let error as MustacheError {
                            if empty == false {
                                throw error.errorWith(templateID: token.templateID, lineNumber: token.lineNumber)
                            }
                        } catch {
                            throw MustacheError(kind: .parseError, templateID: token.templateID, lineNumber: token.lineNumber, underlyingError: error)
                        }
                        if expression != nil && expression != closedExpression {
                            throw MustacheError(kind: .parseError, message: "Unmatched closing tag", templateID: token.templateID, lineNumber: token.lineNumber)
                        }
                        
                        let templateASTNodes = compilationState.currentScope.templateASTNodes
                        let templateAST = TemplateAST(nodes: templateASTNodes, contentType: compilationState.contentType)
                        
//                        // TODO: uncomment and make it compile
//                        if token.templateString !== openingToken.templateString {
//                            fatalError("Not implemented")
//                        }
                        let templateString = token.templateString
                        let innerContentRange = openingToken.range.upperBound..<token.range.lowerBound
                        let sectionTag = TemplateASTNode.section(templateAST: templateAST, expression: closedExpression, inverted: true, openingToken: openingToken, innerTemplateString: String(templateString[innerContentRange]))
                        
                        compilationState.popCurrentScope()
                        compilationState.currentScope.appendNode(sectionTag)
                        
                    case .partialOverride(openingToken: _, parentPartialName: let parentPartialName):
                        var empty: Bool = false
                        var partialName: String?
                        do {
                            partialName = try partialNameFromString(content, inToken: token, empty: &empty)
                        } catch {
                            if empty == false {
                                throw error
                            }
                        }
                        if partialName != nil && partialName != parentPartialName {
                            throw MustacheError(kind: .parseError, message: "Unmatched closing tag", templateID: token.templateID, lineNumber: token.lineNumber)
                        }
                        
                        let parentTemplateAST = try repository.templateAST(named: parentPartialName, relativeToTemplateID:templateID)
                        switch parentTemplateAST.type {
                        case .undefined:
                            break
                        case .defined(nodes: _, contentType: let partialContentType):
                            if partialContentType != compilationState.contentType {
                                throw MustacheError(kind: .parseError, message: "Content type mismatch", templateID: token.templateID, lineNumber: token.lineNumber)
                            }
                        }
                        
                        let templateASTNodes = compilationState.currentScope.templateASTNodes
                        let templateAST = TemplateAST(nodes: templateASTNodes, contentType: compilationState.contentType)
                        let partialOverrideNode = TemplateASTNode.partialOverride(childTemplateAST: templateAST, parentTemplateAST: parentTemplateAST, parentPartialName: parentPartialName)
                        compilationState.popCurrentScope()
                        compilationState.currentScope.appendNode(partialOverrideNode)
                        
                    case .block(openingToken: _, blockName: let closedBlockName):
                        var empty: Bool = false
                        var blockName: String?
                        do {
                            blockName = try blockNameFromString(content, inToken: token, empty: &empty)
                        } catch {
                            if empty == false {
                                throw error
                            }
                        }
                        if blockName != nil && blockName != closedBlockName {
                            throw MustacheError(kind: .parseError, message: "Unmatched closing tag", templateID: token.templateID, lineNumber: token.lineNumber)
                        }
                        
                        let templateASTNodes = compilationState.currentScope.templateASTNodes
                        let templateAST = TemplateAST(nodes: templateASTNodes, contentType: compilationState.contentType)
                        let blockNode = TemplateASTNode.block(innerTemplateAST: templateAST, name: closedBlockName)
                        compilationState.popCurrentScope()
                        compilationState.currentScope.appendNode(blockNode)
                    }
                    
                case .partial(content: let content):
                    var empty: Bool = false
                    let partialName = try partialNameFromString(content, inToken: token, empty: &empty)
                    let partialTemplateAST = try repository.templateAST(named: partialName, relativeToTemplateID: templateID)
                    let partialNode = TemplateASTNode.partial(templateAST: partialTemplateAST, name: partialName)
                    compilationState.currentScope.appendNode(partialNode)
                    compilationState.compilerContentType = .locked(compilationState.contentType)
                }
                
                return true
            } catch {
                state = .error(error)
                return false
            }
        }
    }
    
    
    // MARK: - Private
    
    fileprivate class CompilationState {
        var currentScope: Scope {
            return scopeStack[scopeStack.endIndex - 1]
        }
        var contentType: ContentType {
            switch compilerContentType {
            case .unlocked(let contentType):
                return contentType
            case .locked(let contentType):
                return contentType
            }
        }
        
        init(contentType: ContentType) {
            self.compilerContentType = .unlocked(contentType)
            self.scopeStack = [Scope(type: .root)]
        }
        
        func popCurrentScope() {
            scopeStack.removeLast()
        }
        
        func pushScope(_ scope: Scope) {
            scopeStack.append(scope)
        }
        
        enum CompilerContentType {
            case unlocked(ContentType)
            case locked(ContentType)
        }
        
        var compilerContentType: CompilerContentType
        fileprivate var scopeStack: [Scope]
    }
    
    fileprivate enum CompilerState {
        case compiling(CompilationState)
        case error(Error)
    }
    
    fileprivate class Scope {
        let type: Type
        var templateASTNodes: [TemplateASTNode]
        
        init(type:Type) {
            self.type = type
            self.templateASTNodes = []
        }
        
        func appendNode(_ node: TemplateASTNode) {
            templateASTNodes.append(node)
        }
        
        enum `Type` {
            case root
            case section(openingToken: TemplateToken, expression: Expression)
            case invertedSection(openingToken: TemplateToken, expression: Expression)
            case partialOverride(openingToken: TemplateToken, parentPartialName: String)
            case block(openingToken: TemplateToken, blockName: String)
        }
    }
    
    fileprivate func blockNameFromString(_ string: String, inToken token: TemplateToken, empty: inout Bool) throws -> String {
        let whiteSpace = CharacterSet.whitespacesAndNewlines
        let blockName = string.trimmingCharacters(in: whiteSpace)
        if blockName.count == 0 {
            empty = true
            throw MustacheError(kind: .parseError, message: "Missing block name", templateID: token.templateID, lineNumber: token.lineNumber)
        } else if (blockName.rangeOfCharacter(from: whiteSpace) != nil) {
            empty = false
            throw MustacheError(kind: .parseError, message: "Invalid block name", templateID: token.templateID, lineNumber: token.lineNumber)
        }
        return blockName
    }
    
    fileprivate func partialNameFromString(_ string: String, inToken token: TemplateToken, empty: inout Bool) throws -> String {
        let whiteSpace = CharacterSet.whitespacesAndNewlines
        let partialName = string.trimmingCharacters(in: whiteSpace)
        if partialName.count == 0 {
            empty = true
            throw MustacheError(kind: .parseError, message: "Missing template name", templateID: token.templateID, lineNumber: token.lineNumber)
        } else if (partialName.rangeOfCharacter(from: whiteSpace) != nil) {
            empty = false
            throw MustacheError(kind: .parseError, message: "Invalid template name", templateID: token.templateID, lineNumber: token.lineNumber)
        }
        return partialName
    }
}
