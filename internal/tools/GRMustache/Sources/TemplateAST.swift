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


/// The abstract syntax tree of a template
final class TemplateAST {
    
    /// A template AST can be "defined" or "undefined".
    ///
    /// Undefined template ASTs are used when parsing templates which embed a
    /// partial tag which refers to themselves. The compiler would emit a
    /// PartialNode which contains a reference to an undefined (yet) template
    /// AST. At the end of the compilation the undefined template AST would
    /// become defined.
    ///
    /// See TemplateRepository.templateAST(named:relativeToTemplateID:error:).
    enum `Type` {
        case undefined
        case defined(nodes: [TemplateASTNode], contentType: ContentType)
    }
    var type: Type
    
    fileprivate init(type: Type) {
        self.type = type
    }
    
    
    /// Creates an undefined TemplateAST.
    convenience init() {
        self.init(type: Type.undefined)
    }
    
    /// Creates a defined TemplateAST.
    convenience init(nodes: [TemplateASTNode], contentType: ContentType) {
        self.init(type: Type.defined(nodes: nodes, contentType: contentType))
    }
    
    /// Nil if the template AST is undefined.
    var nodes: [TemplateASTNode]! {
        switch type {
        case .undefined:
            return nil
        case .defined(let nodes, _):
            return nodes
        }
    }

    /// Nil if the template AST is undefined.
    var contentType: ContentType! {
        switch type {
        case .undefined:
            return nil
        case .defined(_, let contentType):
            return contentType
        }
    }

    func updateFromTemplateAST(_ templateAST: TemplateAST) {
        self.type = templateAST.type
    }
}
