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

@testable import FBSDKGamingServicesKit

class TestSwitchContextDialog: SwitchContextDialogProtocol {

  // MARK: Test Evidence
  var wasDidCompleteWithResultsCalled = false
  var wasDidFailWithErrorCalled = false
  var wasDidCancelCalled = false
  var wasShowCalled = false
  var wasValidateCalled = false
  var wasCreateWebDialogCalled = false

  // MARK: Protocol Conformance
  var delegate: ContextDialogDelegate?
  var dialogContent: ValidatableProtocol?
  var currentWebDialog: WebDialog?

  func createWebDialogFrame(
    withWidth: CGFloat,
    height: CGFloat,
    windowFinder: WindowFinding
  ) -> CGRect {
    wasCreateWebDialogCalled = true

    return .zero
  }

  func webDialogDidCancel(_ webDialog: WebDialog) {
    wasDidCancelCalled = true
  }

  func webDialog(_ webDialog: WebDialog, didFailWithError error: Error) {
    wasDidFailWithErrorCalled = true
  }

  func webDialog(_ webDialog: WebDialog, didCompleteWithResults results: [String: Any]) {
    wasDidCompleteWithResultsCalled = true
  }

  func show() -> Bool {
    wasShowCalled = true

    return false
  }

  func validate() throws {
    wasValidateCalled = true
  }
}
