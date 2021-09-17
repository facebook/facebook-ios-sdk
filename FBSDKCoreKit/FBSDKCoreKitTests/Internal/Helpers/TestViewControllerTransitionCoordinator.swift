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
class TestViewControllerTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {
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

  // swiftlint:disable:next identifier_name
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
class TestViewControllerTransitionCoordinatorContext: NSObject, // swiftlint:disable:this type_name
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
