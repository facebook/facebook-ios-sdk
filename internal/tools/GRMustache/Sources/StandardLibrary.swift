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


/// The StandardLibrary exposes built-in goodies.
public struct StandardLibrary {
    
    /// As a filter, `HTMLEscape` returns its argument, HTML-escaped.
    /// 
    ///     <pre>
    ///     {{ HTMLEscape(content) }}
    ///     </pre>
    /// 
    /// When used in a section, `HTMLEscape` escapes all inner variable tags in a section:
    /// 
    ///     {{# HTMLEscape }}
    ///       {{ firstName }}
    ///       {{ lastName }}
    ///     {{/ HTMLEscape }}
    /// 
    /// Variable tags buried inside inner sections are escaped as well, so that
    /// you can render loop and conditional sections:
    /// 
    ///     {{# HTMLEscape }}
    ///       {{# items }}
    ///         {{ name }}
    ///       {{/ items }}
    ///     {{/ HTMLEscape }}
    /// 
    /// ### Usage
    /// 
    ///     let template = ...
    ///     template.register(StandardLibrary.HTMLEscape, forKey: "HTMLEscape")
    public static let HTMLEscape: MustacheBoxable = HTMLEscapeHelper()
    
    /// As a filter, `URLEscape` returns its argument, percent-escaped.
    /// 
    ///     <a href="http://google.com?q={{ URLEscape(query) }}">...</a>
    /// 
    /// When used in a section, `URLEscape` escapes all inner variable tags in a
    /// section:
    /// 
    ///     {{# URLEscape }}
    ///       <a href="http://google.com?q={{query}}&amp;hl={{language}}">...</a>
    ///     {{/ URLEscape }}
    /// 
    /// Variable tags buried inside inner sections are escaped as well, so that
    /// you can render loop and conditional sections:
    /// 
    ///     {{# URLEscape }}
    ///       <a href="http://google.com?q={{query}}{{#language}}&amp;hl={{language}}{{/language}}">...</a>
    ///     {{/ URLEscape }}
    /// 
    /// ### Usage
    /// 
    ///     let template = ...
    ///     template.register(StandardLibrary.URLEscape, forKey: "URLEscape")
    public static let URLEscape: MustacheBoxable = URLEscapeHelper()
    
    /// As a filter, `javascriptEscape` outputs a Javascript and JSON-savvy string:
    /// 
    ///     <script type="text/javascript">
    ///       var name = "{{ javascriptEscape(name) }}";
    ///     </script>
    /// 
    /// When used in a section, `javascriptEscape` escapes all inner variable
    /// tags in a section:
    /// 
    ///     <script type="text/javascript">
    ///       {{# javascriptEscape }}
    ///         var firstName = "{{ firstName }}";
    ///         var lastName = "{{ lastName }}";
    ///       {{/ javascriptEscape }}
    ///     </script>
    /// 
    /// Variable tags buried inside inner sections are escaped as well, so that
    /// you can render loop and conditional sections:
    /// 
    ///     <script type="text/javascript">
    ///       {{# javascriptEscape }}
    ///         var firstName = {{# firstName }}"{{ firstName }}"{{/}}{{^ firstName }}null{{/}};
    ///         var lastName = {{# lastName }}"{{ lastName }}"{{/}}{{^ lastName }}null{{/}};
    ///       {{/ javascriptEscape }}
    ///     </script>
    /// 
    /// ### Usage
    /// 
    ///     let template = ...
    ///     template.register(StandardLibrary.javascriptEscape, forKey: "javascriptEscape")
    public static let javascriptEscape: MustacheBoxable = JavascriptEscapeHelper()
    
    /// Iteration is natural to Mustache templates:
    /// `{{# users }}{{ name }}, {{/ users }}` renders "Alice, Bob, etc." when the
    /// `users` key is given a list of users.
    /// 
    /// The `each` filter gives you some extra keys:
    /// 
    /// - `@index` contains the 0-based index of the item (0, 1, 2, etc.)
    /// - `@indexPlusOne` contains the 1-based index of the item (1, 2, 3, etc.)
    /// - `@indexIsEven` is true if the 0-based index is even.
    /// - `@first` is true for the first item only.
    /// - `@last` is true for the last item only.
    /// 
    /// Given the following template:
    /// 
    ///     One line per user:
    ///     {{# each(users) }}
    ///     - {{ @index }}: {{ name }}
    ///     {{/}}
    /// 
    ///     Comma-separated user names:
    ///     {{# each(users) }}{{ name }}{{^ @last }}, {{/}}{{/}}.
    /// 
    /// The rendering reads:
    /// 
    ///     One line per user:
    ///     - 0: Alice
    ///     - 1: Bob
    ///     - 2: Craig
    /// 
    ///     Comma-separated user names: Alice, Bob, Craig.
    /// 
    /// When provided with a dictionary, `each` iterates each key/value pair of the
    /// dictionary, stores the key in `@key`, and sets the value as the current
    /// context:
    /// 
    ///     {{# each(dictionary) }}
    ///     - {{ @key }}: {{.}}
    ///     {{/}}
    /// 
    /// Renders:
    /// 
    ///     - name: Alice
    ///     - score: 200
    ///     - level: 5
    /// 
    /// The other positional keys `@index`, `@first`, etc. are still available when
    /// iterating dictionaries.
    /// 
    /// ### Usage
    /// 
    ///     let template = ...
    ///     template.register(StandardLibrary.each, forKey: "each")
    public static let each = EachFilter
    
    /// The zip filter iterates several lists all at once. On each step, one object
    /// from each input list enters the rendering context, and makes its own keys
    /// available for rendering.
    /// 
    /// Given the Mustache template:
    /// 
    ///     {{# zip(users, teams, scores) }}
    ///     - {{ name }} ({{ team }}): {{ score }} points
    ///     {{/}}
    /// 
    /// The following JSON input:
    /// 
    ///     {
    ///       "users": [
    ///         { "name": "Alice" },
    ///         { "name": "Bob" },
    ///       ],
    ///       "teams": [
    ///         { "team": "iOS" },
    ///         { "team": "Android" },
    ///       ],
    ///       "scores": [
    ///         { "score": 100 },
    ///         { "score": 200 },
    ///       ]
    ///     }
    /// 
    /// The rendering is:
    /// 
    ///     - Alice (iOS): 100 points
    ///     - Bob (Android): 200 points
    /// 
    /// In the example above, the first step has consumed (Alice, iOS and 100), and
    /// the second one (Bob, Android and 200).
    /// 
    /// The zip filter renders a section as many times as there are elements in the
    /// longest of its argument: exhausted lists simply do not add anything to the
    /// rendering context.
    /// 
    /// ### Usage
    /// 
    ///     let template = ...
    ///     template.register(StandardLibrary.zip, forKey: "zip")
    public static let zip = ZipFilter
}
