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

/// See the documentation of the `TemplateRepositoryDataSource` protocol.
public typealias TemplateID = String

/// The protocol for a TemplateRepository's dataSource.
/// 
/// The dataSource's responsability is to provide Mustache template strings for
/// template and partial names.
public protocol TemplateRepositoryDataSource {
    
    /// Returns a template ID, that is to say a string that uniquely identifies
    /// a template or a template partial.
    /// 
    /// The meaning of this String is opaque: your implementation of a
    /// `TemplateRepositoryDataSource` would define, for itself, how strings
    /// would identity a template or a partial. For example, a file-based data
    /// source may use paths to the templates.
    /// 
    /// The return value of this method can be nil: the library user will then
    /// eventually catch a missing template error.
    /// 
    /// ### Template hierarchies
    /// 
    /// Whenever relevant, template and partial hierarchies are supported via
    /// the baseTemplateID parameter: it contains the template ID of the
    /// enclosing template, or nil when the data source is asked for a
    /// template ID from a raw template string (see
    /// TemplateRepository.template(string:error:)).
    /// 
    /// Not all data sources have to implement hierarchies: they can simply
    /// ignore this parameter.
    /// 
    /// *Well-behaved* data sources that support hierarchies should support
    /// "absolute paths to partials". For example, the built-in directory-based
    /// data source lets users write both `{{> relative/path/to/partial}}` and
    /// `{{> /absolute/path/tp/partial}}`tags.
    /// 
    /// ### Unique IDs
    /// 
    /// Each template must be identified by a single template ID. For example, a
    /// file-based data source which uses path IDs must normalize paths. Not
    /// following this rule yields undefined behavior.
    /// 
    /// - parameter name: The name of the template or template partial.
    /// - parameter baseTemplateID: The template ID of the enclosing template.
    /// - returns: A template ID.
    func templateIDForName(_ name: String, relativeToTemplateID baseTemplateID: TemplateID?) -> TemplateID?
    
    /// Returns the Mustache template string that matches the template ID.
    /// 
    /// - parameter templateID: The template ID of the template.
    /// - throws: MustacheError
    /// - returns: A Mustache template string.
    func templateStringForTemplateID(_ templateID: TemplateID) throws -> String
}

/// A template repository represents a set of sibling templates and partials.
/// 
/// You don't have to instanciate template repositories, because GRMustache
/// provides implicit ones whenever you load templates with methods like
/// `Template(named:error:)`, for example.
/// 
/// However, you may like to use one for your profit. Template repositories
/// provide:
/// 
/// - custom template data source
/// - custom `Configuration`
/// - a cache of template parsings
/// - absolute paths to ease loading of partial templates in a hierarchy of
///   directories and template files
final public class TemplateRepository {
    
    // =========================================================================
    // MARK: - Creating Template Repositories
    
    /// Creates a TemplateRepository which loads template through the provided
    /// dataSource.
    /// 
    /// The dataSource is optional, but repositories without dataSource can not
    /// load templates by name, and can only parse template strings that do not
    /// contain any `{{> partial }}` tag.
    /// 
    ///     let repository = TemplateRepository()
    ///     let template = try! repository.template(string: "Hello {{name}}")
    public init(dataSource: TemplateRepositoryDataSource? = nil) {
        configuration = DefaultConfiguration
        templateASTCache = [:]
        self.dataSource = dataSource
    }
    
    /// Creates a TemplateRepository that loads templates from a dictionary.
    /// 
    ///     let templates = ["template": "Hulk Hogan has a Mustache."]
    ///     let repository = TemplateRepository(templates: templates)
    /// 
    ///     // Renders "Hulk Hogan has a Mustache." twice
    ///     try! repository.template(named: "template").render()
    ///     try! repository.template(string: "{{>template}}").render()
    /// 
    /// - parameter templates: A dictionary whose keys are template names and
    ///   values template strings.
    convenience public init(templates: [String: String]) {
        self.init(dataSource: DictionaryDataSource(templates: templates))
    }
    
    /// Creates a TemplateRepository that loads templates from a directory.
    /// 
    ///     let repository = TemplateRepository(directoryPath: "/path/to/templates")
    /// 
    ///     // Loads /path/to/templates/template.mustache
    ///     let template = try! repository.template(named: "template")
    /// 
    /// 
    /// Eventual partial tags in template files refer to sibling template files.
    /// 
    /// If the target directory contains a hierarchy of template files and
    /// sub-directories, you can navigate through this hierarchy with both
    /// relative and absolute paths to partials. For example, given the
    /// following hierarchy:
    /// 
    /// - /path/to/templates
    ///     - a.mustache
    ///     - partials
    ///         - b.mustache
    /// 
    /// The a.mustache template can embed b.mustache with both
    /// `{{> partials/b }}` and `{{> /partials/b }}` partial tags.
    /// 
    /// The b.mustache template can embed a.mustache with both `{{> ../a }}` and
    /// `{{> /a }}` partial tags.
    /// 
    /// 
    /// - parameter directoryPath: The path to the directory containing
    ///   template files.
    /// - parameter templateExtension: The extension of template files. Default
    ///   extension is "mustache".
    /// - parameter encoding: The encoding of template files. Default encoding
    ///   is UTF-8.
    convenience public init(directoryPath: String, templateExtension: String? = "mustache", encoding: String.Encoding = String.Encoding.utf8) {
        self.init(dataSource: URLDataSource(baseURL: URL(fileURLWithPath: directoryPath, isDirectory: true), templateExtension: templateExtension, encoding: encoding))
    }
    
    /// Creates a TemplateRepository that loads templates from a URL.
    /// 
    ///     let templatesURL = NSURL.fileURLWithPath("/path/to/templates")!
    ///     let repository = TemplateRepository(baseURL: templatesURL)
    /// 
    ///     // Loads /path/to/templates/template.mustache
    ///     let template = try! repository.template(named: "template")
    /// 
    /// 
    /// Eventual partial tags in template files refer to sibling template files.
    /// 
    /// If the target directory contains a hierarchy of template files and
    /// sub-directories, you can navigate through this hierarchy with both
    /// relative and absolute paths to partials. For example, given the
    /// following hierarchy:
    /// 
    /// - /path/to/templates
    ///     - a.mustache
    ///     - partials
    ///         - b.mustache
    /// 
    /// The a.mustache template can embed b.mustache with both `{{> partials/b }}`
    /// and `{{> /partials/b }}` partial tags.
    /// 
    /// The b.mustache template can embed a.mustache with both `{{> ../a }}` and
    /// `{{> /a }}` partial tags.
    /// 
    /// 
    /// - parameter baseURL: The base URL where to look for templates.
    /// - parameter templateExtension: The extension of template resources.
    ///   Default extension is "mustache".
    /// - parameter encoding: The encoding of template resources. Default
    ///   encoding is UTF-8.
    convenience public init(baseURL: URL, templateExtension: String? = "mustache", encoding: String.Encoding = String.Encoding.utf8) {
        self.init(dataSource: URLDataSource(baseURL: baseURL, templateExtension: templateExtension, encoding: encoding))
    }
    
    /// Creates a TemplateRepository that loads templates stored as resources in
    /// a bundle.
    /// 
    ///     let repository = TemplateRepository(bundle: nil)
    /// 
    ///     // Loads the template.mustache resource of the main bundle:
    ///     let template = try! repository.template(named: "template")
    /// 
    /// - parameter bundle: The bundle that stores templates resources. Nil
    ///   stands for the main bundle.
    /// - parameter templateExtension: The extension of template resources.
    ///   Default extension is "mustache".
    /// - parameter encoding: The encoding of template resources. Default
    ///   encoding is UTF-8.
    convenience public init(bundle: Bundle?, templateExtension: String? = "mustache", encoding: String.Encoding = String.Encoding.utf8) {
        self.init(dataSource: BundleDataSource(bundle: bundle ?? Bundle.main, templateExtension: templateExtension, encoding: encoding))
    }
    
    
    // =========================================================================
    // MARK: - Configuring Template Repositories
    
    /// The configuration for all templates and partials built by
    /// the repository.
    /// 
    /// It is initialized with `Mustache.DefaultConfiguration`.
    /// 
    /// You can alter the repository's configuration, or set it to another
    /// value, before you load templates:
    /// 
    ///     // Reset the configuration to a factory configuration and change tag delimiters:
    ///     let repository = TemplateRepository()
    ///     repository.configuration = Configuration()
    ///     repository.configuration.tagDelimiterPair = ("<%", "%>")
    /// 
    ///     // Renders "Hello Luigi"
    ///     let template = try! repository.template(string: "Hello <%name%>")
    ///     try! template.render(["name": "Luigi"])
    /// 
    /// Changing the configuration has no effect after the repository has loaded
    /// one template.
    public var configuration: Configuration
    
    
    // =========================================================================
    // MARK: - Loading Templates from a Repository
    
    
    /// The template repository data source, responsible for loading template
    /// strings.
    public let dataSource: TemplateRepositoryDataSource?
    
    /// Creates a template from a template string.
    /// 
    /// Depending on the way the repository has been created, partial tags such
    /// as `{{>partial}}` load partial templates from URLs, file paths, keys in
    /// a dictionary, or whatever is relevant to the repository's data source.
    /// 
    /// - parameter templateString: A Mustache template string.
    /// - throws: MustacheError
    /// - returns: A Mustache Template.
    public func template(string: String) throws -> Template {
        let templateAST = try self.templateAST(string: string)
        return Template(repository: self, templateAST: templateAST, baseContext: lockedConfiguration.baseContext)
    }
    
    /// Creates a template, identified by its name.
    /// 
    /// Depending on the repository's data source, the name identifies a bundle
    /// resource, a URL, a file path, a key in a dictionary, etc.
    /// 
    /// Template repositories cache the parsing of their templates. However this
    /// method always return new Template instances, which you can further
    /// configure independently.
    /// 
    /// - parameter name: The template name.
    /// - throws: MustacheError
    /// - returns: A Mustache Template.
    /// 
    /// - seealso: reloadTemplates()
    public func template(named name: String) throws -> Template {
        let templateAST = try self.templateAST(named: name, relativeToTemplateID: nil)
        return Template(repository: self, templateAST: templateAST, baseContext: lockedConfiguration.baseContext)
    }
    
    /// Clears the cache of parsed template strings.
    /// 
    ///     // May reuse a cached parsing:
    ///     let template = try! repository.template(named:"profile")
    /// 
    ///     // Forces the reloading of the template:
    ///     repository.reloadTemplates();
    ///     let template = try! repository.template(named:"profile")
    /// 
    /// Note that previously created Template instances are not reloaded.
    public func reloadTemplates() {
        templateASTCache.removeAll()
    }
    
    
    // =========================================================================
    // MARK: - Not public
    
    func templateAST(named name: String, relativeToTemplateID baseTemplateID: TemplateID? = nil) throws -> TemplateAST {
        guard let dataSource = self.dataSource else {
            throw MustacheError(kind: .templateNotFound, message: "Missing dataSource", templateID: baseTemplateID)
        }
        
        guard let templateID = dataSource.templateIDForName(name, relativeToTemplateID: baseTemplateID) else {
            if let baseTemplateID = baseTemplateID {
                throw MustacheError(kind: .templateNotFound, message: "Template not found: \"\(name)\" from \(baseTemplateID)", templateID: baseTemplateID)
            } else {
                throw MustacheError(kind: .templateNotFound, message: "Template not found: \"\(name)\"")
            }
        }
        
        if let templateAST = templateASTCache[templateID] {
            // Return cached AST
            return templateAST
        }
        
        let templateString = try dataSource.templateStringForTemplateID(templateID)
        
        // Cache an empty AST for that name so that we support recursive
        // partials.
        let templateAST = TemplateAST()
        templateASTCache[templateID] = templateAST
        
        do {
            let compiledAST = try self.templateAST(string: templateString, templateID: templateID)
            // Success: update the empty AST
            templateAST.updateFromTemplateAST(compiledAST)
            return templateAST
        } catch {
            // Failure: remove the empty AST
            templateASTCache.removeValue(forKey: templateID)
            throw error
        }
    }
    
    func templateAST(string: String, templateID: TemplateID? = nil) throws -> TemplateAST {
        // A Compiler
        let compiler = TemplateCompiler(
            contentType: lockedConfiguration.contentType,
            repository: self,
            templateID: templateID)
        
        // A Parser that feeds the compiler
        let parser = TemplateParser(
            tokenConsumer: compiler,
            tagDelimiterPair: lockedConfiguration.tagDelimiterPair)
        
        // Parse...
        parser.parse(string, templateID: templateID)
        
        // ...and extract the result from the Compiler
        return try compiler.templateAST()
    }
    
    
    fileprivate var _lockedConfiguration: Configuration?
    fileprivate var lockedConfiguration: Configuration {
        // Changing mutable values within the repository's configuration no
        // longer has any effect.
        if _lockedConfiguration == nil {
            _lockedConfiguration = configuration
        }
        return _lockedConfiguration!
    }
    
    fileprivate var templateASTCache: [TemplateID: TemplateAST]
    
    
    // -------------------------------------------------------------------------
    // MARK: DictionaryDataSource
    
    fileprivate class DictionaryDataSource: TemplateRepositoryDataSource {
        let templates: [String: String]
        
        init(templates: [String: String]) {
            self.templates = templates
        }
        
        func templateIDForName(_ name: String, relativeToTemplateID baseTemplateID: TemplateID?) -> TemplateID? {
            return name
        }
        
        func templateStringForTemplateID(_ templateID: TemplateID) throws -> String {
            if let string = templates[templateID] {
                return string
            } else {
                throw MustacheError(kind: .templateNotFound, templateID: templateID)
            }
        }
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: URLDataSource
    
    fileprivate class URLDataSource: TemplateRepositoryDataSource {
        let baseURLAbsoluteString: String
        let baseURL: URL
        let templateExtension: String?
        let encoding: String.Encoding
        
        init(baseURL: URL, templateExtension: String?, encoding: String.Encoding) {
            self.baseURL = baseURL
            self.baseURLAbsoluteString = baseURL.standardizedFileURL.absoluteString
            self.templateExtension = templateExtension
            self.encoding = encoding
        }
        
        func templateIDForName(_ name: String, relativeToTemplateID baseTemplateID: TemplateID?) -> TemplateID? {
            // Rebase template names starting with a /
            let normalizedName: String
            let normalizedBaseTemplateID: TemplateID?
            if !name.isEmpty && name[name.startIndex] == "/" {
                normalizedName = String(name[name.index(after: name.startIndex)...])
                normalizedBaseTemplateID = nil
            } else {
                normalizedName = name
                normalizedBaseTemplateID = baseTemplateID
            }
        
            if normalizedName.isEmpty {
                return normalizedBaseTemplateID
            }
            
            let templateFilename: String
            if let templateExtension = self.templateExtension , !templateExtension.isEmpty {
                templateFilename = (normalizedName as NSString).appendingPathExtension(templateExtension)!
            } else {
                templateFilename = normalizedName
            }
            
            let templateBaseURL: URL
            if let normalizedBaseTemplateID = normalizedBaseTemplateID {
                templateBaseURL = URL(string: normalizedBaseTemplateID)!
            } else {
                templateBaseURL = self.baseURL
            }
            
            let templateURL = URL(string: templateFilename, relativeTo: templateBaseURL)!.standardizedFileURL
            let templateAbsoluteString = templateURL.absoluteString
            
            // Make sure partial relative paths can not escape repository root
            if templateAbsoluteString.range(of: baseURLAbsoluteString)?.lowerBound == templateAbsoluteString.startIndex {
                return templateAbsoluteString
            } else {
                return nil
            }
        }
        
        func templateStringForTemplateID(_ templateID: TemplateID) throws -> String {
            return try NSString(contentsOf: URL(string: templateID)!, encoding: encoding.rawValue) as String
        }
    }
    
    
    // -------------------------------------------------------------------------
    // MARK: BundleDataSource
    
    fileprivate class BundleDataSource: TemplateRepositoryDataSource {
        let bundle: Bundle
        let templateExtension: String?
        let encoding: String.Encoding
        
        init(bundle: Bundle, templateExtension: String?, encoding: String.Encoding) {
            self.bundle = bundle
            self.templateExtension = templateExtension
            self.encoding = encoding
        }
        
        func templateIDForName(_ name: String, relativeToTemplateID baseTemplateID: TemplateID?) -> TemplateID? {
            // Rebase template names starting with a /
            let normalizedName: String
            let normalizedBaseTemplateID: TemplateID?
            if !name.isEmpty && name[name.startIndex] == "/" {
                normalizedName = String(name[name.index(after: name.startIndex)...])
                normalizedBaseTemplateID = nil
            } else {
                normalizedName = name
                normalizedBaseTemplateID = baseTemplateID
            }
            
            if normalizedName.isEmpty {
                return normalizedBaseTemplateID
            }
            
            if let normalizedBaseTemplateID = normalizedBaseTemplateID {
                let relativePath = (normalizedBaseTemplateID as NSString).deletingLastPathComponent.replacingOccurrences(of: bundle.resourcePath!, with:"")
                return bundle.path(forResource: normalizedName, ofType: templateExtension, inDirectory: relativePath)
            } else {
                return bundle.path(forResource: normalizedName, ofType: templateExtension)
            }
        }
        
        func templateStringForTemplateID(_ templateID: TemplateID) throws -> String {
            return try NSString(contentsOfFile: templateID, encoding: encoding.rawValue) as String
        }
    }
}
