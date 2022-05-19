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

let ZipFilter = VariadicFilter { (boxes) in
    
    // Turn collection arguments into iterators. Iterators can be iterated
    // all together, and this is what we need.
    //
    // Other kinds of arguments generate an error.
    
    var zippedIterators: [AnyIterator<MustacheBox>] = []
    
    for box in boxes {
        if box.isEmpty {
            // Missing collection does not provide anything
        } else if let array = box.arrayValue {
            // Array
            zippedIterators.append(AnyIterator(array.makeIterator()))
        } else {
            // Error
            throw MustacheError(kind: .renderError, message: "Non-enumerable argument in zip filter: `\(box.value.map { String(reflecting: $0) } ?? "nil")`")
        }
    }
    
    
    // Build an array of custom render functions
    
    var renderFunctions: [RenderFunction] = []
    
    while true {
        
        // Extract from all iterators the boxes that should enter the rendering
        // context at each iteration.
        //
        // Given the [1,2,3], [a,b,c] input collections, those boxes would be
        // [1,a] then [2,b] and finally [3,c].
        
        var zippedBoxes: [MustacheBox] = []
        for iterator in zippedIterators {
            var iterator = iterator
            if let box = iterator.next() {
                zippedBoxes.append(box)
            }
        }
        
        
        // All iterators have been enumerated: stop
        
        if zippedBoxes.isEmpty {
            break;
        }
        
        
        // Build a render function which extends the rendering context with
        // zipped boxes before rendering the tag.
        
        let renderFunction: RenderFunction = { (info) -> Rendering in
            var context = zippedBoxes.reduce(info.context) { (context, box) in context.extendedContext(box) }
            return try info.tag.render(context)
        }
        
        renderFunctions.append(renderFunction)
    }
    
    return renderFunctions
}
