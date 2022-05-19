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

final class JavascriptEscapeHelper : MustacheBoxable {
    
    var mustacheBox: MustacheBox {
        // Return a multi-facetted box, because JavascriptEscape interacts in
        // various ways with Mustache rendering.
        return MustacheBox(
            // It has a value:
            value: self,
            
            // JavascriptEscape can be used as a filter: {{ javascriptEscape(x) }}:
            filter: Filter(filter),
            
            // JavascriptEscape escapes all variable tags: {{# javascriptEscape }}...{{ x }}...{{/ javascriptEscape }}
            willRender: willRender)
    }
    
    // This function is used for evaluating `javascriptEscape(x)` expressions.
    private func filter(_ rendering: Rendering) throws -> Rendering {
        return Rendering(JavascriptEscapeHelper.escapeJavascript(rendering.string), rendering.contentType)
    }
    
    // A WillRenderFunction: this function lets JavascriptEscape change values that
    // are about to be rendered to their escaped counterpart.
    //
    // It is activated as soon as the formatter enters the context stack, when
    // used in a section {{# javascriptEscape }}...{{/ javascriptEscape }}.
    private func willRender(_ tag: Tag, box: MustacheBox) -> Any? {
        switch tag.type {
        case .variable:
            // We don't know if the box contains a String, so let's escape its
            // rendering.
            return { (info: RenderingInfo) -> Rendering in
                let rendering = try box.render(info)
                return try self.filter(rendering)
            }
        case .section:
            return box
        }
    }
    
    private class func escapeJavascript(_ string: String) -> String {
        // This table comes from https://github.com/django/django/commit/8c4a525871df19163d5bfdf5939eff33b544c2e2#django/template/defaultfilters.py
        //
        // Quoting Malcolm Tredinnick:
        // > Added extra robustness to the escapejs filter so that all invalid
        // > characters are correctly escaped. This avoids any chance to inject
        // > raw HTML inside <script> tags. Thanks to Mike Wiacek for the patch
        // > and Collin Grady for the tests.
        //
        // Quoting Mike Wiacek from https://code.djangoproject.com/ticket/7177
        // > The escapejs filter currently escapes a small subset of characters
        // > to prevent JavaScript injection. However, the resulting strings can
        // > still contain valid HTML, leading to XSS vulnerabilities. Using hex
        // > encoding as opposed to backslash escaping, effectively prevents
        // > Javascript injection and also helps prevent XSS. Attached is a
        // > small patch that modifies the _js_escapes tuple to use hex encoding
        // > on an expanded set of characters.
        //
        // The initial django commit used `\xNN` syntax. The \u syntax was
        // introduced later for JSON compatibility.
        
        let escapeTable: [Character: String] = [
            "\0": "\\u0000",
            "\u{01}": "\\u0001",
            "\u{02}": "\\u0002",
            "\u{03}": "\\u0003",
            "\u{04}": "\\u0004",
            "\u{05}": "\\u0005",
            "\u{06}": "\\u0006",
            "\u{07}": "\\u0007",
            "\u{08}": "\\u0008",
            "\u{09}": "\\u0009",
            "\u{0A}": "\\u000A",
            "\u{0B}": "\\u000B",
            "\u{0C}": "\\u000C",
            "\u{0D}": "\\u000D",
            "\u{0E}": "\\u000E",
            "\u{0F}": "\\u000F",
            "\u{10}": "\\u0010",
            "\u{11}": "\\u0011",
            "\u{12}": "\\u0012",
            "\u{13}": "\\u0013",
            "\u{14}": "\\u0014",
            "\u{15}": "\\u0015",
            "\u{16}": "\\u0016",
            "\u{17}": "\\u0017",
            "\u{18}": "\\u0018",
            "\u{19}": "\\u0019",
            "\u{1A}": "\\u001A",
            "\u{1B}": "\\u001B",
            "\u{1C}": "\\u001C",
            "\u{1D}": "\\u001D",
            "\u{1E}": "\\u001E",
            "\u{1F}": "\\u001F",
            "\\": "\\u005C",
            "'": "\\u0027",
            "\"": "\\u0022",
            ">": "\\u003E",
            "<": "\\u003C",
            "&": "\\u0026",
            "=": "\\u003D",
            "-": "\\u002D",
            ";": "\\u003B",
            "\u{2028}": "\\u2028",
            "\u{2029}": "\\u2029",
            // Required to pass GRMustache suite test "`javascript.escape` escapes control characters"
            "\r\n": "\\u000D\\u000A",
        ]
        var escaped = ""
        for c in string {
            if let escapedString = escapeTable[c] {
                escaped += escapedString
            } else {
                escaped.append(c)
            }
        }
        return escaped
    }
}
