/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKScreenTitleObserver.h"

#import <UIKit/UIKit.h>

#import "FBSDKSwizzler.h"
#import "UIViewController+FBSDKUserJourney.h"

static const NSInteger kMaxLargeContentTitleViewTraversals = 50;

@interface FBSDKScreenTitleObserver ()

@property (nonatomic) BOOL isObserving;
@property (nullable, nonatomic) IMP originalViewDidAppearImplementation;
@property (nullable, nonatomic, copy) NSString *screenTitle;

@end

@implementation FBSDKScreenTitleObserver

@synthesize screenTitle = _screenTitle;

+ (instancetype)shared
{
  static FBSDKScreenTitleObserver *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[self alloc] initPrivate];
  });
  return shared;
}

- (instancetype)initPrivate
{
  return [super init];
}

- (void)startObserving
{
  @synchronized(self) {
    if (self.isObserving) {
      return;
    }
    self.originalViewDidAppearImplementation =
    [FBSDKSwizzler swizzleMethodsOnSameClass:[UIViewController class]
                            originalSelector:@selector(viewDidAppear:)
                            swizzledSelector:@selector(fb_userJourneyViewDidAppear:)];
    self.isObserving = YES;
  }
}

- (void)stopObserving
{
  @synchronized(self) {
    if (!self.isObserving) {
      return;
    }
    // Exchanging the same two methods again restores their original implementations.
    [FBSDKSwizzler swizzleMethodsOnSameClass:[UIViewController class]
                            originalSelector:@selector(viewDidAppear:)
                            swizzledSelector:@selector(fb_userJourneyViewDidAppear:)];
    self.originalViewDidAppearImplementation = nil;
    self.isObserving = NO;
    _screenTitle = nil;
  }
}

- (void)setScreenTitle:(NSString *)screenTitle
{
  @synchronized(self) {
    _screenTitle = [screenTitle copy];
  }
}

- (NSString *)currentScreenTitle
{
  @synchronized(self) {
    return _screenTitle;
  }
}

+ (nullable NSString *)findLargeContentTitleInView:(nullable UIView *)rootView
{
  if (!rootView) {
    return nil;
  }
  if (@available(iOS 13.0, *)) {
    NSInteger traversals = 0;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:rootView];
    while (queue.count > 0 && traversals < kMaxLargeContentTitleViewTraversals) {
      UIView *view = queue.firstObject;
      [queue removeObjectAtIndex:0];
      traversals++;
      NSString *title = view.largeContentTitle;
      if (title.length > 0) {
        return title;
      }
      [queue addObjectsFromArray:view.subviews];
    }
  }
  return nil;
}

@end
