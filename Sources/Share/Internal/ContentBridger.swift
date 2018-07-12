// Copyright (c) 2016-present, Facebook, Inc. All rights reserved.
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

import FBSDKShareKit
import ObjectiveC.runtime

/**
 Represents content that is sharable with the Graph API. This protocol is internal only, as it is only needed for
 internal sharable types. If we ever have custom types which implement `Content`, then we need to re-investigate
 this architecture.
 */
internal protocol SDKBridgedContent {
  var sdkSharingContentRepresentation: FBSDKSharingContent { get }
}

internal enum ContentBridger {

  // Basic class wrapper for holding `Content`. This gets set as an associated object on the Objective-C
  // FBSDKSharingContent, so we can extract the swift content (which is probably a struct) back as its proper type.
  class SwiftContentHolder<C: ContentProtocol>: NSObject {
    let swiftContent: C

    init(swiftContent: C) {
      self.swiftContent = swiftContent
    }
  }

  // The only way for swift to guarantee a stable pointer is by using UnsafeMutablePointer.alloc. Using the `&`
  // operator, or using withUnsafePointer is liable to have a stack-copied pointer,
  // not a static pointer, which is what we need.
  private static let contentHolderKey: UnsafeMutablePointer<UInt8> = .allocate(capacity: 1)

  internal static func bridgeToObjC<C: ContentProtocol>(_ content: C) -> FBSDKSharingContent? {
    guard let nativeContent = content as? SDKBridgedContent else {
      return nil
    }

    let sdkRepresentation = nativeContent.sdkSharingContentRepresentation
    let contentHolder = SwiftContentHolder(swiftContent: content)
    objc_setAssociatedObject(sdkRepresentation, contentHolderKey, contentHolder, .OBJC_ASSOCIATION_RETAIN)

    return sdkRepresentation
  }

  internal static func bridgeToSwift<C: ContentProtocol>(_ content: FBSDKSharingContent) -> C? {
    let object = objc_getAssociatedObject(content, contentHolderKey)
    guard let contentHolder = object as? SwiftContentHolder<C> else {
      return nil
    }

    return contentHolder.swiftContent
  }
}
