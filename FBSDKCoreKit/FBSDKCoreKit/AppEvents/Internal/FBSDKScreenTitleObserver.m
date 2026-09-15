/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKScreenTitleObserver.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <UIKit/UIKit.h>

#import "FBSDKSwizzler.h"
#import "UIViewController+FBSDKUserJourney.h"

static const NSInteger kMaxLargeContentTitleViewTraversals = 50;

@interface FBSDKScreenTitleObserver ()

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

// The swizzle mutates the shared UIViewController method table, so it must happen on the main
// thread and exactly once for the process lifetime. Exchanging the implementations a second time
// would restore the originals and silently stop title capture.
- (void)startObserving
{
  fb_dispatch_on_main_thread(^{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      self.originalViewDidAppearImplementation =
      [FBSDKSwizzler swizzleMethodsOnSameClass:[UIViewController class]
                              originalSelector:@selector(viewDidAppear:)
                              swizzledSelector:@selector(fb_userJourneyViewDidAppear:)];
    });
  });
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
