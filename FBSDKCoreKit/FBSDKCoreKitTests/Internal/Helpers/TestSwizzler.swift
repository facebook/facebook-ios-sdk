// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

struct SwizzleEvidence: Equatable {
  let selector: Selector
  let `class`: AnyClass

  init(
    selector: Selector,
    `class`: AnyClass
  ) {
    self.selector = selector
    self.`class` = `class`
  }

  static func == (lhs: SwizzleEvidence, rhs: SwizzleEvidence) -> Bool {
    lhs.selector == rhs.selector && lhs.class == rhs.class
  }
}

@objcMembers
class TestSwizzler: NSObject, Swizzling {
  static var evidence = [SwizzleEvidence]()

  static func swizzleSelector(
    _ aSelector: Selector,
    on aClass: AnyClass,
    with block: @escaping swizzleBlock,
    named aName: String
  ) {
    evidence.append(.init(selector: aSelector, class: aClass))
  }

  static func reset() {
    evidence = []
  }
}
