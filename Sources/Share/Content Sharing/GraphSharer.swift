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
@testable import FacebookCore

/**
 A utility class for sharing through the graph API. Using this class requires an access token that
 has been granted the "publish_actions" permission.

 GraphSharer network requests are scheduled on the current run loop in the default run loop mode
 (like NSURLConnection). If you want to use GraphSharer in a background thread, you must manage the run loop
 yourself.
 */
public final class GraphSharer<Content: ContentProtocol> {

  fileprivate let sdkSharer: FBSDKShareAPI
  fileprivate let sdkShareDelegate: SDKSharingDelegateBridge<Content>

  /// The message the person has provided through the custom dialog that will accompany the share content.
  public var message: String? {
    get {
      return sdkSharer.message
    }
    set {
      sdkSharer.message = newValue
    }
  }

  /// The graph node to which content should be shared.
  public var graphNode: String? {
    get {
      return sdkSharer.graphNode
    }
    set {
      sdkSharer.graphNode = newValue
    }
  }

  /// The access token used when performing a share. The access token must have the "publish_actions" permission granted.
  public var accessToken: AccessToken? {
    get {
      let accessToken: FBSDKAccessToken? = sdkSharer.accessToken
      return accessToken.flatMap(AccessToken.init)
    }
    set {
      sdkSharer.accessToken = newValue.map { $0.sdkAccessTokenRepresentation }
    }
  }

  /**
   Create a new Graph API sharer.

   - parameter content:  The content to share.
   */
  public init(content: Content) {
    sdkSharer = FBSDKShareAPI()
    sdkShareDelegate = SDKSharingDelegateBridge()

    sdkShareDelegate.setupAsDelegateFor(sdkSharer)
    sdkSharer.shareContent = ContentBridger.bridgeToObjC(content)
  }
}

//--------------------------------------
// MARK: - Share
//--------------------------------------

extension GraphSharer {
  /**
   Attempt to share `content` with the graph API.

   - throws: If the content fails to share.
   */
  public func share() throws {
    var error: Error?
    let completionHandler = sdkShareDelegate.completion
    sdkShareDelegate.completion = {
      if case .failed(let resultError) = $0 {
        error = resultError
      }
    }

    sdkSharer.share()
    sdkShareDelegate.completion = completionHandler

    if let error = error {
      throw error
    }
  }
}


//--------------------------------------
// MARK: - ContentSharingProtocol
//--------------------------------------

extension GraphSharer: ContentSharingProtocol {

  /// The content that is being shared.
  public var content: Content {
    get {
      guard let swiftContent: Content = ContentBridger.bridgeToSwift(sdkSharer.shareContent) else {
        fatalError("Content of our private sharer has changed type. Something horrible has happened.")
      }
      return swiftContent
    }
  }

  /// The completion handler to be invoked upon the share performing.
  public var completion: ((ContentSharerResult<Content>) -> Void)? {
    get {
      return sdkShareDelegate.completion
    }
    set {
      sdkShareDelegate.completion = newValue
    }
  }

  /// Whether or not this sharer fails on invalid data.
  public var failsOnInvalidData: Bool {
    get {
      return sdkSharer.shouldFailOnDataError
    }
    set {
      sdkSharer.shouldFailOnDataError = newValue
    }
  }

  /**
   Validates the content on the receiver.
   - throws: If The content could not be validated.
   */
  public func validate() throws {
    try sdkSharer.validate()
  }
}

//--------------------------------------
// MARK: - Convenience
//--------------------------------------

extension GraphSharer {
  /**
   Share a given `content` to the Graph API, with a completion handler.

   - parameter content:    The content to share.
   - parameter completion: The completion handler to invoke.

   - returns: Whether or not the operation was successfully started.
   - throws: If the share fails.
   */
  @discardableResult
  public static func share(_ content: Content, completion: ((ContentSharerResult<Content>) -> Void)? = nil) throws -> GraphSharer {
    let sharer = self.init(content: content)
    sharer.completion = completion
    try sharer.share()
    return sharer
  }
}
