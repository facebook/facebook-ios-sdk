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

import UIKit

@objcMembers
public class ViewControllerSpy: UIViewController {

  public var capturedDismissCompletion: (() -> Void)?
  public var dismissWasCalled = false
  public var capturedPresentViewController: UIViewController?
  public var capturedPresentViewControllerAnimated = false
  public var capturedPresentViewControllerCompletion: (() -> Void)?

  /// Used for providing a value to return for the readonly `transitionCoordinator` property
  public var stubbedTransitionCoordinator: UIViewControllerTransitionCoordinator? = nil

  // Overriding with no implementation to stub the property
  public override var transitionCoordinator: UIViewControllerTransitionCoordinator? {
    return stubbedTransitionCoordinator
  }

  private lazy var presenting = {
    ViewControllerSpy.makeDefaultSpy()
  }()

  public override var presentingViewController: UIViewController? {
    return presenting
  }

  public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    dismissWasCalled = true
    capturedDismissCompletion = completion
  }

  public static func makeDefaultSpy() -> ViewControllerSpy {
    return ViewControllerSpy()
  }

  // Overriding with no implementation to stub the method
  public override func present(
    _ viewControllerToPresent: UIViewController,
    animated: Bool,
    completion: (() -> Void)? = nil) {
    capturedPresentViewController = viewControllerToPresent
    capturedPresentViewControllerAnimated = animated
    capturedPresentViewControllerCompletion = completion
  }
}
