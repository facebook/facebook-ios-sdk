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

/// The type for expressions that appear in tags: `name`, `user.name`,
/// `uppercase(user.name)`, etc.
enum Expression {
    
    // {{ . }}
    case implicitIterator

    // {{ identifier }}
    case identifier(identifier: String)
    
    // {{ <expression>.identifier }}
    indirect case scoped(baseExpression: Expression, identifier: String)
    
    // {{ <expression>(<expression>) }}
    indirect case filter(filterExpression: Expression, argumentExpression: Expression, partialApplication: Bool)
}

/// Expression conforms to Equatable so that the Compiler can check that section
/// tags have matching openings and closings: {{# person }}...{{/ person }} is
/// OK but {{# foo }}...{{/ bar }} is not.
extension Expression: Equatable {
}

func ==(lhs: Expression, rhs: Expression) -> Bool {
    switch (lhs, rhs) {
    case (.implicitIterator, .implicitIterator):
        return true
        
    case (.identifier(let lIdentifier), .identifier(let rIdentifier)):
        return lIdentifier == rIdentifier
        
    case (.scoped(let lBase, let lIdentifier), .scoped(let rBase, let rIdentifier)):
        return lBase == rBase && lIdentifier == rIdentifier
        
    case (.filter(let lFilter, let lArgument, let lPartialApplication), .filter(let rFilter, let rArgument, let rPartialApplication)):
        return lFilter == rFilter && lArgument == rArgument && lPartialApplication == rPartialApplication
        
    default:
        return false
    }
}
