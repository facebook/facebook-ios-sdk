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


/// Formatter can format template values.
@objc extension Formatter {
    
    /// Formatter adopts the `MustacheBoxable` protocol so that it can feed
    /// Mustache templates.
    /// 
    /// You should not directly call the `mustacheBox` property.
    ///
    /// Formatter can be used as a filter:
    /// 
    ///     let percentFormatter = NumberFormatter()
    ///     percentFormatter.numberStyle = .percent
    /// 
    ///     var template = try! Template(string: "{{ percent(x) }}")
    ///     template.register(percentFormatter, forKey: "percent")
    /// 
    ///     // Renders "50%"
    ///     try! template.render(["x": 0.5])
    /// 
    /// 
    /// Formatter can also format all variable tags in a Mustache section:
    /// 
    ///     template = try! Template(string:
    ///         "{{# percent }}" +
    ///           "{{#ingredients}}" +
    ///             "- {{name}} ({{proportion}})\n" +
    ///           "{{/ingredients}}" +
    ///         "{{/percent}}")
    ///     template.register(percentFormatter, forKey: "percent")
    /// 
    ///     // - bread (50%)
    ///     // - ham (35%)
    ///     // - butter (15%)
    ///     var data = [
    ///         "ingredients":[
    ///             ["name": "bread", "proportion": 0.5],
    ///             ["name": "ham", "proportion": 0.35],
    ///             ["name": "butter", "proportion": 0.15]]]
    ///     try! template.render(data)
    /// 
    /// As seen in the example above, variable tags buried inside inner sections
    /// are escaped as well, so that you can render loop and conditional
    /// sections. However, values that can't be formatted are left untouched.
    /// 
    /// Precisely speaking, "values that can't be formatted" are the ones that
    /// have the `string(for:)` method return nil, as stated by
    /// [NSFormatter documentation](https://developer.apple.com/reference/foundation/formatter/1415993-string).
    /// 
    /// Typically, `NumberFormatter` only formats numbers, and `DateFormatter`,
    /// dates: you can safely mix various data types in a section controlled by
    /// those well-behaved formatters.
    @objc open override var mustacheBox: MustacheBox {
        // Return a multi-facetted box, because NSFormatter interacts in
        // various ways with Mustache rendering.
        
        return MustacheBox(
            // Let user extract the formatter out of the box:
            value: self,
            
            // This function is used for evaluating `formatter(x)` expressions.
            filter: Filter { (box: MustacheBox) in
                // NSFormatter documentation for stringForObjectValue: states:
                //
                // > First test the passed-in object to see if it’s of the
                // > correct class. If it isn’t, return nil; but if it is of the
                // > right class, return a properly formatted and, if necessary,
                // > localized string.
                if let object = box.value as? NSObject {
                    return self.string(for: object)
                } else {
                    // Not the correct class: return nil, i.e. empty Box.
                    return nil
                }
            },
            
            // This function lets formatter change values that are about to be
            // rendered to their formatted counterpart.
            //
            // It is activated as soon as the formatter enters the context
            // stack, when used in a section `{{# formatter }}...{{/ formatter }}`.
            willRender: { (tag: Tag, box: MustacheBox) in
                switch tag.type {
                case .variable:
                    // {{ value }}
                    // Format the value if we can.
                    //
                    // NSFormatter documentation for stringForObjectValue: states:
                    //
                    // > First test the passed-in object to see if it’s of the correct
                    // > class. If it isn’t, return nil; but if it is of the right class,
                    // > return a properly formatted and, if necessary, localized string.
                    //
                    // So nil result means that object is not of the correct class. Leave
                    // it untouched.
                    
                    if let formatted = self.string(for: box.value) {
                        return formatted
                    } else {
                        return box
                    }
                    
                case .section:
                    // {{# value }}...{{/ value }}
                    // {{^ value }}...{{/ value }}
                    // Leave sections untouched, so that loops and conditions are not
                    // affected by the formatter.
                    
                    return box
                }
        })
    }
}
