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

let EachFilter = Filter { (box: MustacheBox) -> Any? in
    
    // {{# each(nothing) }}...{{/ }}
    if box.isEmpty {
        return box
    }
    
    // {{# each(dictionary) }}...{{/ }}
    //
    //     // Renders "firstName: Charles, lastName: Bronson."
    //     let dictionary = ["firstName": "Charles", "lastName": "Bronson"]
    //     let template = try! Template(string: "{{# each(dictionary) }}{{ @key }}: {{ . }}{{^ @last }}, {{/ @last }}{{/ each(dictionary) }}.")
    //     template.register(StandardLibrary.each, forKey: "each")
    //     try! template.render(["dictionary": dictionary])
    //
    // The dictionaryValue box property makes sure to return a
    // [String: MustacheBox] whatever the boxed dictionary-like value
    // (NSDictionary, [String: Int], [String: CustomObject], etc.
    if let dictionary = box.dictionaryValue {
        let count = dictionary.count
        let customRenderFunctions = dictionary.enumerated().map { (index: Int, element: (key: String, box: MustacheBox)) -> Any? in
            let customRenderFunction: RenderFunction = { info in
                // Push positional keys in the context stack and then perform
                // a regular rendering.
                var position: [String: Any] = [:]
                position["@index"] = index
                position["@indexPlusOne"] = index + 1
                position["@indexIsEven"] = (index % 2 == 0)
                position["@first"] = (index == 0)
                position["@last"] = ((index == count - 1))
                position["@key"] = element.key
                
                var info = info
                info.context = info.context.extendedContext(position)
                return try element.box.render(info)
            }
            return customRenderFunction
        }
        return customRenderFunctions
    }
    
    
    // {{# each(array) }}...{{/ }}
    //
    //     // Renders "1: bread, 2: ham, 3: butter"
    //     let array = ["bread", "ham", "butter"]
    //     let template = try! Template(string: "{{# each(array) }}{{ @indexPlusOne }}: {{ . }}{{^ @last }}, {{/ @last }}{{/ each(array) }}.")
    //     template.register(StandardLibrary.each, forKey: "each")
    //     try! template.render(["array": array])
    //
    // The arrayValue box property makes sure to return a [MustacheBox] whatever
    // the boxed collection: NSArray, NSSet, [String], [CustomObject], etc.
    if let boxes = box.arrayValue {
        let count = boxes.count
        let customRenderFunctions = boxes.enumerated().map { (index: Int, box: MustacheBox) -> Any? in
            let customRenderFunction: RenderFunction = { info in
                // Push positional keys in the context stack and then perform
                // a regular rendering.
                var position: [String: Any] = [:]
                position["@index"] = index
                position["@indexPlusOne"] = index + 1
                position["@indexIsEven"] = (index % 2 == 0)
                position["@first"] = (index == 0)
                position["@last"] = ((index == count - 1))
                
                var info = info
                info.context = info.context.extendedContext(position)
                return try box.render(info)
            }
            return customRenderFunction
        }
        return customRenderFunctions
    }
    
    // Non-iterable value
    throw MustacheError(kind: .renderError, message: "Non-enumerable argument in each filter: \(box.value.map { String(reflecting: $0) } ?? "nil")")
}
