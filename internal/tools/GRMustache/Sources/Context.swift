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

/// A Context represents a state of the Mustache "context stack".
/// 
/// The context stack grows and shrinks as the Mustache engine enters and leaves
/// Mustache sections.
/// 
/// The top of the context stack is called the "current context". It is the
/// value rendered by the `{{.}}` tag:
/// 
///     // Renders "Kitty, Pussy, Melba, "
///     let template = try! Template(string: "{{#cats}}{{.}}, {{/cats}}")
///     try! template.render(["cats": ["Kitty", "Pussy", "Melba"]])
/// 
/// Key lookup starts with the current context and digs down the stack until if
/// finds a value:
/// 
///     // Renders "<child>, <parent>, "
///     let template = try! Template(string: "{{#children}}<{{name}}>, {{/children}}")
///     let data: [String: Any] = [
///       "name": "parent",
///       "children": [
///           ["name": "child"],
///           [:]    // a child without a name
///       ]
///     ]
///     try! template.render(data)
/// 
/// - seealso: Configuration
/// - seealso: TemplateRepository
/// - seealso: RenderFunction
final public class Context {
    
    // =========================================================================
    // MARK: - Creating Contexts
    
    /// Creates an empty Context.
    public convenience init() {
        self.init(type: .root)
    }
    
    /// Creates a context that contains the provided value.
    /// 
    /// - parameter value: A value.
    public convenience init(_ value: Any?) {
        self.init(type: .box(box: Box(value), parent: Context()))
    }
    
    /// Creates a context with a registered key. Registered keys are looked up
    /// first when evaluating Mustache tags.
    /// 
    /// - parameter key: An identifier.
    /// - parameter value: A value.
    public convenience init(registeredKey key: String, value: Any?) {
        self.init(type: .root, registeredKeysContext: Context([key: value]))
    }
    
    
    // =========================================================================
    // MARK: - Deriving New Contexts
    
    /// Creates a new context with the provided value pushed at the top of the
    /// context stack.
    /// 
    /// - parameter value: A value.
    /// - returns: A new context with *value* pushed at the top of the stack.
    public func extendedContext(_ value: Any?) -> Context {
        return Context(type: .box(box: Box(value), parent: self), registeredKeysContext: registeredKeysContext)
    }
    
    /// Creates a new context with the provided value registered for *key*.
    /// Registered keys are looked up first when evaluating Mustache tags.
    /// 
    /// - parameter key: An identifier.
    /// - parameter value: A value.
    /// - returns: A new context with *value* registered for *key*.
    public func extendedContext(withRegisteredValue value: Any?, forKey key: String) -> Context {
        let registeredKeysContext = (self.registeredKeysContext ?? Context()).extendedContext([key: value])
        return Context(type: self.type, registeredKeysContext: registeredKeysContext)
    }
    
    
    // =========================================================================
    // MARK: - Fetching Values from the Context Stack
    
    /// The top box of the context stack, the one that would be rendered by
    /// the `{{.}}` tag.
    public var topBox: MustacheBox {
        switch type {
        case .root:
            return EmptyBox
        case .box(box: let box, parent: _):
            return box
        case .partialOverride(partialOverride: _, parent: let parent):
            return parent.topBox
        }
    }
    
    /// Returns the boxed value stored in the context stack for the given key.
    /// 
    /// The following search pattern is used:
    /// 
    /// 1. If the key is "registered", returns the registered box for that key.
    /// 
    /// 2. Otherwise, searches the context stack for a box that has a non-empty
    ///    box for the key (see `KeyedSubscriptFunction`).
    /// 
    /// 3. If none of the above situations occurs, returns the empty box.
    /// 
    ///         let data = ["name": "Groucho Marx"]
    ///         let context = Context(data)
    /// 
    ///         // "Groucho Marx"
    ///         context.mustacheBox(forKey: "name").value
    /// 
    /// If you want the value for a full Mustache expression such as `user.name` or
    /// `uppercase(user.name)`, use the `mustacheBox(forExpression:)` method.
    /// 
    /// - parameter key: A key.
    /// - returns: The MustacheBox for *key*.
    public func mustacheBox(forKey key: String) -> MustacheBox {
        if let registeredKeysContext = registeredKeysContext {
            let box = registeredKeysContext.mustacheBox(forKey: key)
            if !box.isEmpty {
                return box
            }
        }
        
        switch type {
        case .root:
            return EmptyBox
        case .box(box: let box, parent: let parent):
            let innerBox = box.mustacheBox(forKey: key)
            if innerBox.isEmpty {
                return parent.mustacheBox(forKey: key)
            } else {
                return innerBox
            }
        case .partialOverride(partialOverride: _, parent: let parent):
            return parent.mustacheBox(forKey: key)
        }
    }
    
    /// Evaluates a Mustache expression such as `name`,
    /// or `uppercase(user.name)`.
    /// 
    ///     let data = ["person": ["name": "Albert Einstein"]]
    ///     let context = Context(data)
    /// 
    ///     // "Albert Einstein"
    ///     try! context.mustacheBoxForExpression("person.name").value
    /// 
    /// - parameter string: The expression string.
    /// - throws: MustacheError
    /// - returns: The value of the expression.
    public func mustacheBox(forExpression string: String) throws -> MustacheBox {
        let parser = ExpressionParser()
        var empty = false
        let expression = try parser.parse(string, empty: &empty)
        let invocation = ExpressionInvocation(expression: expression)
        return try invocation.invokeWithContext(self)
    }
    
    
    // =========================================================================
    // MARK: - Not public
    
    fileprivate enum `Type` {
        case root
        case box(box: MustacheBox, parent: Context)
        case partialOverride(partialOverride: TemplateASTNode.PartialOverride, parent: Context)
    }
    
    fileprivate var registeredKeysContext: Context?
    fileprivate let type: Type
    
    var willRenderStack: [WillRenderFunction] {
        switch type {
        case .root:
            return []
        case .box(box: let box, parent: let parent):
            if let willRender = box.willRender {
                return [willRender] + parent.willRenderStack
            } else {
                return parent.willRenderStack
            }
        case .partialOverride(partialOverride: _, parent: let parent):
            return parent.willRenderStack
        }
    }
    
    var didRenderStack: [DidRenderFunction] {
        switch type {
        case .root:
            return []
        case .box(box: let box, parent: let parent):
            if let didRender = box.didRender {
                return parent.didRenderStack + [didRender]
            } else {
                return parent.didRenderStack
            }
        case .partialOverride(partialOverride: _, parent: let parent):
            return parent.didRenderStack
        }
    }
    
    var partialOverrideStack: [TemplateASTNode.PartialOverride] {
        switch type {
        case .root:
            return []
        case .box(box: _, parent: let parent):
            return parent.partialOverrideStack
        case .partialOverride(partialOverride: let partialOverride, parent: let parent):
            return [partialOverride] + parent.partialOverrideStack
        }
    }
    
    fileprivate init(type: Type, registeredKeysContext: Context? = nil) {
        self.type = type
        self.registeredKeysContext = registeredKeysContext
    }

    func extendedContext(partialOverride: TemplateASTNode.PartialOverride) -> Context {
        return Context(type: .partialOverride(partialOverride: partialOverride, parent: self), registeredKeysContext: registeredKeysContext)
    }
}

extension Context: CustomDebugStringConvertible {
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        switch type {
        case .root:
            return "Context.Root"
        case .box(box: let box, parent: let parent):
            return "Context.Box(\(box)):\(parent.debugDescription)"
        case .partialOverride(partialOverride: _, parent: let parent):
            return "Context.PartialOverride:\(parent.debugDescription)"
        }
    }
}
