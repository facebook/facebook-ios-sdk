GRMustache.swift [![Swift](https://img.shields.io/badge/swift-5-orange.svg?style=flat)](https://developer.apple.com/swift/) [![Platforms](https://img.shields.io/cocoapods/p/GRMustache.swift.svg)](https://developer.apple.com/swift/) [![License](https://img.shields.io/github/license/groue/GRMustache.swift.svg?maxAge=2592000)](/LICENSE)
================

### Mustache templates for Swift

**Latest release**: October 23, 2016 &bull; version 2.0.0 &bull; [CHANGELOG](CHANGELOG.md)

**Requirements**: iOS 8.0+ / OSX 10.9+ / tvOS 9.0+ &bull; Xcode 8+ &bull; Swift 3

- Swift 2.2: use the [version 1.0.1](https://github.com/groue/GRMustache.swift/tree/1.0.1)
- Swift 2.3: use the [version 1.1.0](https://github.com/groue/GRMustache.swift/tree/1.1.0)
- Swift 4.0: use the [version 3.0.0](https://github.com/fumito-ito/GRMustache.swift/tree/3.0.0)
- Swift 4.2: use the [version 3.1.0](https://github.com/fumito-ito/GRMustache.swift/tree/3.1.0)
- Swift 5.0: use the [version 4.0.0](https://github.com/fumito-ito/GRMustache.swift/tree/4.0.0)

Follow [@groue](http://twitter.com/groue) on Twitter for release announcements and usage tips.

---

<p align="center">
    <a href="#features">Features</a> &bull;
    <a href="#usage">Usage</a> &bull;
    <a href="#installation">Installation</a> &bull;
    <a href="#documentation">Documentation</a>
</p>

---


Features
--------

GRMustache extends the genuine Mustache language with built-in goodies and extensibility hooks that let you avoid the strict minimalism of Mustache when you need it.

- Support for the full [Mustache syntax](http://mustache.github.io/mustache.5.html)
- Filters, as `{{ uppercase(name) }}`
- Template inheritance, as in [hogan.js](http://twitter.github.com/hogan.js/), [mustache.java](https://github.com/spullara/mustache.java) and [mustache.php](https://github.com/bobthecow/mustache.php).
- Built-in [goodies](Docs/Guides/goodies.md)
- GRMustache.swift does not rely on the Objective-C runtime. It lets you feed your templates with ad-hoc values or your existing models, without forcing you to refactor your Swift code into Objective-C objects.


Usage
-----

The library is built around **two main APIs**:

- The `Template(...)` initializer that loads a template.
- The `Template.render(...)` method that renders your data.


`document.mustache`:

```mustache
Hello {{name}}
Your beard trimmer will arrive on {{format(date)}}.
{{#late}}
Well, on {{format(realDate)}} because of a Martian attack.
{{/late}}
```

```swift
import Mustache

// Load the `document.mustache` resource of the main bundle
let template = try Template(named: "document")

// Let template format dates with `{{format(...)}}`
let dateFormatter = DateFormatter()
dateFormatter.dateStyle = .medium
template.register(dateFormatter, forKey: "format")

// The rendered data
let data: [String: Any] = [
    "name": "Arthur",
    "date": Date(),
    "realDate": Date().addingTimeInterval(60*60*24*3),
    "late": true
]

// The rendering: "Hello Arthur..."
let rendering = try template.render(data)
```


Installation
------------

### CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Xcode projects.

To use GRMustache.swift with CocoaPods, specify in your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!

pod 'GRMustache.swift'
```


### Carthage

[Carthage](https://github.com/Carthage/Carthage) is another dependency manager for Xcode projects.

To use GRMustache.swift with Carthage, specify in your Cartfile:

```
github "groue/GRMustache.swift"
```


### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is the open source tool for managing the distribution of Swift code.

To use GRMustache.swift with the Swift Package Manager, add https://github.com/groue/GRMustache.swift to the list of your package dependencies:

```swift
import PackageDescription

let package = Package(
    name: "MyPackage",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/groue/GRMustache.swift", majorVersion: 2, minor: 0),
    ]
)
```

Check [groue/GRMustacheSPM](https://github.com/groue/GRMustacheSPM) for a sample Swift package that uses GRMustache.swift.


### Manually

1. Download a copy of GRMustache.swift.

2. Checkout the latest GRMustache.swift version:
    
    ```sh
    cd [GRMustache.swift directory]
    git checkout 2.0.0
    ````
    
3. Embed the `Mustache.xcodeproj` project in your own project.

4. Add the `MustacheOSX`, `MustacheiOS`, or `MustacheWatchOS` target in the **Target Dependencies** section of the **Build Phases** tab of your application target.

5. Add the the `Mustache.framework` from the targetted platform to the **Embedded Binaries** section of the **General**  tab of your target.

See [MustacheDemoiOS](Docs/DemoApps/MustacheDemoiOS) for an example of such integration.


Documentation
=============

To fiddle with the library, open the `Xcode/Mustache.xcworkspace` workspace: it contains a Mustache-enabled Playground at the top of the files list.

External links:

- [The Mustache Language](http://mustache.github.io/mustache.5.html): the Mustache language itself. You should start here.
- [GRMustache.swift Reference](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Classes/Template.html) on cocoadocs.org

Rendering templates:

- [Loading Templates](#loading-templates)
- [Errors](#errors)
- [Mustache Tags Reference](#mustache-tags-reference)
- [The Context Stack and Expressions](#the-context-stack-and-expressions)

Feeding templates:

- [Values](#values)
- [Standard Swift Types Reference](#standard-swift-types-reference)
- [Custom Types](#custom-types)
- [Lambdas](#lambdas)
- [Filters](#filters)
- [Advanced Boxes](#advanced-boxes)

Misc:

- [Built-in goodies](#built-in-goodies)


Loading Templates
-----------------

Templates may come from various sources:

- **Raw Swift strings:**

    ```swift
    let template = try Template(string: "Hello {{name}}")
    ```

- **Bundle resources:**

    ```swift
    // Loads the "document.mustache" resource of the main bundle:
    let template = try Template(named: "document")
    ```

- **Files and URLs:**

    ```swift
    let template = try Template(path: "/path/to/document.mustache")
    let template = try Template(URL: templateURL)
    ```

- **Template Repositories:**
    
    Template repositories represent a group of templates. They can be configured independently, and provide neat features like template caching. For example:
    
    ```swift
    // The repository of Bash templates, with extension ".sh":
    let repo = TemplateRepository(bundle: Bundle.main, templateExtension: "sh")
    
    // Disable HTML escaping for Bash scripts:
    repo.configuration.contentType = .text
    
    // Load the "script.sh" resource:
    let template = repo.template(named: "script")!
    ```

For more information, check:

- [Template.swift](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Classes/Template.html)
- [TemplateRepository.swift](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Classes/TemplateRepository.html)


Errors
------

Not funny, but they happen. Standard errors of domain NSCocoaErrorDomain, etc. may be thrown whenever the library needs to access the file system or other system resource. Mustache-specific errors are of type `MustacheError`:

```swift
do {
    let template = try Template(named: "Document")
    let rendering = try template.render(data)
} catch let error as MustacheError {
    // Parse error at line 2 of template /path/to/template.mustache:
    // Unclosed Mustache tag.
    error.description
    
    // templateNotFound, parseError, or renderError
    error.kind
    
    // The eventual template at the source of the error. Can be a path, a URL,
    // a resource name, depending on the repository data source.
    error.templateID
    
    // The eventual faulty line.
    error.lineNumber
    
    // The eventual underlying error.
    error.underlyingError
}
```


Mustache Tags Reference
-----------------------

Mustache is based on tags: `{{name}}`, `{{#registered}}...{{/registered}}`, `{{>include}}`, etc.

Each one of them performs its own little task:

- [Variable Tags](#variable-tags) `{{name}}` render values.
- [Section Tags](#section-tags) `{{#items}}...{{/items}}` perform conditionals, loops, and object scoping.
- [Inverted Section Tags](#inverted-section-tags) `{{^items}}...{{/items}}` are sisters of regular section tags, and render when the other one does not.
- [Partial Tags](#partial-tags) `{{>partial}}` let you include a template in another one.
    - [File system](#file-system)
    - [Bundle Resources](#bundle-resources)
    - [Dynamic Partials](#dynamic-partials)
- [Partial Override Tags](#partial-override-tags) `{{<layout}}...{{/layout}}` provide *template inheritance*.
    - [Dynamic Partial Overrides](#dynamic-partial-overrides)
- [Set Delimiters Tags](#set-delimiters-tags) `{{=<% %>=}}` let you change the tag delimiters.
- [Comment Tags](#comment-tags) let you comment: `{{! Wow. Such comment. }}`
- [Pragma Tags](#pragma-tags) trigger implementation-specific features.


### Variable Tags

A *Variable tag* `{{value}}` renders the value associated with the key `value`, HTML-escaped. To avoid HTML-escaping, use triple mustache tags `{{{value}}}`:

```swift
let template = try Template(string: "{{value}} - {{{value}}}")

// Mario &amp; Luigi - Mario & Luigi
let data = ["value": "Mario & Luigi"]
let rendering = try template.render(data)
```


### Section Tags

A *Section tag* `{{#value}}...{{/value}}` is a common syntax for three different usages:

- conditionally render a section.
- loop over a collection.
- dig inside an object.

Those behaviors are triggered by the value associated with `value`:


#### Falsey values

If the value is *falsey*, the section is not rendered. Falsey values are:

- missing values
- false boolean
- zero numbers
- empty strings
- empty collections
- NSNull

For example:

```swift
let template = try Template(string: "<{{#value}}Truthy{{/value}}>")

// "<Truthy>"
try template.render(["value": true])
// "<>"
try template.render([:])                  // missing value
try template.render(["value": false])     // false boolean
```


#### Collections

If the value is a *collection* (an array or a set), the section is rendered as many times as there are elements in the collection, and inner tags have direct access to the keys of elements:

Template:

```mustache
{{# friends }}
- {{ name }}
{{/ friends }}
```

Data:

```swift
[
  "friends": [
    [ "name": "Hulk Hogan" ],
    [ "name": "Albert Einstein" ],
    [ "name": "Tom Selleck" ],
  ]
]
```

Rendering:

```
- Hulk Hogan
- Albert Einstein
- Tom Selleck
```


#### Other Values

If the value is not falsey, and not a collection, then the section is rendered once, and inner tags have direct access to the value's keys:

Template:

```mustache
{{# user }}
- {{ name }}
- {{ score }}
{{/ user }}
```

Data:

```swift
[
  "user": [
    "name": "Mario"
    "score": 1500
  ]
]
```

Rendering:

```
- Mario
- 1500
```


### Inverted Section Tags

An *Inverted section tag* `{{^value}}...{{/value}}` renders when a regular section `{{#value}}...{{/value}}` would not. You can think of it as the Mustache "else" or "unless".

Template:

```
{{# persons }}
- {{name}} is {{#alive}}alive{{/alive}}{{^alive}}dead{{/alive}}.
{{/ persons }}
{{^ persons }}
Nobody
{{/ persons }}
```

Data:

```swift
[
  "persons": []
]
```

Rendering:

```
Nobody
```

Data:

```swift
[
  "persons": [
    ["name": "Errol Flynn", "alive": false],
    ["name": "Sacha Baron Cohen", "alive": true]
  ]
]
```

Rendering:

```
- Errol Flynn is dead.
- Sacha Baron Cohen is alive.
```


### Partial Tags

A *Partial tag* `{{> partial }}` includes another template, identified by its name. The included template has access to the currently available data:

`document.mustache`:

```mustache
Guests:
{{# guests }}
  {{> person }}
{{/ guests }}
```

`person.mustache`:

```mustache
{{ name }}
```

Data:

```swift
[
  "guests": [
    ["name": "Frank Zappa"],
    ["name": "Lionel Richie"]
  ]
]
```

Rendering:

```
Guests:
- Frank Zappa
- Lionel Richie
```

Recursive partials are supported, but your data should avoid infinite loops.

Partial lookup depends on the origin of the main template:


#### File System

Partial names are **relative paths** when the template comes from the file system (via paths or URLs):

```swift
// Load /path/document.mustache
let template = Template(path: "/path/document.mustache")

// {{> partial }} includes /path/partial.mustache.
// {{> shared/partial }} includes /path/shared/partial.mustache.
```

Partials have the same file extension as the main template.

```swift
// Loads /path/document.html
let template = Template(path: "/path/document.html")

// {{> partial }} includes /path/partial.html.
```

When your templates are stored in a hierarchy of directories, you can use **absolute paths** to partials, with a leading slash. For that, you need a *template repository* which will define the root of absolute partial paths:

```swift
let repository = TemplateRepository(directoryPath: "/path")
let template = repository.template(named: ...)

// {{> /shared/partial }} includes /path/shared/partial.mustache.
```


#### Bundle Resources
    
Partial names are interpreted as **resource names** when the template is a bundle resource:

```swift
// Load the document.mustache resource from the main bundle
let template = Template(named: "document")

// {{> partial }} includes the partial.mustache resource.
```

Partials have the same file extension as the main template.

```swift
// Load the document.html resource from the main bundle
let template = Template(named: "document", templateExtension: "html")

// {{> partial }} includes the partial.html resource.
```


#### General case

Generally speaking, partial names are always interpreted by a **Template Repository**:

- `Template(named:...)` uses a bundle-based template repository: partial names are resource names.
- `Template(path:...)` uses a file-based template repository: partial names are relative paths.
- `Template(URL:...)` uses a URL-based template repository: partial names are relative URLs.
- `Template(string:...)` uses a template repository that can’t load any partial.
- `templateRepository.template(named:...)` uses the partial loading mechanism of the template repository.

Check [TemplateRepository.swift](Sources/TemplateRepository.swift) for more information ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Classes/TemplateRepository.html)).


#### Dynamic Partials

A tag `{{> partial }}` includes a template, the one that is named "partial". One can say it is **statically** determined, since that partial has already been loaded before the template is rendered:

```swift
let repo = TemplateRepository(bundle: Bundle.main)
let template = try repo.template(string: "{{#user}}{{>partial}}{{/user}}")

// Now the `partial.mustache` resource has been loaded. It will be used when
// the template is rendered. Nothing can change that.
```

You can also include **dynamic partials**. To do so, use a regular variable tag `{{ partial }}`, and provide the template of your choice for the key "partial" in your rendered data:

```swift
// A template that delegates the rendering of a user to a partial.
// No partial has been loaded yet.
let template = try Template(string: "{{#user}}{{partial}}{{/user}}")

// The user
let user = ["firstName": "Georges", "lastName": "Brassens", "occupation": "Singer"]

// Two different partials:
let partial1 = try Template(string: "{{firstName}} {{lastName}}")
let partial2 = try Template(string: "{{occupation}}")

// Two different renderings of the same template:
// "Georges Brassens"
try template.render(["user": user, "partial": partial1])
// "Singer"
try template.render(["user": user, "partial": partial2])
```


### Partial Override Tags

GRMustache.swift supports **Template Inheritance**, like [hogan.js](http://twitter.github.com/hogan.js/), [mustache.java](https://github.com/spullara/mustache.java) and [mustache.php](https://github.com/bobthecow/mustache.php).

A *Partial Override Tag* `{{< layout }}...{{/ layout }}` includes another template inside the rendered template, just like a regular [partial tag](#partial-tags) `{{> partial}}`.

However, this time, the included template can contain *blocks*, and the rendered template can override them. Blocks look like sections, but use a dollar sign: `{{$ overrideMe }}...{{/ overrideMe }}`.

The included template `layout.mustache` below has `title` and `content` blocks that the rendered template can override:

```mustache
<html>
<head>
    <title>{{$ title }}Default title{{/ title }}</title>
</head>
<body>
    <h1>{{$ title }}Default title{{/ title }}</h1>
    {{$ content }}
        Default content
    {{/ content }}}
</body>
</html>
```

The rendered template `article.mustache`:

```mustache
{{< layout }}

    {{$ title }}{{ article.title }}{{/ title }}
    
    {{$ content }}
        {{{ article.html_body }}}
        <p>by {{ article.author }}</p>
    {{/ content }}
    
{{/ layout }}
```

```swift
let template = try Template(named: "article")
let data = [
    "article": [
        "title": "The 10 most amazing handlebars",
        "html_body": "<p>...</p>",
        "author": "John Doe"
    ]
]
let rendering = try template.render(data)
```

The rendering is a full HTML page:

```HTML
<html>
<head>
    <title>The 10 most amazing handlebars</title>
</head>
<body>
    <h1>The 10 most amazing handlebars</h1>
    <p>...</p>
    <p>by John Doe</p>
</body>
</html>
```

A few things to know:

- A block `{{$ title }}...{{/ title }}` is always rendered, and rendered once. There is no boolean checks, no collection iteration. The "title" identifier is a name that allows other templates to override the block, not a key in your rendered data.

- A template can contain several partial override tags.

- A template can override a partial which itself overrides another one. Recursion is possible, but your data should avoid infinite loops.

- Generally speaking, any part of a template can be refactored with partials and partial override tags, without requiring any modification anywhere else (in other templates that depend on it, or in your code).


#### Dynamic Partial Overrides

Like a regular partial tag, a partial override tag `{{< layout }}...{{/ layout }}` includes a statically determined template, the very one that is named "layout".

To override a dynamic partial, use a regular section tag `{{# layout }}...{{/ layout }}`, and provide the template of your choice for the key "layout" in your rendered data.


### Set Delimiters Tags

Mustache tags are generally enclosed by "mustaches" `{{` and `}}`. A *Set Delimiters Tag* can change that, right inside a template.

```
Default tags: {{ name }}
{{=<% %>=}}
ERB-styled tags: <% name %>
<%={{ }}=%>
Default tags again: {{ name }}
```

There are also APIs for setting those delimiters. Check `Configuration.tagDelimiterPair` in [Configuration.swift](Sources/Configuration.swift) ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Structs/Configuration.html)).


### Comment Tags

`{{! Comment tags }}` are simply not rendered at all.


### Pragma Tags

Several Mustache implementations use *Pragma tags*. They start with a percent `%` and are not rendered at all. Instead, they trigger implementation-specific features.

GRMustache.swift interprets two pragma tags that set the content type of the template:

- `{{% CONTENT_TYPE:TEXT }}`
- `{{% CONTENT_TYPE:HTML }}`

**HTML templates** is the default. They HTML-escape values rendered by variable tags `{{name}}`.

In a **text template**, there is no HTML-escaping. Both `{{name}}` and `{{{name}}}` have the same rendering. Text templates are globally HTML-escaped when included in HTML templates.

For a more complete discussion, see the documentation of `Configuration.contentType` in [Configuration.swift](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Structs/Configuration.html).


The Context Stack and Expressions
---------------------------------

### The Context Stack

Variable and section tags fetch values in the data you feed your templates with: `{{name}}` looks for the key "name" in your input data, or, more precisely, in the *context stack*.

That context stack grows as the rendering engine enters sections, and shrinks when it leaves. Its top value, pushed by the last entered section, is where a `{{name}}` tag starts looking for the "name" identifier. If this top value does not provide the key, the tag digs further down the stack, until it finds the name it looks for.

For example, given the template:

```mustache
{{#family}}
- {{firstName}} {{lastName}}
{{/family}}
```

Data:

```swift
[
    "lastName": "Johnson",
    "family": [
        ["firstName": "Peter"],
        ["firstName": "Barbara"],
        ["firstName": "Emily", "lastName": "Scott"],
    ]
]
```

The rendering is:

```
- Peter Johnson
- Barbara Johnson
- Emily Scott
```

The context stack is usually initialized with the data you render your template with:

```swift
// The rendering starts with a context stack containing `data`
template.render(data)
```

Precisely speaking, a template has a *base context stack* on top of which the rendered data is added. This base context is always available whatever the rendered data. For example:

```swift
// The base context contains `baseData`
template.extendBaseContext(baseData)

// The rendering starts with a context stack containing `baseData` and `data`
template.render(data)
```

The base context is usually a good place to register [filters](#filters):

```swift
template.extendBaseContext(["each": StandardLibrary.each])
```

But you will generally register filters with the `register(:forKey:)` method, because it prevents the rendered data from overriding the name of the filter:

```swift
template.register(StandardLibrary.each, forKey: "each")
```

See [Template](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Classes/Template.html) for more information on the base context.


### Expressions

Variable and section tags contain *Expressions*. `name` is an expression, but also `article.title`, and `format(article.modificationDate)`. When a tag renders, it evaluates its expression, and renders the result.

There are four kinds of expressions:

- **The dot** `.` aka "Implicit Iterator" in the Mustache lingo:
    
    Implicit iterator evaluates to the top of the context stack, the value pushed by the last entered section.
    
    It lets you iterate over collection of strings, for example. `{{#items}}<{{.}}>{{/items}}` renders `<1><2><3>` when given [1,2,3].

- **Identifiers** like `name`:
    
    Evaluation of identifiers like `name` goes through the context stack until a value provides the `name` key.
    
    Identifiers can not contain white space, dots, parentheses and commas. They can not start with any of those characters: `{}&$#^/<>`.

- **Compound expressions** like `article.title` and generally `<expression>.<identifier>`:
    
    This time there is no going through the context stack: `article.title` evaluates to the title of the article, regardless of `title` keys defined by enclosing contexts.
    
    `.title` (with a leading dot) is a compound expression based on the implicit iterator: it looks for `title` at the top of the context stack.
    
    Compare these three templates:
    
    - `...{{# article }}{{  title }}{{/ article }}...`
    - `...{{# article }}{{ .title }}{{/ article }}...`
    - `...{{ article.title }}...`
    
    The first will look for `title` anywhere in the context stack, starting with the `article` object.
    
    The two others are identical: they ensure the `title` key comes from the very `article` object.

- **Filter expressions** like `format(date)` and generally `<expression>(<expression>, ...)`:
    
    [Filters](#filters) are introduced below.


Values
------

Templates render values:

```swift
template.render(["name": "Luigi"])
template.render(Person(name: "Luigi"))
```

You can feed templates with:

- Values that adopt the `MustacheBoxable` protocol such as `String`, `Int`, `NSObject` and its subclasses (see [Standard Swift Types Reference](#standard-swift-types-reference) and [Custom Types](#custom-types))

- Arrays, sets, and dictionaries (Swift arrays, sets, dictionaries, and Foundation collections). *This does not include other collections, such as Swift ranges.*

- A few function types such as [filter functions](#filters), [lambdas](#lambdas), and other functions involved in [advanced boxes](#advanced-boxes).

- [Goodies](Docs/Guides/goodies.md) such as Foundation's formatters.


Standard Swift Types Reference
------------------------------

GRMustache.swift comes with built-in support for the following standard Swift types:

- [Bool](#bool)
- [Numeric Types](#numeric-types): Int, UInt, Int64, UInt64, Float, Double and CGFloat.
- [String](#string)
- [Set](#set)
- [Array](#array)
- [Dictionary](#dictionary)
- [NSObject](#nsobject)


### Bool

- `{{bool}}` renders "0" or "1".
- `{{#bool}}...{{/bool}}` renders if and only if *bool* is true.
- `{{^bool}}...{{/bool}}` renders if and only if *bool* is false.


### Numeric Types

GRMustache supports `Int`, `UInt`, `Int64`, `UInt64`, `Float`, `Double` and `CGFloat`:

- `{{number}}` renders the standard Swift string interpolation of *number*.
- `{{#number}}...{{/number}}` renders if and only if *number* is not 0 (zero).
- `{{^number}}...{{/number}}` renders if and only if *number* is 0 (zero).

The Swift types `Int8`, `UInt8`, etc. have no built-in support: turn them into one of the three general types before injecting them into templates.

To format numbers, you can use `NumberFormatter`:

```swift
let percentFormatter = NumberFormatter()
percentFormatter.numberStyle = .percent

let template = try Template(string: "{{ percent(x) }}")
template.register(percentFormatter, forKey: "percent")

// Rendering: 50%
let data = ["x": 0.5]
let rendering = try template.render(data)
```

[More info on Formatter](Docs/Guides/goodies.md#formatter).


### String

- `{{string}}` renders *string*, HTML-escaped.
- `{{{string}}}` renders *string*, not HTML-escaped.
- `{{#string}}...{{/string}}` renders if and only if *string* is not empty.
- `{{^string}}...{{/string}}` renders if and only if *string* is empty.

Exposed keys:

- `string.length`: the length of the string.


### Set

- `{{set}}` renders the concatenation of the renderings of set elements.
- `{{#set}}...{{/set}}` renders as many times as there are elements in the set, pushing them on top of the [context stack](#the-context-stack).
- `{{^set}}...{{/set}}` renders if and only if the set is empty.

Exposed keys:

- `set.first`: the first element.
- `set.count`: the number of elements in the set.


### Array

- `{{array}}` renders the concatenation of the renderings of array elements.
- `{{#array}}...{{/array}}` renders as many times as there are elements in the array, pushing them on top of the [context stack](#the-context-stack).
- `{{^array}}...{{/array}}` renders if and only if the array is empty.

Exposed keys:

- `array.first`: the first element.
- `array.last`: the last element.
- `array.count`: the number of elements in the array.

In order to render array indexes, or vary the rendering according to the position of elements in the array, use the [each](Docs/Guides/goodies.md#each) filter from the Standard Library:

`document.mustache`:

```
Users with their positions:
{{# each(users) }}
- {{ @indexPlusOne }}: {{ name }}
{{/}}

Comma-separated user names:
{{# each(users) }}{{ name }}{{^ @last }}, {{/}}{{/}}.
```

```swift
let template = try! Template(named: "document")

// Register StandardLibrary.each for the key "each":
template.register(StandardLibrary.each, forKey: "each")

// Users with their positions:
// - 1: Alice
// - 2: Bob
// - 3: Craig
// 
// Comma-separated user names: Alice, Bob, Craig.
let users = [["name": "Alice"], ["name": "Bob"], ["name": "Craig"]]
let rendering = try! template.render(["users": users])
```


### Dictionary

- `{{dictionary}}` renders the standard Swift string interpolation of *dictionary* (not very useful).
- `{{#dictionary}}...{{/dictionary}}` renders once, pushing the dictionary on top of the [context stack](#the-context-stack).
- `{{^dictionary}}...{{/dictionary}}` does not render.

In order to iterate over the key/value pairs of a dictionary, use the [each](Docs/Guides/goodies.md#each) filter from the Standard Library:

`document.mustache`:

```mustache
{{# each(dictionary) }}
    key: {{ @key }}, value: {{.}}
{{/}}
```

```swift
let template = try! Template(named: "document")

// Register StandardLibrary.each for the key "each":
template.register(StandardLibrary.each, forKey: "each")

// Renders "key: name, value: Freddy Mercury"
let dictionary = ["name": "Freddy Mercury"]
let rendering = try! template.render(["dictionary": dictionary])
```


### NSObject

The rendering of NSObject depends on the actual class:

- **NSFastEnumeration**
    
    When an object conforms to the NSFastEnumeration protocol, like **NSArray**, it renders just like Swift [Array](#array). **NSSet** is an exception, rendered as a Swift [Set](#set). **NSDictionary**, the other exception, renders as a Swift [Dictionary](#dictionary).

- **NSNumber** is rendered as a Swift [Bool](#bool), [Int, UInt, Int64, UInt64, Float or Double](#numeric-types), depending on its value.

- **NSString** is rendered as [String](#string)

- **NSNull** renders as:

    - `{{null}}` does not render.
    - `{{#null}}...{{/null}}` does not render.
    - `{{^null}}...{{/null}}` renders.

- For other NSObject, those default rules apply:

    - `{{object}}` renders the `description` method, HTML-escaped.
    - `{{{object}}}` renders the `description` method, not HTML-escaped.
    - `{{#object}}...{{/object}}` renders once, pushing the object on top of the [context stack](#the-context-stack).
    - `{{^object}}...{{/object}}` does not render.
    
    With support for Objective-C runtime, templates can render object properties: `{{ user.name }}`.
    
    Subclasses can alter this behavior by overriding the `mustacheBox` method of the `MustacheBoxable` protocol. For more information, check the rendering of [Custom Types](#custom-types) below.


Custom Types
------------

### NSObject subclasses

NSObject subclasses can trivially feed your templates:

```swift
// An NSObject subclass
class Person : NSObject {
    let name: String
    
    init(name: String) {
        self.name = name
    }
}

// Charlie Chaplin has a mustache.
let person = Person(name: "Charlie Chaplin")
let template = try Template(string: "{{name}} has a mustache.")
let rendering = try template.render(person)
```

When extracting values from your NSObject subclasses, GRMustache.swift uses the [Key-Value Coding](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/KeyValueCoding/Articles/KeyValueCoding.html) method `valueForKey:`, as long as the key is "safe" (safe keys are the names of declared properties, including NSManagedObject attributes).

Subclasses can alter this default behavior by overriding the `mustacheBox` method of the `MustacheBoxable` protocol, described below:


### Pure Swift Values and MustacheBoxable

Key-Value Coding is not available for Swift enums, structs and classes, regardless of eventual `@objc` or `dynamic` modifiers. Swift values can still feed templates, though, with a little help.

```swift
// Define a pure Swift object:
struct Person {
    let name: String
}
```

To let Mustache templates extract the `name` key out of a person so that they can render `{{ name }}` tags, we need to explicitly help the Mustache engine by conforming to the `MustacheBoxable` protocol:

```swift
extension Person : MustacheBoxable {
    
    // Feed templates with a dictionary:
    var mustacheBox: MustacheBox {
        return Box(["name": self.name])
    }
}
```

Your `mustacheBox` implementation will generally call the `Box` function on a regular [value](#values) that itself adopts the `MustacheBoxable` protocol (such as `String` or `Int`), or an array, a set, or a dictionary.

Now we can render persons, arrays of persons, dictionaries of persons, etc:

```swift
// Freddy Mercury has a mustache.
let person = Person(name: "Freddy Mercury")
let template = try Template(string: "{{name}} has a mustache.")
let rendering = try template.render(person)
```

Boxing a dictionary is an easy way to build a box. However there are many kinds of boxes: check the rest of this documentation.


Lambdas
-------

Mustache lambdas are functions that let you perform custom rendering. There are two kinds of lambdas: those that process section tags, and those that render variable tags.

```swift
// `{{fullName}}` renders just as `{{firstName}} {{lastName}}.`
let fullName = Lambda { "{{firstName}} {{lastName}}" }

// `{{#wrapped}}...{{/wrapped}}` renders the content of the section, wrapped in
// a <b> HTML tag.
let wrapped = Lambda { (string) in "<b>\(string)</b>" }

// <b>Frank Zappa is awesome.</b>
let templateString = "{{#wrapped}}{{fullName}} is awesome.{{/wrapped}}"
let template = try Template(string: templateString)
let data: [String: Any] = [
    "firstName": "Frank",
    "lastName": "Zappa",
    "fullName": fullName,
    "wrapped": wrapped]
let rendering = try template.render(data)
```

Lambdas are a special case of custom rendering functions. The raw `RenderFunction` type gives you extra flexibility when you need to perform custom rendering. See [CoreFunctions.swift](Sources/CoreFunctions.swift) ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Typealiases.html)).

> :point_up: **Note**: Mustache lambdas slightly overlap with [dynamic partials](#dynamic-partials). Lambdas are required by the Mustache specification. Dynamic partials are more efficient because they avoid parsing lambda strings over and over.


Filters
-------

Filters apply like functions, with parentheses: `{{ uppercase(name) }}`.

Generally speaking, using filters is a three-step process:

```swift
// 1. Define the filter using the `Filter()` function:
let uppercase = Filter(...)

// 2. Assign a name to your filter, and register it in a template:
template.register(uppercase, forKey: "uppercase")

// 3. Render
template.render(...)
```

It helps thinking about four kinds of filters:

- [Value filters](#value-filters), as in `{{ square(radius) }}`
- [Pre-rendering filters](#pre-rendering-filters), as in `{{ uppercase(...) }}`
- [Custom rendering filters](#custom-rendering-filters), as in `{{# pluralize(cats.count) }}cat{{/}}`
- [Advanced filters](#advanced-filters)


### Value Filters

Value filters transform any type of input. They can return anything as well.

For example, here is a `square` filter which squares integers:

```swift
// Define the `square` filter.
//
// square(n) evaluates to the square of the provided integer.
let square = Filter { (n: Int?) in
    guard let n = n else {
        // No value, or not an integer: return nil.
        // We could throw an error as well.
        return nil
    }
    
    // Return the result
    return n * n
}

// Register the square filter in our template:
let template = try Template(string: "{{n}} × {{n}} = {{square(n)}}")
template.register(square, forKey:"square")

// 10 × 10 = 100
let rendering = try template.render(["n": 10])
```


Filters can accept a precisely typed argument as above. You may prefer managing the value type yourself:

```swift
// Define the `abs` filter.
//
// abs(x) evaluates to the absolute value of x (Int or Double):
let absFilter = Filter { (box: MustacheBox) in
    switch box.value {
    case let int as Int:
        return abs(int)
    case let double as Double:
        return abs(double)
    default:
        return nil
    }
}
```


You can process collections and dictionaries as well, and return new ones:

```swift
// Define the `oneEveryTwoItems` filter.
//
// oneEveryTwoItems(collection) returns the array of even items in the input
// collection.
let oneEveryTwoItems = Filter { (box: MustacheBox) in
    // `box.arrayValue` returns a `[MustacheBox]` for all boxed collections
    // (Array, Set, NSArray, etc.).
    guard let boxes = box.arrayValue else {
        // No value, or not a collection: return the empty box
        return nil
    }
    
    // Rebuild another array with even indexes:
    var result: [MustacheBox] = []
    for (index, box) in boxes.enumerated() where index % 2 == 0 {
        result.append(box)
    }
    
    return result
}

// A template where the filter is used in a section, so that the items in the
// filtered array are iterated:
let templateString = "{{# oneEveryTwoItems(items) }}<{{.}}>{{/ oneEveryTwoItems(items) }}"
let template = try Template(string: templateString)

// Register the oneEveryTwoItems filter in our template:
template.register(oneEveryTwoItems, forKey: "oneEveryTwoItems")

// <1><3><5><7><9>
let rendering = try template.render(["items": Array(1..<10)])
```


Multi-arguments filters are OK as well. but you use the `VariadicFilter()` function, this time:

```swift
// Define the `sum` filter.
//
// sum(x, ...) evaluates to the sum of provided integers
let sum = VariadicFilter { (boxes: [MustacheBox]) in
    var sum = 0
    for box in boxes {
        sum += (box.value as? Int) ?? 0
    }
    return sum
}

// Register the sum filter in our template:
let template = try Template(string: "{{a}} + {{b}} + {{c}} = {{ sum(a,b,c) }}")
template.register(sum, forKey: "sum")

// 1 + 2 + 3 = 6
let rendering = try template.render(["a": 1, "b": 2, "c": 3])
```


Filters can chain and generally be part of more complex expressions:

    Circle area is {{ format(product(PI, circle.radius, circle.radius)) }} cm².


When you want to format values, just use NumberFormatter, DateFormatter, or generally any Foundation's Formatter. They are ready-made filters:

```swift
let percentFormatter = NumberFormatter()
percentFormatter.numberStyle = .percent

let template = try Template(string: "{{ percent(x) }}")
template.register(percentFormatter, forKey: "percent")

// Rendering: 50%
let data = ["x": 0.5]
let rendering = try template.render(data)
```

[More info on formatters](Docs/Guides/goodies.md#formatter).


### Pre-Rendering Filters

Value filters as seen above process input values, which may be of any type (bools, ints, collections, etc.). Pre-rendering filters always process strings, whatever the input value. They have the opportunity to alter those strings before they get actually included in the final template rendering.

You can, for example, reverse a rendering:

```swift
// Define the `reverse` filter.
//
// reverse(x) renders the reversed rendering of its argument:
let reverse = Filter { (rendering: Rendering) in
    let reversedString = String(rendering.string.characters.reversed())
    return Rendering(reversedString, rendering.contentType)
}

// Register the reverse filter in our template:
let template = try Template(string: "{{reverse(value)}}")
template.register(reverse, forKey: "reverse")

// ohcuorG
try template.render(["value": "Groucho"])

// 321
try template.render(["value": 123])
```

Such filter does not quite process a raw string, as you have seen. It processes a `Rendering`, which is a flavored string, a string with its contentType (text or HTML).

This rendering will usually be text: simple values (ints, strings, etc.) render as text. Our reversing filter preserves this content-type, and does not mangle HTML entities:

```swift
// &gt;lmth&lt;
try template.render(["value": "<html>"])
```


### Custom Rendering Filters

An example will show how they can be used:

```swift
// Define the `pluralize` filter.
//
// {{# pluralize(count) }}...{{/ }} renders the plural form of the
// section content if the `count` argument is greater than 1.
let pluralize = Filter { (count: Int?, info: RenderingInfo) in
    
    // The inner content of the section tag:
    var string = info.tag.innerTemplateString
    
    // Pluralize if needed:
    if let count = count, count > 1 {
        string += "s"  // naive
    }
    
    return Rendering(string)
}

// Register the pluralize filter in our template:
let templateString = "I have {{ cats.count }} {{# pluralize(cats.count) }}cat{{/ }}."
let template = try Template(string: templateString)
template.register(pluralize, forKey: "pluralize")

// I have 3 cats.
let data = ["cats": ["Kitty", "Pussy", "Melba"]]
let rendering = try template.render(data)
```

As those filters perform custom rendering, they are based on `RenderFunction`, just like [lambdas](#lambdas). Check the `RenderFunction` type in [CoreFunctions.swift](Sources/CoreFunctions.swift) for more information about the `RenderingInfo` and `Rendering` types ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/2.0.0/Typealiases.html)).


### Advanced Filters

All the filters seen above are particular cases of `FilterFunction`. "Value filters", "Pre-rendering filters" and "Custom rendering filters" are common use cases that are granted with specific APIs.

Yet the library ships with a few built-in filters that don't quite fit any of those categories. Go check their [documentation](Docs/Guides/goodies.md). And since they are all written with public GRMustache.swift APIs, check also their [source code](Mustache/Goodies), for inspiration. The general `FilterFunction` itself is detailed in [CoreFunctions.swift](Sources/CoreFunctions.swift) ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/0.11.0/Typealiases.html)).


Advanced Boxes
--------------

Values that feed templates are able of many different behaviors. Let's review some of them:

- Bool can trigger or prevent the rendering of sections:

    ```
    {{# isVerified }}VERIFIED{{/ isVerified }}
    {{^ isVerified }}NOT VERIFIED{{/ isVerified }}
    ```

- Arrays render sections multiple times, and expose the `count`, `first`, and `last` keys:
    
    ```
    You see {{ objects.count }} objects:
    {{# objects }}
    - {{ name }}
    {{/ objects }}
    ```

- Dictionaries expose all their keys:
    
    ```
    {{# user }}
    - {{ name }}
    - {{ age }}
    {{/ user }}
    ```

- NSObject exposes all its properties:
    
    ```
    {{# user }}
    - {{ name }}
    - {{ age }}
    {{/ user }}
    ```

- Foundation's Formatter is able to format values ([more information](Docs/Guides/goodies.md#formatter)):
    
    ```
    {{ format(date) }}
    ```

- `StandardLibrary.each` is a filter that defines some extra keys when iterating an array ([more information](Docs/Guides/goodies.md#each)):
    
    ```
    {{# each(items) }}
    - {{ @indexPlusOne }}: {{ name }}
    {{/}}
    ```

This variety of behaviors is made possible by the `MustacheBox` type. Whenever a value, array, filter, etc. feeds a template, it is turned into a box that interact with the rendering engine.

Let's describe in detail the rendering of the `{{ F(A) }}` tag, and shed some light on the available customizations:

1. The `A` and `F` expressions are evaluated: the rendering engine looks in the [context stack](#the-context-stack) for boxes that return a non-empty box for the keys "A" and "F". The key-extraction service is provided by a customizable `KeyedSubscriptFunction`.
    
    This is how NSObject exposes its properties, and Dictionary, its keys.

2. The customizable `FilterFunction` of the F box is evaluated with the A box as an argument.
    
    The Result box may well depend on the customizable value of the A box, but all other facets of the A box may be involved. This is why there are various types of [filters](#filters).

3. The rendering engine then looks in the context stack for all boxes that have a customized `WillRenderFunction`. Those functions have an opportunity to process the Result box, and eventually return another one.
    
    This is how, for example, a boxed [DateFormatter](Docs/Guides/goodies.md#formatter) can format all dates in a section: its `WillRenderFunction` formats dates into strings.

4. The resulting box is ready to be rendered. For regular and inverted section tags, the rendering engine queries the customizable boolean value of the box, so that `{{# F(A) }}...{{/}}` and `{{^ F(A) }}...{{/}}` can't be both rendered.
    
    The Bool type obviously has a boolean value, but so does String, so that empty strings are considered [falsey](#falsey-values).

5. The resulting box gets eventually rendered: its customizable `RenderFunction` is executed. Its `Rendering` result is HTML-escaped, depending on its content type, and appended to the final template rendering.
    
    [Lambdas](#lambdas) use such a `RenderFunction`, so do [pre-rendering filters](#pre-rendering-filters) and [custom rendering filters](#custom-rendering-filters).

6. Finally the rendering engine looks in the context stack for all boxes that have a customized `DidRenderFunction`.
    
    This one is used by [Localizer](Docs/Guides/goodies.md#localizer) and [Logger](Docs/Guides/goodies.md#logger) goodies.

All those customizable properties are exposed in the low-level MustacheBox initializer:

```swift
// MustacheBox initializer
init(
    value value: Any? = nil,
    boolValue: Bool? = nil,
    keyedSubscript: KeyedSubscriptFunction? = nil,
    filter: FilterFunction? = nil,
    render: RenderFunction? = nil,
    willRender: WillRenderFunction? = nil,
    didRender: DidRenderFunction? = nil)
```

We'll below describe each of them individually, even though you can provide several ones at the same time:

- `value`
    
    The optional *value* parameter gives the boxed value. The value is used when the box is rendered (unless you provide a custom RenderFunction). It is also
    returned by the `value` property of MustacheBox.
    
    ```swift
    let aBox = MustacheBox(value: 1)
    
    // Renders "1"
    let template = try Template(string: "{{a}}")
    try template.render(["a": aBox])
    ```

- `boolValue`
    
    The optional *boolValue* parameter tells whether the Box should trigger or prevent the rendering of regular `{{#section}}...{{/}}` and inverted `{{^section}}...{{/}}` tags. The default value is true.
    
    ```swift
    // Render "true", "false"
    let template = try Template(string:"{{#.}}true{{/.}}{{^.}}false{{/.}}")
    try template.render(MustacheBox(boolValue: true))
    try template.render(MustacheBox(boolValue: false))
    ```

- `keyedSubscript`
    
    The optional *keyedSubscript* parameter is a `KeyedSubscriptFunction` that lets the Mustache engine extract keys out of the box. For example, the `{{a}}` tag would call the subscript function with `"a"` as an argument, and render the returned box.
    
    The default value is nil, which means that no key can be extracted.
    
    Check the `KeyedSubscriptFunction` type in [CoreFunctions.swift](Sources/CoreFunctions.swift) for more information ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/0.11.0/Typealiases.html)).
    
    ```swift
    let box = MustacheBox(keyedSubscript: { (key: String) in
        return Box("key:\(key)")
    })
    
    // Renders "key:a"
    let template = try Template(string:"{{a}}")
    try template.render(box)
    ```

- `filter`
    
    The optional *filter* parameter is a `FilterFunction` that lets the Mustache engine evaluate filtered expression that involve the box. The default value is nil, which means that the box can not be used as a filter.
    
    Check the `FilterFunction` type in [CoreFunctions.swift](Sources/CoreFunctions.swift) for more information ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/0.11.0/Typealiases.html)).
    
    ```swift
    let box = MustacheBox(filter: Filter { (x: Int?) in
        return x! * x!
    })
    
    // Renders "100"
    let template = try Template(string:"{{square(x)}}")
    try template.render(["square": box, "x": Box(10)])
    ```

- `render`
    
    The optional *render* parameter is a `RenderFunction` that is evaluated when the Box is rendered.
    
    The default value is nil, which makes the box perform default Mustache rendering:
    
    - `{{box}}` renders the built-in Swift String Interpolation of the value, HTML-escaped.
    - `{{{box}}}` renders the built-in Swift String Interpolation of the value, not HTML-escaped.
    - `{{#box}}...{{/box}}` pushes the box on the top of the context stack, and renders the section once.
    
    Check the `RenderFunction` type in [CoreFunctions.swift](Sources/CoreFunctions.swift) for more information ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/0.11.0/Typealiases.html)).
    
    ```swift
    let box = MustacheBox(render: { (info: RenderingInfo) in
        return Rendering("foo")
    })
    
    // Renders "foo"
    let template = try Template(string:"{{.}}")
    try template.render(box)
    ```

- `willRender` & `didRender`
    
    The optional *willRender* and *didRender* parameters are a `WillRenderFunction` and `DidRenderFunction` that are evaluated for all tags as long as the box is in the context stack.
    
    Check the `WillRenderFunction` and `DidRenderFunction` type in [CoreFunctions.swift](Sources/CoreFunctions.swift) for more information ([read on cocoadocs.org](http://cocoadocs.org/docsets/GRMustache.swift/0.11.0/Typealiases.html)).
    
    ```swift
    let box = MustacheBox(willRender: { (tag: Tag, box: MustacheBox) in
        return "baz"
    })
    
    // Renders "baz baz"
    let template = try Template(string:"{{#.}}{{foo}} {{bar}}{{/.}}")
    try template.render(box)
    ```

**By mixing all those parameters, you can finely tune the behavior of a box.**


Built-in goodies
----------------

The library ships with built-in [goodies](Docs/Guides/goodies.md) that will help you render your templates: format values, render array indexes, localize templates, etc.
