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

extension StandardLibrary {
    
    /// StandardLibrary.Logger is a tool intended for debugging templates.
    /// 
    /// It logs the rendering of variable and section tags such as `{{name}}`
    /// and `{{#name}}...{{/name}}`.
    /// 
    /// To activate logging, add a Logger to the base context of a template:
    /// 
    ///     let template = try! Template(string: "{{name}} died at {{age}}.")
    /// 
    ///     // Logs all tag renderings with print:
    ///     let logger = StandardLibrary.Logger() { print($0) }
    ///     template.extendBaseContext(logger)
    ///     
    ///     // Render
    ///     let data = ["name": "Freddy Mercury", "age": 45]
    ///     let rendering = try! template.render(data)
    /// 
    ///     // Prints:
    ///     // {{name}} at line 1 did render "Freddy Mercury" as "Freddy Mercury"
    ///     // {{age}} at line 1 did render 45 as "45"
    public final class Logger : MustacheBoxable {
        
        /// Creates a Logger.
        /// 
        /// - parameter log: A closure that takes a String. Default one logs that
        ///   string with NSLog().
        public init(_ log: ((String) -> Void)? = nil) {
            if let log = log {
                self.log = log
            } else {
                self.log = { NSLog($0) }
            }
        }
        
        /// Logger adopts the `MustacheBoxable` protocol so that it can feed
        /// Mustache templates.
        /// 
        /// You should not directly call the `mustacheBox` property.
        public var mustacheBox: MustacheBox {
            return MustacheBox(
                willRender: { (tag, box) in
                    if tag.type == .section {
                        self.log("\(self.indentationPrefix)\(tag) will render \(box.valueDescription)")
                        self.indentationLevel += 1
                    }
                    return box
                },
                didRender: { (tag, box, string) in
                    if tag.type == .section {
                        self.indentationLevel -= 1
                    }
                    if let string = string {
                        self.log("\(self.indentationPrefix)\(tag) did render \(box.valueDescription) as \(string.debugDescription)")
                    }
                }
            )
        }
        
        var indentationPrefix: String {
            return String(repeating: " ", count: indentationLevel * 2)
        }
        
        fileprivate let log: (String) -> Void
        fileprivate var indentationLevel: Int = 0
    }
}
