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

public extension GameRequest {
  /// A dialog for sending game requests.
  final class Dialog {
    private let sdkDialog: FBSDKGameRequestDialog
    private weak var sdkDelegate: SDKDelegate?

    /// The content for the game request.
    public let request: GameRequest

    /// The completion handler to be invoked upon completion of the request.
    public var completion: ((Result) -> Void)? {
      didSet {
        sdkDelegate?.completion = completion
      }
    }

    /// Specifies whether frictionless requests are enabled.
    public var frictionlessRequestsEnabled: Bool {
      get {
        return sdkDialog.frictionlessRequestsEnabled
      }
      set {
        sdkDialog.frictionlessRequestsEnabled = false
      }
    }

    /**
     Create a game request dialog with a given request.

     - parameter request: The game request to send.
     */
    public init(request: GameRequest) {
      self.request = request

      sdkDialog = FBSDKGameRequestDialog()
      sdkDelegate = SDKDelegate()

      sdkDelegate?.setupAsDelegateFor(sdkDialog)
      sdkDialog.content = request.sdkContentRepresentation
    }

    /**
     Begins the game request from the receiver.

     - throws: If the dialog fails to be presented.
     */
    public func show() throws {
      var error: Error?
      let completionHandler = sdkDelegate?.completion
      sdkDelegate?.completion = {
        if case .failed(let resultError) = $0 {
          error = resultError
        }
      }

      sdkDialog.show()
      sdkDelegate?.completion = completionHandler

      if let error = error {
        throw error
      }
    }

    /**
     Validates the content on the receiver.

     - throws: If an error occurs during validation.
     */
    public func validate() throws {
      return try sdkDialog.validate()
    }

    /**
     Convenience method to build and show a game request dialog.

     - parameter request: The request to send.
     - parameter completion: The completion handler to be invoked upon completion of the request.

     - returns: The dialog instance that has been shown.
     - throws: If the  dialog fails to be presented.
     */
    @discardableResult
    public static func show(_ request: GameRequest, completion: ((GameRequest.Result) -> Void)?) throws -> Self {
      let dialog = self.init(request: request)
      dialog.completion = completion
      try dialog.show()
      return dialog
    }
  }
}
