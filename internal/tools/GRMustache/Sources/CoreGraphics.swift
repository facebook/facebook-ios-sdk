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

#if os(iOS) || os(macOS) || os(tvOS) || os(watchOS)
    import CoreGraphics
    
    /// GRMustache provides built-in support for rendering `CGFloat`.
    extension CGFloat : MustacheBoxable {
        
        /// CGFloat adopts the MustacheBoxable protocol so that it can feed
        /// Mustache templates.
        ///
        /// You should not directly call the `mustacheBox` property.
        ///
        /// ### Rendering
        ///
        /// - `{{cgfloat}}` is rendered with built-in Swift String
        ///   Interpolation. Custom formatting can be explicitly required with
        ///   NSNumberFormatter, as in `{{format(a)}}` (see `NSFormatter`).
        ///
        /// - `{{#cgfloat}}...{{/cgfloat}}` renders if and only if `cgfloat` is not 0 (zero).
        ///
        /// - `{{^cgfloat}}...{{/cgfloat}}` renders if and only if `double` is 0 (zero).
        public var mustacheBox: MustacheBox {
            return MustacheBox(
                value: self,
                boolValue: (self != 0.0),
                render: { (info: RenderingInfo) in
                    switch info.tag.type {
                    case .variable:
                        // {{ cgfloat }}
                        return Rendering("\(self)")
                    case .section:
                        if info.enumerationItem {
                            // {{# cgfloats }}...{{/ cgfloats }}
                            return try info.tag.render(info.context.extendedContext(Box(self)))
                        } else {
                            // {{# cgfloat }}...{{/ cgfloat }}
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

#endif
