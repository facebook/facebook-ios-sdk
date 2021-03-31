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

import FBSDKCoreKit
import XCTest

class WebDialogViewTests: XCTestCase {

  var dialog: FBWebDialogView! // swiftlint:disable:this implicitly_unwrapped_optional
  var webView = TestWebView()
  var factory = TestWebViewFactory()
  let frame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))

  override func setUp() {
    super.setUp()

    webView = factory.webView
    FBWebDialogView.configure(withWebViewProvider: factory)
    dialog = FBWebDialogView(frame: frame)
  }

  func testCreatingWithDefaultWebView() {
    FBWebDialogView.reset()
    let dialog = FBWebDialogView(frame: .zero)

    XCTAssertNil(
      dialog.webView,
      "Should not have a webview by default"
    )
  }

  func testRequestsWebView() {
    XCTAssertEqual(
      factory.capturedFrame,
      .zero,
      "Should request a webview with a frame of zero"
    )
  }

  func testSetsWebViewAsSubview() {
    XCTAssertNotNil(
      dialog.subviews.first as? TestWebView,
      "Should add the webview from the factory as a subview"
    )
  }

  func testSetsSelfAsNavigationDelegate() {
    guard let delegate = webView.navigationDelegate
    else {
      return XCTFail("Should add a child webview on creation")
    }
    XCTAssertEqual(
      ObjectIdentifier(delegate),
      ObjectIdentifier(dialog),
      "Should set the dialog as the webview's navigation delegate"
    )
  }

  func testActivityIndicatorDefaultState() {
    XCTAssertTrue(
      activityIndicatorView.hidesWhenStopped,
      "The activity indicator view should hide when stopped"
    )
    XCTAssertFalse(
      activityIndicatorView.isAnimating,
      "The activity indicator view should not animate by default"
    )
  }

  func testLoadingURL() {
    dialog.load(SampleUrls.valid)

    XCTAssertEqual(
      webView.capturedRequest,
      URLRequest(url: SampleUrls.valid),
      "Should attempt to load the request in the webview"
    )
    XCTAssertTrue(
      activityIndicatorView.isAnimating,
      "Should start animating the activity indicator during loading"
    )
  }

  func testStopLoadingURL() {
    dialog.load(SampleUrls.valid)
    dialog.stopLoading()

    XCTAssertEqual(
      webView.stopLoadingCallCount,
      1,
      "Stopping the dialog view should stop loading the request in the webview"
    )
    XCTAssertFalse(
      activityIndicatorView.isAnimating,
      "Should stop animating the activity indicator when loading stops"
    )
  }

  func testLayingOutSubviewsWithoutEnoughSpace() {
    dialog.bounds = CGRect(origin: .zero, size: .zero)
    dialog.draw(.zero)
    dialog.layoutSubviews()

    XCTAssertEqual(
      dialog.frame,
      .init(x: 5, y: 5, width: 0, height: 0),
      "Should set the expected frame when layout out subviews"
    )
  }

  func testLayingOutSubviewsWithEnoughSpace() {
    dialog.bounds = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
    dialog.draw(.zero)
    dialog.layoutSubviews()

    XCTAssertEqual(
      dialog.frame,
      .init(x: -20, y: -20, width: 50, height: 50),
      "Should set the expected frame when layout out subviews"
    )
  }

  // MARK: - Helpers

  var activityIndicatorView: UIActivityIndicatorView {
    guard let loadingIndicator = webView.subviews.first as? UIActivityIndicatorView else {
      fatalError("Should provide an activity indicator view during setup")
    }
    return loadingIndicator
  }

}
