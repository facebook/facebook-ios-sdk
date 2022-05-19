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


/// Mustache templates don't eat raw values: they eat values boxed
/// in `MustacheBox`.
/// 
/// Boxing is generally automatic:
/// 
///     // The render method automatically boxes the dictionary:
///     template.render(["name": "Arthur"])
/// 
/// **Warning**: the fact that `MustacheBox` is a subclass of NSObject is an
/// implementation detail that is enforced by the Swift language itself. This
/// may change in the future: do not rely on it.
final public class MustacheBox : NSObject {
    
    // IMPLEMENTATION NOTE
    //
    // Why is MustacheBox a subclass of NSObject, and not, say, a Swift struct?
    //
    // Swift does not allow a class extension to override a method that is
    // inherited from an extension to its superclass and incompatible with
    // Objective-C.
    //
    // If MustacheBox were a pure Swift type, this Swift limit would prevent
    // NSObject subclasses such as NSNull, NSNumber, etc. to override
    // MustacheBoxable.mustacheBox, and provide custom rendering behavior.
    //
    // For an example of this limitation, see example below:
    //
    //     import Foundation
    //     
    //     // A type that is not compatible with Objective-C
    //     struct MustacheBox { }
    //     
    //     // So far so good
    //     extension NSObject {
    //         var mustacheBox: MustacheBox { return MustacheBox() }
    //     }
    //     
    //     // Error: declarations in extensions cannot override yet
    //     extension NSNull {
    //         override var mustacheBox: MustacheBox { return MustacheBox() }
    //     }
    //
    // This problem does not apply to Objc-C compatible protocols:
    //
    //     import Foundation
    //     
    //     // So far so good
    //     extension NSObject {
    //         var prop: String { return "NSObject" }
    //     }
    //     
    //     // No error
    //     extension NSNull {
    //         override var prop: String { return "NSNull" }
    //     }
    //     
    //     NSObject().prop // "NSObject"
    //     NSNull().prop   // "NSNull"
    //
    // In order to let the user easily override NSObject.mustacheBox, we had to
    // keep its return type compatible with Objective-C, that is to say make
    // MustacheBox a subclass of NSObject.
    

    // -------------------------------------------------------------------------
    // MARK: - The boxed value
    
    /// The boxed value.
    public let value: Any?
    
    /// The only empty box is `Box()`.
    public let isEmpty: Bool
    
    /// The boolean value of the box.
    /// 
    /// It tells whether the Box should trigger or prevent the rendering of
    /// regular `{{#section}}...{{/}}` and inverted `{{^section}}...{{/}}`.
    public let boolValue: Bool
    
    /// If the boxed value can be iterated (array or set), returns an array
    /// of `MustacheBox`.
    public var arrayValue: [MustacheBox]? {
        return converter?.arrayValue()
    }
    
    /// If the boxed value is a dictionary, returns a `[String: MustacheBox]`.
    public var dictionaryValue: [String: MustacheBox]? {
        return converter?.dictionaryValue()
    }
    
    /// Extracts a key out of a box.
    /// 
    ///     let box = Box(["firstName": "Arthur"])
    ///     box.mustacheBox(forKey: "firstName").value  // "Arthur"
    /// 
    /// - parameter key: A key.
    /// - returns: The MustacheBox for *key*.
    public func mustacheBox(forKey key: String) -> MustacheBox {
        guard let keyedSubscript = keyedSubscript else {
            return EmptyBox
        }
        return Box(keyedSubscript(key))
    }

    public func render(_ info: RenderingInfo) throws -> Rendering {
        return try self._render(info)
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Other facets
    
    fileprivate var _render: RenderFunction
    
    /// See the documentation of `FilterFunction`.
    public let filter: FilterFunction?
    
    /// See the documentation of `WillRenderFunction`.
    public let willRender: WillRenderFunction?
    
    /// See the documentation of `DidRenderFunction`.
    public let didRender: DidRenderFunction?
    
    
    // -------------------------------------------------------------------------
    // MARK: - Multi-facetted Box Initialization
    
    /// This is the low-level initializer of MustacheBox, suited for building
    /// "advanced" boxes.
    /// 
    /// This initializer can take up to seven parameters, all optional, that
    /// define how the box interacts with the Mustache engine:
    /// 
    /// - `value`:          an optional boxed value
    /// - `boolValue`:      an optional boolean value for the Box.
    /// - `keyedSubscript`: an optional KeyedSubscriptFunction
    /// - `filter`:         an optional FilterFunction
    /// - `render`:         an optional RenderFunction
    /// - `willRender`:     an optional WillRenderFunction
    /// - `didRender`:      an optional DidRenderFunction
    /// 
    /// 
    /// To illustrate the usage of all those parameters, let's look at how the
    /// `{{f(a)}}` tag is rendered.
    /// 
    /// First the `a` and `f` expressions are evaluated. The Mustache engine
    /// looks in the context stack for boxes whose *keyedSubscript* return
    /// non-empty boxes for the keys "a" and "f". Let's call them aBox and fBox.
    /// 
    /// Then the *filter* of the fBox is evaluated with aBox as an argument. It
    /// is likely that the result depends on the *value* of the aBox: it is the
    /// resultBox.
    /// 
    /// Then the Mustache engine is ready to render resultBox. It looks in the
    /// context stack for boxes whose *willRender* function is defined. Those
    /// willRender functions have the opportunity to process the resultBox, and
    /// eventually provide the box that will be actually rendered:
    /// the renderedBox.
    /// 
    /// The renderedBox has a *render* function: it is evaluated by the Mustache
    /// engine which appends its result to the final rendering.
    /// 
    /// Finally the Mustache engine looks in the context stack for boxes whose
    /// *didRender* function is defined, and call them.
    /// 
    /// 
    /// ### value
    /// 
    /// The optional `value` parameter gives the boxed value. The value is used
    /// when the box is rendered (unless you provide a custom RenderFunction).
    /// It is also returned by the `value` property of MustacheBox.
    /// 
    ///     let aBox = MustacheBox(value: 1)
    /// 
    ///     // Renders "1"
    ///     let template = try! Template(string: "{{a}}")
    ///     try! template.render(["a": aBox])
    /// 
    /// 
    /// ### boolValue
    /// 
    /// The optional `boolValue` parameter tells whether the Box should trigger
    /// or prevent the rendering of regular `{{#section}}...{{/}}` and inverted
    /// `{{^section}}...{{/}}` tags. The default boolValue is true, unless the
    /// Box is initialized without argument to build the empty box.
    /// 
    ///     // Render "true", then "false"
    ///     let template = try! Template(string:"{{#.}}true{{/.}}{{^.}}false{{/.}}")
    ///     try! template.render(MustacheBox(boolValue: true))
    ///     try! template.render(MustacheBox(boolValue: false))
    /// 
    /// 
    /// ### keyedSubscript
    /// 
    /// The optional `keyedSubscript` parameter is a `KeyedSubscriptFunction`
    /// that lets the Mustache engine extract keys out of the box. For example,
    /// the `{{a}}` tag would call the subscript function with `"a"` as an
    /// argument, and render the returned box.
    /// 
    /// The default value is nil, which means that no key can be extracted.
    /// 
    /// See `KeyedSubscriptFunction` for a full discussion of this type.
    /// 
    ///     let box = MustacheBox(keyedSubscript: { (key: String) in
    ///         return Box("key:\(key)")
    ///     })
    /// 
    ///     // Renders "key:a"
    ///     let template = try! Template(string:"{{a}}")
    ///     try! template.render(box)
    /// 
    /// 
    /// ### filter
    /// 
    /// The optional `filter` parameter is a `FilterFunction` that lets the
    /// Mustache engine evaluate filtered expression that involve the box. The
    /// default value is nil, which means that the box can not be used as
    /// a filter.
    /// 
    /// See `FilterFunction` for a full discussion of this type.
    /// 
    ///     let box = MustacheBox(filter: Filter { (x: Int?) in
    ///         return Box(x! * x!)
    ///     })
    /// 
    ///     // Renders "100"
    ///     let template = try! Template(string:"{{square(x)}}")
    ///     try! template.render(["square": box, "x": 10])
    /// 
    /// 
    /// ### render
    /// 
    /// The optional `render` parameter is a `RenderFunction` that is evaluated
    /// when the Box is rendered.
    /// 
    /// The default value is nil, which makes the box perform default Mustache
    /// rendering:
    /// 
    /// - `{{box}}` renders the built-in Swift String Interpolation of the value,
    ///   HTML-escaped.
    /// 
    /// - `{{{box}}}` renders the built-in Swift String Interpolation of the
    ///   value, not HTML-escaped.
    /// 
    /// - `{{#box}}...{{/box}}` does not render if `boolValue` is false.
    ///   Otherwise, it pushes the box on the top of the context stack, and
    ///   renders the section once.
    /// 
    /// - `{{^box}}...{{/box}}` renders once if `boolValue` is false. Otherwise,
    ///   it does not render.
    /// 
    /// See `RenderFunction` for a full discussion of this type.
    /// 
    ///     let box = MustacheBox(render: { (info: RenderingInfo) in
    ///         return Rendering("foo")
    ///     })
    /// 
    ///     // Renders "foo"
    ///     let template = try! Template(string:"{{.}}")
    ///     try! template.render(box)
    /// 
    /// 
    /// ### willRender, didRender
    /// 
    /// The optional `willRender` and `didRender` parameters are a
    /// `WillRenderFunction` and `DidRenderFunction` that are evaluated for all
    /// tags as long as the box is in the context stack.
    /// 
    /// See `WillRenderFunction` and `DidRenderFunction` for a full discussion of
    /// those types.
    /// 
    ///     let box = MustacheBox(willRender: { (tag: Tag, box: MustacheBox) in
    ///         return Box("baz")
    ///     })
    /// 
    ///     // Renders "baz baz"
    ///     let template = try! Template(string:"{{#.}}{{foo}} {{bar}}{{/.}}")
    ///     try! template.render(box)
    /// 
    /// 
    /// ### Multi-facetted boxes
    /// 
    /// By mixing all those parameters, you can finely tune the behavior of
    /// a box.
    /// 
    /// GRMustache source code ships a few multi-facetted boxes, which may
    /// inspire you. See for example:
    /// 
    /// - Formatter.mustacheBox
    /// - HTMLEscape.mustacheBox
    /// - StandardLibrary.Localizer.mustacheBox
    /// 
    /// Let's give an example:
    /// 
    ///     // A regular type:
    /// 
    ///     struct Person {
    ///         let firstName: String
    ///         let lastName: String
    ///     }
    /// 
    /// We want:
    /// 
    /// 1. `{{person.firstName}}` and `{{person.lastName}}` should render the
    ///    matching properties.
    /// 2. `{{person}}` should render the concatenation of the first and last names.
    /// 
    /// We'll provide a `KeyedSubscriptFunction` to implement 1, and a
    /// `RenderFunction` to implement 2:
    /// 
    ///     // Have Person conform to MustacheBoxable so that we can box people, and
    ///     // render them:
    /// 
    ///     extension Person : MustacheBoxable {
    ///         
    ///         // MustacheBoxable protocol requires objects to implement this property
    ///         // and return a MustacheBox:
    ///         
    ///         var mustacheBox: MustacheBox {
    ///             
    ///             // A person is a multi-facetted object:
    ///             return MustacheBox(
    ///                 // It has a value:
    ///                 value: self,
    ///                 
    ///                 // It lets Mustache extracts properties by name:
    ///                 keyedSubscript: { (key: String) -> Any? in
    ///                     switch key {
    ///                     case "firstName": return self.firstName
    ///                     case "lastName":  return self.lastName
    ///                     default:          return nil
    ///                     }
    ///                 },
    ///                 
    ///                 // It performs custom rendering:
    ///                 render: { (info: RenderingInfo) -> Rendering in
    ///                     switch info.tag.type {
    ///                     case .variable:
    ///                         // {{ person }}
    ///                         return Rendering("\(self.firstName) \(self.lastName)")
    ///                     case .section:
    ///                         // {{# person }}...{{/}}
    ///                         //
    ///                         // Perform the default rendering: push self on the top
    ///                         // of the context stack, and render the section:
    ///                         let context = info.context.extendedContext(Box(self))
    ///                         return try info.tag.render(context)
    ///                     }
    ///                 }
    ///             )
    ///         }
    ///     }
    /// 
    ///     // Renders "The person is Errol Flynn"
    ///     let person = Person(firstName: "Errol", lastName: "Flynn")
    ///     let template = try! Template(string: "{{# person }}The person is {{.}}{{/ person }}")
    ///     try! template.render(["person": person])
    /// 
    /// - parameter value:          An optional boxed value.
    /// - parameter boolValue:      An optional boolean value for the Box.
    /// - parameter keyedSubscript: An optional `KeyedSubscriptFunction`.
    /// - parameter filter:         An optional `FilterFunction`.
    /// - parameter render:         An optional `RenderFunction`.
    /// - parameter willRender:     An optional `WillRenderFunction`.
    /// - parameter didRender:      An optional `DidRenderFunction`.
    /// - returns: A MustacheBox.
    public convenience init(
        value: Any? = nil,
        boolValue: Bool? = nil,
        keyedSubscript: KeyedSubscriptFunction? = nil,
        filter: FilterFunction? = nil,
        render: RenderFunction? = nil,
        willRender: WillRenderFunction? = nil,
        didRender: DidRenderFunction? = nil)
    {
        self.init(
            converter: nil,
            value: value,
            boolValue: boolValue,
            keyedSubscript: keyedSubscript,
            filter: filter,
            render: render,
            willRender: willRender,
            didRender: didRender)
    }

    
    // -------------------------------------------------------------------------
    // MARK: - Internal
    
    let keyedSubscript: KeyedSubscriptFunction?
    let converter: Converter?
    
    init(
        converter: Converter?,
        value: Any? = nil,
        boolValue: Bool? = nil,
        keyedSubscript: KeyedSubscriptFunction? = nil,
        filter: FilterFunction? = nil,
        render: RenderFunction? = nil,
        willRender: WillRenderFunction? = nil,
        didRender: DidRenderFunction? = nil)
    {
        let empty = (value == nil) && (keyedSubscript == nil) && (render == nil) && (filter == nil) && (willRender == nil) && (didRender == nil)
        self.isEmpty = empty
        self.value = value
        self.converter = converter
        self.boolValue = boolValue ?? !empty
        self.keyedSubscript = keyedSubscript
        self.filter = filter
        self.willRender = willRender
        self.didRender = didRender
        if let render = render {
            self.hasCustomRenderFunction = true
            self._render = render
            super.init()
        } else {
            // The default render function: it renders {{variable}} tags as the
            // boxed value, and {{#section}}...{{/}} tags by adding the box to
            // the context stack.
            //
            // IMPLEMENTATIN NOTE
            //
            // We have to set self.render twice in order to avoid the compiler
            // error: "variable 'self.render' captured by a closure before being
            // initialized"
            self._render = { (_) in return Rendering("") }
            self.hasCustomRenderFunction = false
            super.init()
            self._render = { [unowned self] (info: RenderingInfo) in
                
                // Default rendering depends on the tag type:
                switch info.tag.type {
                case .variable:
                    // {{ box }} and {{{ box }}}
                    
                    if let value = self.value {
                        // Use the built-in Swift String Interpolation:
                        return Rendering("\(value)", .text)
                    } else {
                        return Rendering("", .text)
                    }
                case .section:
                    // {{# box }}...{{/ box }}
                    
                    // Push the value on the top of the context stack:
                    let context = info.context.extendedContext(self)
                    
                    // Renders the inner content of the section tag:
                    return try info.tag.render(context)
                }
            }
        }
    }
    
    fileprivate let hasCustomRenderFunction: Bool
    
    // Converter wraps all the conversion closures that help MustacheBox expose
    // its raw value (typed Any) as useful types.
    struct Converter {
        let arrayValue: (() -> [MustacheBox]?)
        let dictionaryValue: (() -> [String: MustacheBox]?)
        
        init(
            arrayValue: (() -> [MustacheBox])? = nil,
            dictionaryValue: (() -> [String: MustacheBox]?)? = nil)
        {
            self.arrayValue = arrayValue ?? { nil }
            self.dictionaryValue = dictionaryValue ?? { nil }
        }
    }
}

extension MustacheBox {
    /// A textual representation of `self`.
    override public var description: String {
        let facets = self.facetsDescriptions
        switch facets.count {
        case 0:
            return "MustacheBox(Empty)"
        default:
            let content = facets.joined(separator: ",")
            return "MustacheBox(\(content))"
        }
    }
}

extension MustacheBox {
    /// A textual representation of the boxed value. Useful for debugging.
    public var valueDescription: String {
        let facets = self.facetsDescriptions
        switch facets.count {
        case 0:
            return "Empty"
        case 1:
            return facets.first!
        default:
            return "(" + facets.joined(separator: ",") + ")"
        }
    }
    
    var facetsDescriptions: [String] {
        var facets = [String]()
        if let array = arrayValue {
            let items = array.map { $0.valueDescription }.joined(separator: ",")
            facets.append("[\(items)]")
        } else if let dictionary = dictionaryValue {
            if dictionary.isEmpty {
                facets.append("[:]")
            } else {
                let items = dictionary.map { (key, box) in
                    return "\(String(reflecting: key)):\(box.valueDescription)"
                }.joined(separator: ",")
                facets.append("[\(items)]")
            }
        } else if let value = value {
            facets.append(String(reflecting: value))
        }
        
        if let _ = filter {
            facets.append("FilterFunction")
        }
        if let _ = willRender {
            facets.append("WillRenderFunction")
        }
        if let _ = didRender {
            facets.append("DidRenderFunction")
        }
        if value == nil && hasCustomRenderFunction {
            facets.append("RenderFunction")
        }
        
        return facets
    }
}
