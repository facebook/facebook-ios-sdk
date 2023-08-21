/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import UIKit

@objcMembers
final class TestViewControllerTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
  var isAnimated = false
  var presentationStyle = UIModalPresentationStyle.none
  var initiallyInteractive = false
  var isInterruptible = false
  var isInteractive = false
  var isCancelled = false
  var transitionDuration: TimeInterval = 0
  var percentComplete: CGFloat = 0
  var completionVelocity: CGFloat = 0
  var completionCurve = UIView.AnimationCurve.easeInOut
  var containerView: UIView = TestView()
  var targetTransform = CGAffineTransform.identity

  func animate(
    alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
    completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
  ) -> Bool {
    capturedAnimateAlongsideTransitionCompletion = completion

    return true
  }

  var capturedAnimateAlongsideTransitionCompletion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?

  func animateAlongsideTransition(
    in view: UIView?,
    animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
    completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)? = nil
  ) -> Bool {
    true
  }

  func notifyWhenInteractionEnds(
    _ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void
  ) {}

  func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {}

  func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
    nil
  }

  func view(forKey key: UITransitionContextViewKey) -> UIView? {
    nil
  }
}

@objcMembers
final class TestViewControllerTransitionCoordinatorContext: NSObject, // swiftlint:disable:this type_name
UIViewControllerTransitionCoordinatorContext {
  var isAnimated = false
  var presentationStyle = UIModalPresentationStyle.fullScreen
  var initiallyInteractive = false
  var isInterruptible = false
  var isInteractive = false
  var isCancelled = false
  var transitionDuration: TimeInterval = 0
  var percentComplete: CGFloat = 0
  var completionVelocity: CGFloat = 0
  var completionCurve = UIView.AnimationCurve.easeInOut
  var containerView: UIView = TestView()
  var targetTransform = CGAffineTransform.identity

  func viewController(
    forKey key: UITransitionContextViewControllerKey
  ) -> UIViewController? {
    nil
  }

  func view(
    forKey key: UITransitionContextViewKey
  ) -> UIView? {
    nil
  }
}
