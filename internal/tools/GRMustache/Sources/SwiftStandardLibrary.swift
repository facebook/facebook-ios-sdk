// The MIT License
//
// Copyright (c) 2016 Gwendal Roué
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


/// GRMustache provides built-in support for rendering `Double`.
extension Double : MustacheBoxable {
    
    /// `Double` adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{double}}` is rendered with built-in Swift String Interpolation.
    /// Custom formatting can be explicitly required with NumberFormatter, as in
    /// `{{format(a)}}` (see `Formatter`).
    /// 
    /// - `{{#double}}...{{/double}}` renders if and only if `double` is not 0 (zero).
    /// 
    /// - `{{^double}}...{{/double}}` renders if and only if `double` is 0 (zero).
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: (self != 0.0),
            render: { (info: RenderingInfo) in
                switch info.tag.type {
                case .variable:
                    // {{ double }}
                    return Rendering("\(self)")
                case .section:
                    if info.enumerationItem {
                        // {{# doubles }}...{{/ doubles }}
                        return try info.tag.render(info.context.extendedContext(Box(self)))
                    } else {
                        // {{# double }}...{{/ double }}
                        //
                        // Doubles do not enter the context stack when used in a
                        // boolean section.
                        //
                        // This behavior must not change:
                        // https://github.com/groue/GRMustache/issues/83
                        return try info.tag.render(info.context)
                    }
                }
        })
    }
}


/// GRMustache provides built-in support for rendering `Float`.
extension Float : MustacheBoxable {
    
    /// `Float` adopts the `MustacheBoxable` protocol so that it can feed Mustache
    /// templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{float}}` is rendered with built-in Swift String Interpolation.
    /// Custom formatting can be explicitly required with NumberFormatter, as in
    /// `{{format(a)}}` (see `Formatter`).
    /// 
    /// - `{{#float}}...{{/float}}` renders if and only if `float` is not 0 (zero).
    /// 
    /// - `{{^float}}...{{/float}}` renders if and only if `float` is 0 (zero).
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: (self != 0.0),
            render: { (info: RenderingInfo) in
                switch info.tag.type {
                case .variable:
                    // {{ float }}
                    return Rendering("\(self)")
                case .section:
                    if info.enumerationItem {
                        // {{# floats }}...{{/ floats }}
                        return try info.tag.render(info.context.extendedContext(Box(self)))
                    } else {
                        // {{# float }}...{{/ float }}
                        //
                        // Floats do not enter the context stack when used in a
                        // boolean section.
                        //
                        // This behavior must not change:
                        // https://github.com/groue/GRMustache/issues/83
                        return try info.tag.render(info.context)
                    }
                }
        })
    }
}


/// GRMustache provides built-in support for rendering `String`.
extension String : MustacheBoxable {
    
    /// `String` adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{string}}` renders the string, HTML-escaped.
    /// 
    /// - `{{{string}}}` renders the string, *not* HTML-escaped.
    /// 
    /// - `{{#string}}...{{/string}}` renders if and only if `string` is not empty.
    /// 
    /// - `{{^string}}...{{/string}}` renders if and only if `string` is empty.
    /// 
    /// HTML-escaping of `{{string}}` tags is disabled for Text templates: see
    /// `Configuration.contentType` for a full discussion of the content type of
    /// templates.
    /// 
    /// 
    /// ### Keys exposed to templates
    /// 
    /// A string can be queried for the following keys:
    /// 
    /// - `length`: the number of characters in the string.
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: (self.count > 0),
            keyedSubscript: { (key: String) in
                switch key {
                case "length":
                    return self.count
                default:
                    return nil
                }
        })
    }
}


/// GRMustache provides built-in support for rendering `Bool`.
extension Bool : MustacheBoxable {
    
    /// `Bool` adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{bool}}` renders as `0` or `1`.
    /// 
    /// - `{{#bool}}...{{/bool}}` renders if and only if `bool` is true.
    /// 
    /// - `{{^bool}}...{{/bool}}` renders if and only if `bool` is false.
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: self,
            render: { (info: RenderingInfo) in
                switch info.tag.type {
                case .variable:
                    // {{ bool }}
                    return Rendering("\(self ? 1 : 0)") // Behave like [NSNumber numberWithBool:]
                case .section:
                    if info.enumerationItem {
                        // {{# bools }}...{{/ bools }}
                        return try info.tag.render(info.context.extendedContext(Box(self)))
                    } else {
                        // {{# bool }}...{{/ bool }}
                        //
                        // Bools do not enter the context stack when used in a
                        // boolean section.
                        //
                        // This behavior must not change:
                        // https://github.com/groue/GRMustache/issues/83
                        return try info.tag.render(info.context)
                    }
                }
        })
    }
}


/// GRMustache provides built-in support for rendering `Int64`.
extension Int64 : MustacheBoxable {
    
    /// `Int64` adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{int}}` is rendered with built-in Swift String Interpolation.
    ///   Custom formatting can be explicitly required with NumberFormatter,
    ///   as in `{{format(a)}}` (see `Formatter`).
    /// 
    /// - `{{#int}}...{{/int}}` renders if and only if `int` is not 0 (zero).
    /// 
    /// - `{{^int}}...{{/int}}` renders if and only if `int` is 0 (zero).
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: (self != 0),
            render: { (info: RenderingInfo) in
                switch info.tag.type {
                case .variable:
                    // {{ int }}
                    return Rendering("\(self)")
                case .section:
                    if info.enumerationItem {
                        // {{# ints }}...{{/ ints }}
                        return try info.tag.render(info.context.extendedContext(Box(self)))
                    } else {
                        // {{# int }}...{{/ int }}
                        //
                        // Ints do not enter the context stack when used in a
                        // boolean section.
                        //
                        // This behavior must not change:
                        // https://github.com/groue/GRMustache/issues/83
                        return try info.tag.render(info.context)
                    }
                }
        })
    }
}


/// GRMustache provides built-in support for rendering `Int`.
extension Int : MustacheBoxable {
    
    /// `Int` adopts the `MustacheBoxable` protocol so that it can feed Mustache
    /// templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{int}}` is rendered with built-in Swift String Interpolation.
    ///   Custom formatting can be explicitly required with NumberFormatter, as
    ///   in `{{format(a)}}` (see `Formatter`).
    /// 
    /// - `{{#int}}...{{/int}}` renders if and only if `int` is not 0 (zero).
    /// 
    /// - `{{^int}}...{{/int}}` renders if and only if `int` is 0 (zero).
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: (self != 0),
            render: { (info: RenderingInfo) in
                switch info.tag.type {
                case .variable:
                    // {{ int }}
                    return Rendering("\(self)")
                case .section:
                    if info.enumerationItem {
                        // {{# ints }}...{{/ ints }}
                        return try info.tag.render(info.context.extendedContext(Box(self)))
                    } else {
                        // {{# int }}...{{/ int }}
                        //
                        // Ints do not enter the context stack when used in a
                        // boolean section.
                        //
                        // This behavior must not change:
                        // https://github.com/groue/GRMustache/issues/83
                        return try info.tag.render(info.context)
                    }
                }
        })
    }
}


/// GRMustache provides built-in support for rendering `UInt64`.
extension UInt64 : MustacheBoxable {
    
    /// `UInt64` adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{uint}}` is rendered with built-in Swift String Interpolation.
    ///   Custom formatting can be explicitly required with NumberFormatter, as
    ///   in `{{format(a)}}` (see `Formatter`).
    /// 
    /// - `{{#uint}}...{{/uint}}` renders if and only if `uint` is not 0 (zero).
    /// 
    /// - `{{^uint}}...{{/uint}}` renders if and only if `uint` is 0 (zero).
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: (self != 0),
            render: { (info: RenderingInfo) in
                switch info.tag.type {
                case .variable:
                    // {{ uint }}
                    return Rendering("\(self)")
                case .section:
                    if info.enumerationItem {
                        // {{# uints }}...{{/ uints }}
                        return try info.tag.render(info.context.extendedContext(Box(self)))
                    } else {
                        // {{# uint }}...{{/ uint }}
                        //
                        // Uints do not enter the context stack when used in a
                        // boolean section.
                        //
                        // This behavior must not change:
                        // https://github.com/groue/GRMustache/issues/83
                        return try info.tag.render(info.context)
                    }
                }
        })
    }
}


/// GRMustache provides built-in support for rendering `UInt`.
extension UInt : MustacheBoxable {
    
    /// `UInt` adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    /// 
    /// 
    /// ### Rendering
    /// 
    /// - `{{uint}}` is rendered with built-in Swift String Interpolation.
    ///   Custom formatting can be explicitly required with NumberFormatter, as
    ///   in `{{format(a)}}` (see `Formatter`).
    /// 
    /// - `{{#uint}}...{{/uint}}` renders if and only if `uint` is not 0 (zero).
    /// 
    /// - `{{^uint}}...{{/uint}}` renders if and only if `uint` is 0 (zero).
    public var mustacheBox: MustacheBox {
        return MustacheBox(
            value: self,
            boolValue: (self != 0),
            render: { (info: RenderingInfo) in
                switch info.tag.type {
                case .variable:
                    // {{ uint }}
                    return Rendering("\(self)")
                case .section:
                    if info.enumerationItem {
                        // {{# uints }}...{{/ uints }}
                        return try info.tag.render(info.context.extendedContext(Box(self)))
                    } else {
                        // {{# uint }}...{{/ uint }}
                        //
                        // Uints do not enter the context stack when used in a
                        // boolean section.
                        //
                        // This behavior must not change:
                        // https://github.com/groue/GRMustache/issues/83
                        return try info.tag.render(info.context)
                    }
                }
        })
    }
}
