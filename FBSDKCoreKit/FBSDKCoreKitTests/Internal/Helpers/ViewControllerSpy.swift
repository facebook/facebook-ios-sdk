/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit

@objcMembers
class ViewControllerSpy: UIViewController {

  var capturedDismissCompletion: (() -> Void)?
  var dismissWasCalled = false
  var capturedPresentViewController: UIViewController?
  var capturedPresentViewControllerAnimated = false
  var capturedPresentViewControllerCompletion: (() -> Void)?

  /// Used for providing a value to return for the readonly `transitionCoordinator` property
  var stubbedTransitionCoordinator: UIViewControllerTransitionCoordinator?

  // Overriding with no implementation to stub the property
  override var transitionCoordinator: UIViewControllerTransitionCoordinator? {
    stubbedTransitionCoordinator
  }

  private lazy var presenting = {
    ViewControllerSpy.makeDefaultSpy()
  }()

  override var presentingViewController: UIViewController? {
    presenting
  }

  override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
    dismissWasCalled = true
    capturedDismissCompletion = completion
  }

  static func makeDefaultSpy() -> ViewControllerSpy {
    ViewControllerSpy()
  }

  // Overriding with no implementation to stub the method
  override func present(
    _ viewControllerToPresent: UIViewController,
    animated: Bool,
    completion: (() -> Void)? = nil
  ) {
    capturedPresentViewController = viewControllerToPresent
    capturedPresentViewControllerAnimated = animated
    capturedPresentViewControllerCompletion = completion
  }
}
