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

final class RenderingEngine {
    
    init(templateAST: TemplateAST, context: Context) {
        self.templateAST = templateAST
        self.baseContext = context
        buffer = ""
    }
    
    func render() throws -> Rendering {
        buffer = ""
        try renderTemplateAST(templateAST, inContext: baseContext)
        return Rendering(buffer, templateAST.contentType)
    }
    
    
    // MARK: - Rendering
    
    fileprivate let templateAST: TemplateAST
    fileprivate let baseContext: Context
    fileprivate var buffer: String

    fileprivate func renderTemplateAST(_ templateAST: TemplateAST, inContext context: Context) throws {
        // We must take care of eventual content-type mismatch between the
        // currently rendered AST (defined by init), and the argument.
        //
        // For example, the partial loaded by the HTML template `{{>partial}}`
        // may be a text one. In this case, we must render the partial as text,
        // and then HTML-encode its rendering. See the "Partial containing
        // CONTENT_TYPE:TEXT pragma is HTML-escaped when embedded." test in
        // the text_rendering.json test suite.
        //
        // So let's check for a content-type mismatch:
        
        let targetContentType = self.templateAST.contentType!
        if templateAST.contentType == targetContentType
        {
            // Content-type match
            
            for node in templateAST.nodes {
                try renderNode(node, inContext: context)
            }
        }
        else
        {
            // Content-type mismatch
            //
            // Render separately, so that we can HTML-escape the rendering of
            // the templateAST before appending to our buffer.
            let renderingEngine = RenderingEngine(templateAST: templateAST, context: context)
            let rendering = try renderingEngine.render()
            switch (targetContentType, rendering.contentType) {
            case (.html, .text):
                buffer.append(escapeHTML(rendering.string))
            default:
                buffer.append(rendering.string)
            }
        }
    }
    
    fileprivate func renderNode(_ node: TemplateASTNode, inContext context: Context) throws {
        switch node {
        case .blockNode(let block):
            // {{$ name }}...{{/ name }}
            //
            // Render the inner content of the resolved block.
            let resolvedBlock = resolveBlock(block, inContext: context)
            return try renderTemplateAST(resolvedBlock.innerTemplateAST, inContext: context)
            
        case .partialOverrideNode(let partialOverride):
            // {{< name }}...{{/ name }}
            //
            // Extend the inheritance stack, and render the content of the parent partial
            let context = context.extendedContext(partialOverride: partialOverride)
            return try renderTemplateAST(partialOverride.parentPartial.templateAST, inContext: context)
            
        case .partialNode(let partial):
            // {{> name }}
            //
            // Render the content of the partial
            return try renderTemplateAST(partial.templateAST, inContext: context)
            
        case .sectionNode(let section):
            // {{# name }}...{{/ name }}
            // {{^ name }}...{{/ name }}
            //
            // We have common rendering for sections and variable tags, yet with
            // a few specific flags:
            return try renderTag(section.tag, escapesHTML: true, inverted: section.inverted, expression: section.expression, inContext: context)
            
        case .textNode(let text):
            // text is the trivial case:
            buffer.append(text)
            
        case .variableNode(let variable):
            // {{ name }}
            // {{{ name }}}
            // {{& name }}
            //
            // We have common rendering for sections and variable tags, yet with
            // a few specific flags:
            return try renderTag(variable.tag, escapesHTML: variable.escapesHTML, inverted: false, expression: variable.expression, inContext: context)
        }
    }
    
    fileprivate func renderTag(_ tag: LocatedTag, escapesHTML: Bool, inverted: Bool, expression: Expression, inContext context: Context) throws {
        
        // 1. Evaluate expression
        
        var box: MustacheBox

        do {
            box = try ExpressionInvocation(expression: expression).invokeWithContext(context)
        } catch let error as MustacheError {
            let newMessage: String
            if let oldMessage = error.message {
                newMessage = "Could not evaluate \(tag): \(oldMessage)"
            } else {
                newMessage = "Could not evaluate \(tag)"
            }
            throw error.errorWith(message: newMessage, templateID: tag.templateID, lineNumber: tag.lineNumber)
        } catch {
            throw MustacheError(kind: .renderError, message: "Could not evaluate \(tag)", templateID: tag.templateID, lineNumber: tag.lineNumber, underlyingError: error)
        }
        
        
        // 2. Let willRender functions alter the box
        
        for willRender in context.willRenderStack {
            box = Box(willRender(tag, box))
        }
        
        
        // 3. Render the box
        
        let rendering: Rendering
        do {
            switch tag.type {
            case .variable:
                let info = RenderingInfo(tag: tag, context: context, enumerationItem: false)
                rendering = try box.render(info)
            case .section:
                switch (inverted, box.boolValue) {
                case (false, true):
                    // {{# true }}...{{/ true }}
                    // Only case where we trigger the RenderFunction of the Box
                    let info = RenderingInfo(tag: tag, context: context, enumerationItem: false)
                    rendering = try box.render(info)
                case (true, false):
                    // {{^ false }}...{{/ false }}
                    rendering = try tag.render(context)
                default:
                    // {{^ true }}...{{/ true }}
                    // {{# false }}...{{/ false }}
                    rendering = Rendering("")
                }
            }
        } catch {
            for didRender in context.didRenderStack {
                didRender(tag, box, nil)
            }
            // TODO? Inject location in error
            throw error
        }
        
        // 4. Extend buffer with the rendering, HTML-escaped if needed.
        
        let string: String
        switch (templateAST.contentType!, rendering.contentType, escapesHTML) {
        case (.html, .text, true):
            string = escapeHTML(rendering.string)
        default:
            string = rendering.string
        }
        buffer.append(string)
        
        
        // 5. Let didRender functions do their job
        
        for didRender in context.didRenderStack {
            didRender(tag, box, string)
        }
    }
    
    
    // MARK: - Template inheritance
    
    fileprivate func resolveBlock(_ block: TemplateASTNode.Block, inContext context: Context) -> TemplateASTNode.Block {
        // As we iterate partial overrides, block becomes the deepest overriden
        // block. context.partialOverrideStack has been built in
        // renderNode(node:inContext:).
        //
        // We also update an array of used parent template AST in order to
        // support nested partial overrides.
        var usedParentTemplateASTs: [TemplateAST] = []
        return context.partialOverrideStack.reduce(block) { (block, partialOverride) in
            // Don't apply already used partial
            //
            // Relevant test:
            // {
            //   "name": "com.github.mustachejava.ExtensionTest.testNested",
            //   "template": "{{<box}}{{$box_content}}{{<main}}{{$main_content}}{{<box}}{{$box_content}}{{<tweetbox}}{{$tweetbox_classes}}tweetbox-largetweetbox-user-styled{{/tweetbox_classes}}{{$tweetbox_attrs}}data-rich-text{{/tweetbox_attrs}}{{/tweetbox}}{{/box_content}}{{/box}}{{/main_content}}{{/main}}{{/box_content}}{{/box}}",
            //   "partials": {
            //     "box": "<box>{{$box_content}}{{/box_content}}</box>",
            //     "main": "<main>{{$main_content}}{{/main_content}}</main>",
            //     "tweetbox": "<tweetbox classes=\"{{$tweetbox_classes}}{{/tweetbox_classes}}\" attrs=\"{{$tweetbox_attrs}}{{/tweetbox_attrs}}\"></tweetbox>"
            //   },
            //   "expected": "<box><main><box><tweetbox classes=\"tweetbox-largetweetbox-user-styled\" attrs=\"data-rich-text\"></tweetbox></box></main></box>"
            // }
            
            let parentTemplateAST = partialOverride.parentPartial.templateAST
            if (usedParentTemplateASTs.contains { $0 === parentTemplateAST }) {
                return block
            } else {
                let (resolvedBlock, modified) = resolveBlock(block, inChildTemplateAST: partialOverride.childTemplateAST)
                if modified {
                    usedParentTemplateASTs.append(parentTemplateAST)
                }
                return resolvedBlock
            }
        }
    }
    
    // Looks for an override for the block argument in a TemplateAST.
    // Returns the resolvedBlock, and a boolean that tells whether the block was
    // actually overriden.
    fileprivate func resolveBlock(_ block: TemplateASTNode.Block, inChildTemplateAST childTemplateAST: TemplateAST) -> (TemplateASTNode.Block, Bool)
    {
        // As we iterate template AST nodes, block becomes the last inherited
        // block in the template AST.
        //
        // The boolean turns to true once the block has been actually overriden.
        return childTemplateAST.nodes.reduce((block, false)) { (step, node) in
            let (block, modified) = step
            switch node {
            case .blockNode(let resolvedBlock) where resolvedBlock.name == block.name:
                // {{$ name }}...{{/ name }}
                //
                // A block is overriden by another block with the same name.
                return (resolvedBlock, true)
                
            case .partialOverrideNode(let partialOverride):
                // {{< partial }}...{{/ partial }}
                //
                // Partial overrides have two opprtunities to override the
                // block: their parent partial, and their overriding blocks.
                //
                // Relevant tests:
                //
                // {
                //   "name": "Two levels of inheritance: parent partial with overriding content containing another parent partial",
                //   "data": { },
                //   "template": "{{<partial}}{{<partial2}}{{/partial2}}{{/partial}}",
                //   "partials": {
                //       "partial": "{{$block}}ignored{{/block}}",
                //       "partial2": "{{$block}}inherited{{/block}}" },
                //   "expected": "inherited"
                // },
                // {
                //   "name": "Two levels of inheritance: parent partial with overriding content containing another parent partial with overriding content containing a block",
                //   "data": { },
                //   "template": "{{<partial}}{{<partial2}}{{$block}}inherited{{/block}}{{/partial2}}{{/partial}}",
                //   "partials": {
                //       "partial": "{{$block}}ignored{{/block}}",
                //       "partial2": "{{$block}}ignored{{/block}}" },
                //   "expected": "inherited"
                // }
                
                let (resolvedBlock1, modified1) = resolveBlock(block, inChildTemplateAST: partialOverride.parentPartial.templateAST)
                let (resolvedBlock2, modified2) = resolveBlock(resolvedBlock1, inChildTemplateAST: partialOverride.childTemplateAST)
                return (resolvedBlock2, modified || modified1 || modified2)
                
            case .partialNode(let partial):
                // {{> partial }}
                //
                // Relevant test:
                //
                // {
                //   "name": "Partials in parent partials can override blocks",
                //   "data": { },
                //   "template": "{{<partial2}}{{>partial1}}{{/partial2}}",
                //   "partials": {
                //       "partial1": "{{$block}}partial1{{/block}}",
                //       "partial2": "{{$block}}ignored{{/block}}" },
                //   "expected": "partial1"
                // },
                let (resolvedBlock1, modified1) = resolveBlock(block, inChildTemplateAST: partial.templateAST)
                return (resolvedBlock1, modified || modified1)
                
            default:
                // Other nodes can't override the block.
                return (block, modified)
            }
        }
    }
}
