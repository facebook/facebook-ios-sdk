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


extension Expression : CustomDebugStringConvertible {
    /// A textual representation of `self`, suitable for debugging.
    var debugDescription: String {
        let string = ExpressionGenerator().stringFromExpression(self)
        return "Expression(\(string))"
    }
}

final class ExpressionGenerator {
    let configuration: Configuration
    
    init(configuration: Configuration? = nil) {
        self.configuration = configuration ?? DefaultConfiguration
    }
    
    func stringFromExpression(_ expression: Expression) -> String {
        buffer = ""
        renderExpression(expression)
        return buffer
    }
    
    func renderExpression(_ expression: Expression) {
        switch expression {
        case .implicitIterator:
            // {{ . }}
            
            buffer.append(".")
            
        case .identifier(let identifier):
            // {{ identifier }}
            
            buffer.append(identifier)
            
        case .scoped(let baseExpression, let identifier):
            // {{ <expression>.identifier }}
            
            renderExpression(baseExpression)
            buffer.append(".")
            buffer.append(identifier)
            
        case .filter(let filterExpression, let argumentExpression, _):
            // {{ <expression>(<expression>) }}
            //
            // Support for variadic filters is not implemented:
            // `f(a,b)` is rendered `f(a)(b)`.
            
            renderExpression(filterExpression)
            buffer.append("(")
            renderExpression(argumentExpression)
            buffer.append(")")
        }
    }
    
    fileprivate var buffer: String = ""
}
