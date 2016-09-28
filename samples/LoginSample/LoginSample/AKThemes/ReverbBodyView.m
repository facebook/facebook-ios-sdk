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

#import "ReverbBodyView.h"

static const NSTimeInterval ReverbBodyImageRotationAnimationDuration = 2.0;
static NSString *const ReverbBodyViewImageRotationAnimationKey = @"ReverbBodyViewImageRotationAnimation";

@implementation ReverbBodyView
{
  UIImageView *_imageView;
  BOOL _shouldRotate;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithImage:(UIImage *)image shouldRotate:(BOOL)shouldRotate
{
  if ((self = [super initWithFrame:CGRectZero])) {
    _shouldRotate = shouldRotate;

    _imageView = [[UIImageView alloc] initWithImage:image];
    _imageView.backgroundColor = [UIColor clearColor];
    _imageView.opaque = NO;
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_imageView];

    [self addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
  }
  return self;
}

#pragma mark - Layout

- (CGSize)intrinsicContentSize
{
  return CGSizeMake(UIViewNoIntrinsicMetric, _imageView.image.size.height);
}

#pragma mark - Visibility

- (void)willMoveToWindow:(UIWindow *)newWindow
{
  [super willMoveToWindow:newWindow];

  if (_shouldRotate && (newWindow != nil)) {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.duration = ReverbBodyImageRotationAnimationDuration;
    animation.toValue = @(M_PI * 2);
    animation.repeatCount = MAXFLOAT;
    [_imageView.layer addAnimation:animation forKey:ReverbBodyViewImageRotationAnimationKey];
  }
}

- (void)didMoveToWindow
{
  [super didMoveToWindow];

  if (_shouldRotate && (self.window == nil)) {
    [_imageView.layer removeAnimationForKey:ReverbBodyViewImageRotationAnimationKey];
  }
}

@end
