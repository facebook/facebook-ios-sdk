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

final class ExpressionParser {
    
    func parse(_ string: String, empty outEmpty: inout Bool) throws -> Expression {
        enum State {
            // error
            case error(String)
            
            // Any expression can start
            case waitingForAnyExpression
            
            // Expression has started with a dot
            case leadingDot
            
            // Expression has started with an identifier
            case identifier(identifierStart: String.Index)
            
            // Parsing a scoping identifier
            case scopingIdentifier(identifierStart: String.Index, baseExpression: Expression)
            
            // Waiting for a scoping identifier
            case waitingForScopingIdentifier(baseExpression: Expression)
            
            // Parsed an expression
            case doneExpression(expression: Expression)
            
            // Parsed white space after an expression
            case doneExpressionPlusWhiteSpace(expression: Expression)
        }
        
        var state: State = .waitingForAnyExpression
        var filterExpressionStack: [Expression] = []
        
        var i = string.startIndex
        let end = string.endIndex
        stringLoop: while i < end {
            let c = string[i]
            
            switch state {
            case .error:
                break stringLoop
                
            case .waitingForAnyExpression:
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    break
                case ".":
                    state = .leadingDot
                case "(", ")", ",", "{", "}", "&", "$", "#", "^", "/", "<", ">":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                default:
                    state = .identifier(identifierStart: i)
                }
                
            case .leadingDot:
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    state = .doneExpressionPlusWhiteSpace(expression: Expression.implicitIterator)
                case ".":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                case "(":
                    filterExpressionStack.append(Expression.implicitIterator)
                    state = .waitingForAnyExpression
                case ")":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        let expression = Expression.filter(filterExpression: filterExpression, argumentExpression: Expression.implicitIterator, partialApplication: false)
                        state = .doneExpression(expression: expression)
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                case ",":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        filterExpressionStack.append(Expression.filter(filterExpression: filterExpression, argumentExpression: Expression.implicitIterator, partialApplication: true))
                        state = .waitingForAnyExpression
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                case "{", "}", "&", "$", "#", "^", "/", "<", ">":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                default:
                    state = .scopingIdentifier(identifierStart: i, baseExpression: Expression.implicitIterator)
                }
                
            case .identifier(identifierStart: let identifierStart):
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    let identifier = String(string[identifierStart..<i])
                    state = .doneExpressionPlusWhiteSpace(expression: Expression.identifier(identifier: identifier))
                case ".":
                    let identifier = String(string[identifierStart..<i])
                    state = .waitingForScopingIdentifier(baseExpression: Expression.identifier(identifier: identifier))
                case "(":
                    let identifier = String(string[identifierStart..<i])
                    filterExpressionStack.append(Expression.identifier(identifier: identifier))
                    state = .waitingForAnyExpression
                case ")":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        let identifier = String(string[identifierStart..<i])
                        let expression = Expression.filter(filterExpression: filterExpression, argumentExpression: Expression.identifier(identifier: identifier), partialApplication: false)
                        state = .doneExpression(expression: expression)
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                case ",":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        let identifier = String(string[identifierStart..<i])
                        filterExpressionStack.append(Expression.filter(filterExpression: filterExpression, argumentExpression: Expression.identifier(identifier: identifier), partialApplication: true))
                        state = .waitingForAnyExpression
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                default:
                    break
                }
                
            case .scopingIdentifier(identifierStart: let identifierStart, baseExpression: let baseExpression):
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    let identifier = String(string[identifierStart..<i])
                    let scopedExpression = Expression.scoped(baseExpression: baseExpression, identifier: identifier)
                    state = .doneExpressionPlusWhiteSpace(expression: scopedExpression)
                case ".":
                    let identifier = String(string[identifierStart..<i])
                    let scopedExpression = Expression.scoped(baseExpression: baseExpression, identifier: identifier)
                    state = .waitingForScopingIdentifier(baseExpression: scopedExpression)
                case "(":
                    let identifier = String(string[identifierStart..<i])
                    let scopedExpression = Expression.scoped(baseExpression: baseExpression, identifier: identifier)
                    filterExpressionStack.append(scopedExpression)
                    state = .waitingForAnyExpression
                case ")":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        let identifier = String(string[identifierStart..<i])
                        let scopedExpression = Expression.scoped(baseExpression: baseExpression, identifier: identifier)
                        let expression = Expression.filter(filterExpression: filterExpression, argumentExpression: scopedExpression, partialApplication: false)
                        state = .doneExpression(expression: expression)
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                case ",":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        let identifier = String(string[identifierStart..<i])
                        let scopedExpression = Expression.scoped(baseExpression: baseExpression, identifier: identifier)
                        filterExpressionStack.append(Expression.filter(filterExpression: filterExpression, argumentExpression: scopedExpression, partialApplication: true))
                        state = .waitingForAnyExpression
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                default:
                    break
                }
                
            case .waitingForScopingIdentifier(let baseExpression):
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    state = .error("Unexpected white space character at index \(string.distance(from: string.startIndex, to: i))")
                case ".":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                case "(":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                case ")":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                case ",":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                case "{", "}", "&", "$", "#", "^", "/", "<", ">":
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                default:
                    state = .scopingIdentifier(identifierStart: i, baseExpression: baseExpression)
                }
                
            case .doneExpression(let doneExpression):
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    state = .doneExpressionPlusWhiteSpace(expression: doneExpression)
                case ".":
                    state = .waitingForScopingIdentifier(baseExpression: doneExpression)
                case "(":
                    filterExpressionStack.append(doneExpression)
                    state = .waitingForAnyExpression
                case ")":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        let expression = Expression.filter(filterExpression: filterExpression, argumentExpression: doneExpression, partialApplication: false)
                        state = .doneExpression(expression: expression)
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                case ",":
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        filterExpressionStack.append(Expression.filter(filterExpression: filterExpression, argumentExpression: doneExpression, partialApplication: true))
                        state = .waitingForAnyExpression
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                default:
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                }
                
            case .doneExpressionPlusWhiteSpace(let doneExpression):
                switch c {
                case " ", "\r", "\n", "\r\n", "\t":
                    break
                case ".":
                    // Prevent "a .b"
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                case "(":
                    // Accept "a (b)"
                    filterExpressionStack.append(doneExpression)
                    state = .waitingForAnyExpression
                case ")":
                    // Accept "a(b )"
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        let expression = Expression.filter(filterExpression: filterExpression, argumentExpression: doneExpression, partialApplication: false)
                        state = .doneExpression(expression: expression)
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                case ",":
                    // Accept "a(b ,c)"
                    if let filterExpression = filterExpressionStack.last {
                        filterExpressionStack.removeLast()
                        filterExpressionStack.append(Expression.filter(filterExpression: filterExpression, argumentExpression: doneExpression, partialApplication: true))
                        state = .waitingForAnyExpression
                    } else {
                        state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                    }
                default:
                    state = .error("Unexpected character `\(c)` at index \(string.distance(from: string.startIndex, to: i))")
                }
            }
            
            i = string.index(after: i)
        }
        
        
        // Parsing done
        
        enum FinalState {
            case error(String)
            case empty
            case valid(expression: Expression)
        }
        
        let finalState: FinalState
        
        switch state {
        case .waitingForAnyExpression:
            if filterExpressionStack.isEmpty {
                finalState = .empty
            } else {
                finalState = .error("Missing `)` character at index \(string.distance(from: string.startIndex, to: string.endIndex))")
            }
            
        case .leadingDot:
            if filterExpressionStack.isEmpty {
                finalState = .valid(expression: Expression.implicitIterator)
            } else {
                finalState = .error("Missing `)` character at index \(string.distance(from: string.startIndex, to: string.endIndex))")
            }
            
        case .identifier(identifierStart: let identifierStart):
            if filterExpressionStack.isEmpty {
                let identifier = String(string[identifierStart...])
                finalState = .valid(expression: Expression.identifier(identifier: identifier))
            } else {
                finalState = .error("Missing `)` character at index \(string.distance(from: string.startIndex, to: string.endIndex))")
            }
            
        case .scopingIdentifier(identifierStart: let identifierStart, baseExpression: let baseExpression):
            if filterExpressionStack.isEmpty {
                let identifier = String(string[identifierStart...])
                let scopedExpression = Expression.scoped(baseExpression: baseExpression, identifier: identifier)
                finalState = .valid(expression: scopedExpression)
            } else {
                finalState = .error("Missing `)` character at index \(string.distance(from: string.startIndex, to: string.endIndex))")
            }
            
        case .waitingForScopingIdentifier:
            finalState = .error("Missing identifier at index \(string.distance(from: string.startIndex, to: string.endIndex))")
            
        case .doneExpression(let doneExpression):
            if filterExpressionStack.isEmpty {
                finalState = .valid(expression: doneExpression)
            } else {
                finalState = .error("Missing `)` character at index \(string.distance(from: string.startIndex, to: string.endIndex))")
            }
            
        case .doneExpressionPlusWhiteSpace(let doneExpression):
            if filterExpressionStack.isEmpty {
                finalState = .valid(expression: doneExpression)
            } else {
                finalState = .error("Missing `)` character at index \(string.distance(from: string.startIndex, to: string.endIndex))")
            }
            
        case .error(let message):
            finalState = .error(message)
        }
        
        
        // End
        
        switch finalState {
        case .empty:
            outEmpty = true
            throw MustacheError(kind: .parseError, message: "Missing expression")
            
        case .error(let description):
            outEmpty = false
            throw MustacheError(kind: .parseError, message: "Invalid expression `\(string)`: \(description)")
            
        case .valid(expression: let expression):
            return expression
        }
    }
}
