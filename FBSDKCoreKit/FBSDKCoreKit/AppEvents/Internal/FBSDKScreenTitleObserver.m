/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKScreenTitleObserver.h"

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <UIKit/UIKit.h>

#import "FBSDKSwizzler.h"
#import "UIViewController+FBSDKUserJourney.h"

static const NSInteger kMaxLargeContentTitleViewTraversals = 50;

@interface FBSDKScreenTitleObserver ()

@property (nullable, nonatomic) IMP originalViewDidAppearImplementation;
@property (nullable, nonatomic, copy) NSString *screenTitle;
@property (atomic) id<FBSDKSettings> settings;
@property (atomic) id<FBSDKFeatureChecking> featureChecker;

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
  if ((self = [super init])) {
    _settings = FBSDKSettings.sharedSettings;
    _featureChecker = FBSDKFeatureManager.shared;
  }
  return self;
}

// Both controls gate the screen title, at install, at capture and at read. Install gating keeps
// an app that never opts in from being swizzled at all; capture and read gating are what make a
// mid-session change take effect, since the swizzle is permanent and cannot be uninstalled.
- (BOOL)isCollectionPermitted
{
  return self.settings.isMetaDataCollectionEnabled
  && [self.featureChecker isEnabled:FBSDKFeatureUserJourney];
}

// The swizzle mutates the shared UIViewController method table, so it must happen on the main
// thread and exactly once for the process lifetime. Exchanging the implementations a second time
// would restore the originals and silently stop title capture.
- (void)startObserving
{
  fb_dispatch_on_main_thread(^{
    // Outside dispatch_once so a gate being off does not burn the token; a later opt-in can install.
    if (!self.isCollectionPermitted) {
      return;
    }
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
  // Store nil rather than returning early, so a title captured before either gate closed is
  // erased rather than frozen — the swizzle keeps firing once installed.
  NSString *title = self.isCollectionPermitted ? screenTitle : nil;
  @synchronized(self) {
    _screenTitle = [title copy];
  }
}

- (NSString *)currentScreenTitle
{
  if (!self.isCollectionPermitted) {
    return nil;
  }
  @synchronized(self) {
    return _screenTitle;
  }
}

+ (nullable NSString *)findLargeContentTitleInView:(nullable UIView *)rootView
{
  if (!rootView) {
    return nil;
  }
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
  return nil;
}

@end
