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


/// Configuration exposes properties that affect both the parsing and the
/// rendering of Mustache templates.
/// 
/// 
/// ### What can be configured
/// 
/// Configuration covers:
/// 
/// - **Content type**: HTML templates escape rendered strings, while Text
///   templates do not. Text templates are HTML-escaped as a whole when included
///   in HTML templates.
/// 
/// - **Context stack**: values stored in a Configuration's context are readily
///   available to templates.
/// 
/// - **Tag delimiters**: default Mustache delimiters are `{{` and `}}`. These
///   are configurable.
/// 
/// 
/// ### Usage
/// 
/// You setup a configuration *before* loading templates:
/// 
///     // Template loaded later will not HTML-escape the rendered strings:
///     Mustache.DefaultConfiguration.contentType = .text
///     
///     // A text template
///     let template = try! Template(string: "...")
/// 
/// 
/// ### Configuration levels
/// 
/// There are three levels of configuration:
/// 
/// `Mustache.DefaultConfiguration` is a global variable that applies
/// by default:
/// 
///     Mustache.DefaultConfiguration.contentType = .text
/// 
///     // A text template
///     let template = try! Template(named: "Document")
/// 
/// `TemplateRepository.configuration` only applies to templates loaded from the
/// template repository:
/// 
///     let repository = TemplateRepository(directoryPath: "/path/to/templates")
///     repository.configuration.contentType = .text
/// 
///     // A text template
///     let template = try! repository.template(named: "Document")
/// 
/// Templates can also be configured individually. See the documentation of each
/// Configuration method for more details.
public struct Configuration {
    
    // =========================================================================
    // MARK: - Factory Configuration
    
    /// Creates a factory configuration.
    /// 
    /// Its contentType is HTML, baseContext empty, tag delimiters `{{` and `}}`.
    /// 
    /// For example:
    /// 
    ///     // Make sure the template repository uses factory configuration,
    ///     // regardless of changes made to `Mustache.DefaultConfiguration`:
    ///     let repository = TemplateRepository(directoryPath: "/path/to/templates")
    ///     repository.configuration = Configuration()
    public init() {
        contentType = .html
        baseContext = Context()
        tagDelimiterPair = ("{{", "}}")
    }
    
    
    // =========================================================================
    // MARK: - Content Type
    
    /// The content type of strings rendered by templates built with this
    /// configuration.
    /// 
    /// It affects the HTML-escaping of your data:
    /// 
    /// - The `.html` content type has templates render HTML. This is the
    ///   default behavior. HTML template escape the input of variable tags such
    ///   as `{{name}}`. Use triple mustache tags `{{{content}}}` in order to
    ///   avoid HTML-escaping.
    /// 
    /// - The `.text` content type has templates render text. They do not
    ///   HTML-escape their input: `{{name}}` and `{{{name}}}` have identical,
    ///   non-escaped, renderings.
    /// 
    /// GRMustache safely keeps track of the content type of templates: should a
    /// HTML template embed a text template, the content of the text template
    /// would be HTML-escaped, as a whole.
    /// 
    /// Setting the contentType of a configuration affects the contentType of
    /// all templates loaded afterwards:
    /// 
    ///     // Globally, with Mustache.DefaultConfiguration:
    /// 
    ///     Mustache.DefaultConfiguration.contentType = .text
    ///     let textTemplate = try! Template(named: "Script")
    /// 
    ///     // Locally, using a TemplateRepository:
    /// 
    ///     let repository = TemplateRepository(bundle: Bundle.main)
    ///     repository.configuration.contentType = .html
    ///     let HTMLTemplate = try! repository.template(named: "HTMLDocument")
    /// 
    /// In order to set the content type of an individual templates, use pragma tags
    /// right in the content of your templates:
    /// 
    /// - `{{% CONTENT_TYPE:TEXT }}` turns a template into a text template.
    /// - `{{% CONTENT_TYPE:HTML }}` turns a template into a HTML template.
    /// 
    /// For example:
    /// 
    ///     {{! This template renders a bash script. }}
    ///     {{% CONTENT_TYPE:TEXT }}
    ///     export LANG={{ENV.LANG}}
    ///     ...
    /// 
    /// These pragmas must be found early in the template (before any value
    /// tag). Should several pragmas be found in a template content, the last
    /// one wins.
    public var contentType: ContentType
    
    
    // =========================================================================
    // MARK: - Context Stack
    
    /// The base context for templates rendering. All templates built with this
    /// configuration can access values stored in the base context.
    /// 
    /// The default base context is empty.
    /// 
    /// You can set it to some custom context, or extend it with the
    /// `extendBaseContext(_)` and `register(_:forKey:)` methods.
    /// 
    ///     // Globally, with Mustache.DefaultConfiguration:
    /// 
    ///     Mustache.DefaultConfiguration.baseContext = Context(["foo": "bar"])
    /// 
    ///     // "bar"
    ///     let template1 = try! Template(string: "{{foo}}")
    ///     try! template1.render()
    /// 
    ///     // Locally, using a TemplateRepository:
    ///     
    ///     let repository = TemplateRepository(bundle: Bundle.main)
    ///     repository.configuration.baseContext = Context(["foo": "bar"])
    ///     
    ///     // "bar"
    ///     let template2 = try! repository.template(string: "{{foo}}")
    ///     try! template2.render()
    /// 
    /// The base context can also be set for individual templates:
    /// 
    ///     let template3 = try! Template(string: "{{foo}}")
    ///     template3.baseContext = Context(["foo": "bar"])
    ///     
    ///     // "bar"
    ///     try! template3.render()
    /// 
    /// - seealso: extendBaseContext(_)
    /// - seealso: register(_:forKey:)
    public var baseContext: Context
    
    /// Extends the base context with the provided value. All templates built
    /// with this configuration can access the value.
    /// 
    ///     // Globally, with Mustache.DefaultConfiguration:
    /// 
    ///     Mustache.DefaultConfiguration.extendBaseContext(["foo": "bar"])
    /// 
    ///     // "bar"
    ///     let template1 = try! Template(string: "{{foo}}")
    ///     try! template1.render()
    /// 
    ///     // Locally, using a TemplateRepository:
    ///     
    ///     let repository = TemplateRepository(bundle: Bundle.main)
    ///     repository.configuration.extendBaseContext(["foo": "bar"])
    ///     
    ///     // "bar"
    ///     let template2 = try! repository.template(string: "{{foo}}")
    ///     try! template2.render()
    /// 
    /// The base context can also be extended for individual templates:
    /// 
    ///     let template3 = try! Template(string: "{{foo}}")
    ///     template3.extendBaseContext(["foo": "bar"])
    ///     
    ///     // "bar"
    ///     try! template3.render()
    /// 
    /// - parameter value: The value pushed on the top of the context stack.
    /// 
    /// - seealso: baseContext
    /// - seealso: register(_:forKey:)
    public mutating func extendBaseContext(_ value: Any?) {
        baseContext = baseContext.extendedContext(value)
    }
    
    /// Registers a key/value pair in the base context. All renderings will be
    /// able to access the provided value through this key.
    /// 
    /// Registered keys are looked up first when evaluating Mustache tags.
    /// 
    ///     // Globally, with Mustache.DefaultConfiguration:
    /// 
    ///     Mustache.DefaultConfiguration.register("bar", forKey: "foo")
    /// 
    ///     // Renders "bar"
    ///     let template1 = try! Template(string: "{{foo}}")
    ///     try! template1.render()
    /// 
    ///     // Renders "bar" again, because the registered value "bar" has priority.
    ///     try! template1.render(["foo": "qux"])
    /// 
    ///     // Locally, using a TemplateRepository:
    ///     
    ///     let repository = TemplateRepository(bundle: Bundle.main)
    ///     repository.configuration.register("bar", forKey: "foo")
    ///     
    ///     // "bar"
    ///     let template2 = try! repository.template(string: "{{foo}}")
    ///     try! template2.render()
    /// 
    /// Keys can also be registered in the base context of individual templates:
    /// 
    ///     let template3 = try! Template(string: "{{foo}}")
    ///     template3.register("bar", forKey: "foo")
    ///     
    ///     // "bar"
    ///     try! template3.render()
    /// 
    /// 
    /// - parameter key: An identifier.
    /// - parameter value: The value registered for *key*.
    /// 
    /// - seealso: baseContext
    /// - seealso: extendBaseContext(_)
    public mutating func register(_ value: Any?, forKey key: String) {
        baseContext = baseContext.extendedContext(withRegisteredValue: value, forKey: key)
    }
    
    
    // =========================================================================
    // MARK: - Tag delimiters
    
    /// The delimiters for Mustache tags. All templates built with this
    /// configuration are parsed using those delimiters.
    /// 
    /// The default value is `("{{", "}}")`.
    /// 
    /// Setting the tagDelimiterPair of a configuration affects all templates
    /// loaded afterwards:
    /// 
    ///     // Globally, with Mustache.DefaultConfiguration:
    /// 
    ///     Mustache.DefaultConfiguration.tagDelimiterPair = ("<%", "%>")
    ///     let template = try! Template(string: "<% name %>)
    /// 
    ///     // Locally, using a TemplateRepository:
    /// 
    ///     let repository = TemplateRepository()
    ///     repository.configuration.tagDelimiterPair = ("[[", "]]")
    ///     let template = try! repository.template(string: "[[ name ]]")
    /// 
    /// You can also change the delimiters right in your templates using a "Set
    /// Delimiter tag": `{{=[[ ]]=}}` changes delimiters to `[[` and `]]`.
    public var tagDelimiterPair: TagDelimiterPair
}


// =============================================================================
// MARK: - Default Configuration

/// The default configuration that is used unless specified otherwise by a
/// TemplateRepository.
public var DefaultConfiguration = Configuration()
