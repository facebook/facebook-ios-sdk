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

// =============================================================================
// MARK: - TagType

/// The type of a tag, variable or section. See the documentation of `Tag` for
/// more information.
public enum TagType {
    
    /// The type of tags such as `{{name}}` and `{{{body}}}`.
    case variable
    
    /// The type of section tags such as `{{#user}}...{{/user}}`.
    case section
}


// =============================================================================
// MARK: - Tag

/// Tag instances represent Mustache tags that render values:
///
/// - variable tags: `{{name}}` and `{{{body}}}`
/// - section tags: `{{#user}}...{{/user}}`
///
/// You may meet the Tag class when you implement your own `RenderFunction`,
/// `WillRenderFunction` or `DidRenderFunction`, or filters that perform custom
/// rendering (see `FilterFunction`).
///
/// - seealso: RenderFunction
/// - seealso: WillRenderFunction
/// - seealso: DidRenderFunction
public protocol Tag: AnyObject, CustomStringConvertible {
    
    // IMPLEMENTATION NOTE
    //
    // Tag is a class-only protocol so that the Swift compiler does not crash
    // when compiling the `tag` property of RenderingInfo.
    
    /// The type of the tag: variable or section:
    ///
    ///     let render: RenderFunction = { (info: RenderingInfo) in
    ///         switch info.tag.type {
    ///         case .variable:
    ///             return Rendering("variable")
    ///         case .section:
    ///             return Rendering("section")
    ///         }
    ///     }
    ///
    ///     let template = try! Template(string: "{{object}}, {{#object}}...{{/object}}")
    ///
    ///     // Renders "variable, section"
    ///     try! template.render(["object": Box(render)])
    var type: TagType { get }
    
    
    /// The literal and unprocessed inner content of the tag.
    ///
    /// A section tag such as `{{# person }}Hello {{ name }}!{{/ person }}`
    /// returns "Hello {{ name }}!".
    ///
    /// Variable tags such as `{{ name }}` have no inner content: their inner
    /// template string is the empty string.
    ///
    ///     // {{# pluralize(count) }}...{{/ }} renders the plural form of the section
    ///     // content if the `count` argument is greater than 1.
    ///     let pluralize = Filter { (count: Int?, info: RenderingInfo) in
    ///
    ///         // Pluralize the inner content of the section tag:
    ///         var string = info.tag.innerTemplateString
    ///         if let count = count, count > 1 {
    ///             string += "s"  // naive
    ///         }
    ///
    ///         return Rendering(string)
    ///     }
    ///
    ///     let template = try! Template(string: "I have {{ cats.count }} {{# pluralize(cats.count) }}cat{{/ }}.")
    ///     template.register(pluralize, forKey: "pluralize")
    ///
    ///     // Renders "I have 3 cats."
    ///     let data = ["cats": ["Kitty", "Pussy", "Melba"]]
    ///     try! template.render(data)
    var innerTemplateString: String { get }
    
    /// The delimiters of the tag.
    var tagDelimiterPair: TagDelimiterPair { get }
    
    /// Returns the rendering of the tag's inner content. All inner tags are
    /// evaluated with the provided context.
    ///
    /// This method does not return a String, but a Rendering value that wraps
    /// both the rendered string and its content type (HTML or Text).
    ///
    /// The contentType is HTML, unless specified otherwise by `Configuration`,
    /// or a `{{% CONTENT_TYPE:TEXT }}` pragma tag.
    ///
    ///     // The strong RenderFunction below wraps a section in a <strong> HTML tag.
    ///     let strong: RenderFunction = { (info: RenderingInfo) -> Rendering in
    ///         let rendering = try info.tag.render(info.context)
    ///         return Rendering("<strong>\(rendering.string)</strong>", .html)
    ///     }
    ///
    ///     let template = try! Template(string: "{{#strong}}Hello {{name}}{{/strong}}")
    ///     template.register(strong, forKey: "strong")
    ///
    ///     // Renders "<strong>Hello Arthur</strong>"
    ///     try! template.render(["name": Box("Arthur")])
    ///
    /// - parameter context: The context stack for evaluating mustache tags.
    /// - throws: An eventual rendering error.
    /// - returns: The rendering of the tag.
    func render(_ context: Context) throws -> Rendering
}
