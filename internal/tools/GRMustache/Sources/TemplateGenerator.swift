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


extension TemplateAST : CustomDebugStringConvertible {
    /// A textual representation of `self`, suitable for debugging.
    var debugDescription: String {
        let string = TemplateGenerator().stringFromTemplateAST(self)
        return "TemplateAST(\(string.debugDescription))"
    }
}

extension Template : CustomDebugStringConvertible {
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        let string = TemplateGenerator().stringFromTemplateAST(templateAST)
        return "Template(\(string.debugDescription))"
    }
}

final class TemplateGenerator {
    let configuration: Configuration
    
    init(configuration: Configuration? = nil) {
        self.configuration = configuration ?? DefaultConfiguration
    }
    
    func stringFromTemplateAST(_ templateAST: TemplateAST) -> String {
        buffer = ""
        renderTemplateAST(templateAST)
        return buffer
    }
    
    fileprivate func renderTemplateAST(_ templateAST: TemplateAST) {
        for node in templateAST.nodes {
            renderTemplateASTNode(node)
        }
    }
    
    func renderTemplateASTNode(_ node: TemplateASTNode) {
        switch node {
        case .blockNode(let block):
            let tagStartDelimiter = configuration.tagDelimiterPair.0
            let tagEndDelimiter = configuration.tagDelimiterPair.1
            let name = block.name
            buffer.append("\(tagStartDelimiter)$\(name)\(tagEndDelimiter)")
            renderTemplateAST(block.innerTemplateAST)
            buffer.append("\(tagStartDelimiter)/\(name)\(tagEndDelimiter)")
            
        case .partialOverrideNode(let partialOverride):
            let tagStartDelimiter = configuration.tagDelimiterPair.0
            let tagEndDelimiter = configuration.tagDelimiterPair.1
            let name = partialOverride.parentPartial.name ?? "<null>"
            buffer.append("\(tagStartDelimiter)<\(name)\(tagEndDelimiter)")
            renderTemplateAST(partialOverride.childTemplateAST)
            buffer.append("\(tagStartDelimiter)/\(name)\(tagEndDelimiter)")
            
        case .partialNode(let partial):
            let tagStartDelimiter = configuration.tagDelimiterPair.0
            let tagEndDelimiter = configuration.tagDelimiterPair.1
            let name = partial.name ?? "<null>"
            buffer.append("\(tagStartDelimiter)>\(name)\(tagEndDelimiter)")
            
        case .sectionNode(let section):
            // Change delimiters tags are ignored. Always use configuration tag
            // delimiters.
            let tagStartDelimiter = configuration.tagDelimiterPair.0
            let tagEndDelimiter = configuration.tagDelimiterPair.1
            let expression = ExpressionGenerator().stringFromExpression(section.expression)
            if section.inverted {
                buffer.append("\(tagStartDelimiter)^\(expression)\(tagEndDelimiter)")
            } else {
                buffer.append("\(tagStartDelimiter)#\(expression)\(tagEndDelimiter)")
            }
            renderTemplateAST(section.tag.innerTemplateAST)
            buffer.append("\(tagStartDelimiter)/\(expression)\(tagEndDelimiter)")
            
        case .textNode(let text):
            buffer.append(text)
            
        case .variableNode(let variable):
            // Change delimiters tags are ignored. Always use configuration tag
            // delimiters.
            let tagStartDelimiter = configuration.tagDelimiterPair.0
            let tagEndDelimiter = configuration.tagDelimiterPair.1
            let expression = ExpressionGenerator().stringFromExpression(variable.expression)
            if variable.escapesHTML {
                buffer.append("\(tagStartDelimiter)\(expression)\(tagEndDelimiter)")
            } else if tagStartDelimiter == "{{" && tagEndDelimiter == "}}" {
                buffer.append("\(tagStartDelimiter){\(expression)}\(tagEndDelimiter)")
            } else {
                buffer.append("\(tagStartDelimiter)&\(expression)\(tagEndDelimiter)")
            }
        }
    }
    
    fileprivate var buffer: String = ""
}
