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


/// The MustacheBoxable protocol gives any type the ability to feed Mustache
/// templates.
///
/// It is adopted by the standard types Bool, Int, Double, String, NSObject...
///
/// Your own types can conform to it as well, so that they can feed templates:
///
///     extension Profile: MustacheBoxable { ... }
///
///     let profile = ...
///     let template = try! Template(named: "Profile")
///     let rendering = try! template.render(profile)
public protocol MustacheBoxable {
    
    /// Returns a `MustacheBox` that describes how your type interacts with the
    /// rendering engine.
    ///
    /// You can for example box another value that is already boxable, such as
    /// a dictionary:
    ///
    ///     struct Person {
    ///         let firstName: String
    ///         let lastName: String
    ///     }
    ///
    ///     extension Person : MustacheBoxable {
    ///         // Expose the `firstName`, `lastName` and `fullName` keys to
    ///         // Mustache templates:
    ///         var mustacheBox: MustacheBox {
    ///             return Box([
    ///                 "firstName": firstName,
    ///                 "lastName": lastName,
    ///                 "fullName": "\(self.firstName) \(self.lastName)",
    ///             ])
    ///         }
    ///     }
    ///
    ///     let person = Person(firstName: "Tom", lastName: "Selleck")
    ///
    ///     // Renders "Tom Selleck"
    ///     let template = try! Template(string: "{{person.fullName}}")
    ///     try! template.render(["person": person])
    var mustacheBox: MustacheBox { get }
}

@objc extension MustacheBox {
    
    /// `MustacheBox` adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates. Its mustacheBox property returns itself.
    @objc public override var mustacheBox: MustacheBox {
        return self
    }
}


/// Returns a MustacheBox that allows *value* to feed Mustache templates.
///
/// The returned box depends on the type of the value:
///
///
/// ## MustacheBoxable
///
/// For values that adopt the MustacheBoxable protocol, the `Box` function
/// returns their mustacheBox property.
///
///
/// ## Arrays
///
/// Arrays can feed Mustache templates.
///
///     let array = [1,2,3]
///
///     // Renders "123"
///     let template = try! Template(string: "{{#array}}{{.}}{{/array}}")
///     try! template.render(["array": array])
///
///
/// ### Rendering
///
/// - `{{array}}` renders the concatenation of the array items.
///
/// - `{{#array}}...{{/array}}` renders as many times as there are items in
///   `array`, pushing each item on its turn on the top of the context stack.
///
/// - `{{^array}}...{{/array}}` renders if and only if `array` is empty.
///
///
/// ### Keys exposed to templates
///
/// An array can be queried for the following keys:
///
/// - `count`: number of elements in the array
/// - `first`: the first object in the array
/// - `last`: the last object in the array
///
/// Because 0 (zero) is falsey, `{{#array.count}}...{{/array.count}}` renders
/// once, if and only if `array` is not empty.
///
///
/// ## Sets
///
/// Sets can feed Mustache templates.
///
///     let set:Set<Int> = [1,2,3]
///
///     // Renders "132", or "231", etc.
///     let template = try! Template(string: "{{#set}}{{.}}{{/set}}")
///     try! template.render(["set": set])
///
///
/// ### Rendering
///
/// - `{{set}}` renders the concatenation of the set items.
///
/// - `{{#set}}...{{/set}}` renders as many times as there are items in `set`,
///   pushing each item on its turn on the top of the context stack.
///
/// - `{{^set}}...{{/set}}` renders if and only if `set` is empty.
///
///
/// ### Keys exposed to templates
///
/// A set can be queried for the following keys:
///
/// - `count`: number of elements in the set
/// - `first`: the first object in the set
///
/// Because 0 (zero) is falsey, `{{#set.count}}...{{/set.count}}` renders once,
/// if and only if `set` is not empty.
///
///
/// ## Dictionaries
///
/// A dictionary can feed Mustache templates.
///
///     let dictionary: [String: String] = [
///         "firstName": "Freddy",
///         "lastName": "Mercury"]
///
///     // Renders "Freddy Mercury"
///     let template = try! Template(string: "{{firstName}} {{lastName}}")
///     let rendering = try! template.render(dictionary)
///
///
/// ### Rendering
///
/// - `{{dictionary}}` renders the built-in Swift String Interpolation of the
///   dictionary.
///
/// - `{{#dictionary}}...{{/dictionary}}` pushes the dictionary on the top of the
///   context stack, and renders the section once.
///
/// - `{{^dictionary}}...{{/dictionary}}` does not render.
///
///
/// In order to iterate over the key/value pairs of a dictionary, use the `each`
/// filter from the Standard Library:
///
///     // Register StandardLibrary.each for the key "each":
///     let template = try! Template(string: "<{{# each(dictionary) }}{{@key}}:{{.}}, {{/}}>")
///     template.register(StandardLibrary.each, forKey: "each")
///
///     // Renders "<firstName:Freddy, lastName:Mercury,>"
///     let dictionary: [String: String] = ["firstName": "Freddy", "lastName": "Mercury"]
///     let rendering = try! template.render(["dictionary": dictionary])
///
///
/// ## FilterFunction, RenderFunction, WillRenderFunction, DidRenderFunction, KeyedSubscriptFunction
///
/// Those functions are boxed as customized boxes.
///
/// ## Other Values
///
/// Other values (including nil) are discarded as empty boxes.
///
/// - parameter value: A value.
/// - returns: A MustacheBox.
public func Box(_ value: Any?) -> MustacheBox {
    guard let value = value else {
        return EmptyBox
    }
    
    switch value {
    case let boxable as MustacheBoxable:
        return boxable.mustacheBox
    case let array as [Any?]:
        return MustacheBox(array: array)
    case let set as Set<AnyHashable>:
        return MustacheBox(set: set)
    case let dictionary as [AnyHashable: Any?]:
        return MustacheBox(dictionary: dictionary)
    case let filter as FilterFunction:
        return MustacheBox(filter: filter)
    case let render as RenderFunction:
        return MustacheBox(render: render)
    case let willRender as WillRenderFunction:
        return MustacheBox(willRender: willRender)
    case let didRender as DidRenderFunction:
        return MustacheBox(didRender: didRender)
    case let f as KeyedSubscriptFunction:
        return MustacheBox(keyedSubscript: f)
    default:
        NSLog("%@", "Mustache warning: \(String(reflecting: value)) of type \(type(of: value)) is not MustacheBoxable, Array, Set, Dictionary, and is discarded.")
        return EmptyBox
    }
}


/// Concatenates the rendering of the collection items.
///
/// There are two tricks when rendering collections:
///
/// 1. Items can render as Text or HTML, and our collection should render with
///    the same type. It is an error to mix content types.
///
/// 2. We have to tell items that they are rendered as an enumeration item.
///    This allows collections to avoid enumerating their items when they are
///    part of another collections:
///
///         {{# arrays }}  // Each array renders as an enumeration item, and has itself enter the context stack.
///           {{#.}}       // Each array renders "normally", and enumerates its items
///             ...
///           {{/.}}
///         {{/ arrays }}
///
/// - parameter info: A RenderingInfo
/// - parameter box: A closure that turns collection items into a
///   MustacheBox.
/// - returns: A Rendering
private func concatenateRenderings(array: [Any?], info: RenderingInfo) throws -> Rendering {
    // Prepare the rendering. We don't known the contentType yet: it depends on items
    var buffer = ""
    var contentType: ContentType? = nil
    
    // Tell items they are rendered as an enumeration item.
    //
    // Some values don't render the same whenever they render as an
    // enumeration item, or alone: {{# values }}...{{/ values }} vs.
    // {{# value }}...{{/ value }}.
    //
    // This is the case of Int, UInt, Double, Bool: they enter the context
    // stack when used in an iteration, and do not enter the context stack
    // when used as a boolean.
    //
    // This is also the case of collections: they enter the context stack
    // when used as an item of a collection, and enumerate their items when
    // used as a collection.
    var info = info
    info.enumerationItem = true
    
    for element in array {
        let boxRendering = try Box(element).render(info)
        if contentType == nil
        {
            // First element: now we know our contentType
            contentType = boxRendering.contentType
            buffer += boxRendering.string
        }
        else if contentType == boxRendering.contentType
        {
            // Consistent content type: keep on buffering.
            buffer += boxRendering.string
        }
        else
        {
            // Inconsistent content type: this is an error. How are we
            // supposed to mix Text and HTML?
            throw MustacheError(kind: .renderError, message: "Content type mismatch")
        }
    }
    
    if let contentType = contentType {
        // {{ collection }}
        // {{# collection }}...{{/ collection }}
        //
        // We know our contentType, hence the collection is not empty and
        // we render our buffer.
        return Rendering(buffer, contentType)
    } else {
        // {{ collection }}
        //
        // We don't know our contentType, hence the collection is empty.
        //
        // Now this code is executed. This means that the collection is
        // rendered, despite its emptiness.
        //
        // We are not rendering a regular {{# section }} tag, because empty
        // collections have a false boolValue, and RenderingEngine would prevent
        // us to render.
        //
        // We are not rendering an inverted {{^ section }} tag, because
        // RenderingEngine takes care of the rendering of inverted sections.
        //
        // So we are rendering a {{ variable }} tag. As en empty collection, we
        // must return an empty rendering.
        //
        // Renderings have a content type. In order to render an empty
        // rendering that has the contentType of the tag, let's use the
        // `render` method of the tag.
        return try info.tag.render(info.context)
    }
}

extension MustacheBox {
    
    convenience init(array: [Any?]) {
        self.init(
            converter: MustacheBox.Converter(arrayValue: { array.map { Box($0) } }),
            value: array,
            boolValue: !array.isEmpty,
            keyedSubscript: { key in
                switch key {
                case "first":   // C: CollectionType
                    if let first = array.first {
                        return Box(first)
                    } else {
                        return EmptyBox
                    }
                case "last":    // C.Index: BidirectionalIndexType
                    if let last = array.last {
                        return Box(last)
                    } else {
                        return EmptyBox
                    }
                case "count":   // C.IndexDistance == Int
                    return Box(array.count)
                default:
                    return EmptyBox
                }
            },
            render: { (info: RenderingInfo) in
                if info.enumerationItem {
                    // {{# collections }}...{{/ collections }}
                    return try info.tag.render(info.context.extendedContext(array))
                } else {
                    // {{ collection }}
                    // {{# collection }}...{{/ collection }}
                    return try concatenateRenderings(array: array, info: info)
                }
        })
    }
    
    convenience init<Element>(set: Set<Element>) {
        self.init(
            converter: MustacheBox.Converter(arrayValue: { set.map({ Box($0) }) }),
            value: set,
            boolValue: !set.isEmpty,
            keyedSubscript: { (key) in
                switch key {
                case "first":   // C: CollectionType
                    if let first = set.first {
                        return Box(first)
                    } else {
                        return EmptyBox
                    }
                case "count":   // C.IndexDistance == Int
                    return Box(set.count)
                default:
                    return EmptyBox
                }
            },
            render: { (info: RenderingInfo) in
                if info.enumerationItem {
                    // {{# collections }}...{{/ collections }}
                    return try info.tag.render(info.context.extendedContext(set))
                } else {
                    // {{ collection }}
                    // {{# collection }}...{{/ collection }}
                    return try concatenateRenderings(array: Array(set), info: info)
                }
            }
        )
    }
    
    convenience init(dictionary: [AnyHashable: Any?]) {
        self.init(
            converter: MustacheBox.Converter(dictionaryValue: {
                var boxDictionary: [String: MustacheBox] = [:]
                for (key, value) in dictionary {
                    if let key = key as? String {
                        boxDictionary[key] = Box(value)
                    } else {
                        NSLog("Mustache: non-string key in dictionary (\(key)) is discarded.")
                    }
                }
                return boxDictionary
            }),
            value: dictionary,
            keyedSubscript: { (key: String) in
                if let value = dictionary[key] {
                    return Box(value)
                } else {
                    return EmptyBox
                }
        })
    }
}

let EmptyBox = MustacheBox()
