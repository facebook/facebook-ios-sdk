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
  }
  return self;
}

- (BOOL)isMetaDataCollectionEnabled
{
  return self.settings.isMetaDataCollectionEnabled;
}

// The swizzle mutates the shared UIViewController method table, so it must happen on the main
// thread and exactly once for the process lifetime. Exchanging the implementations a second time
// would restore the originals and silently stop title capture.
- (void)startObserving
{
  fb_dispatch_on_main_thread(^{
    // Outside dispatch_once so opting out does not burn the token; a later opt-in can install.
    if (!self.isMetaDataCollectionEnabled) {
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
  // Store nil rather than returning early, so a title captured before the opt-out is erased.
  NSString *title = self.isMetaDataCollectionEnabled ? screenTitle : nil;
  @synchronized(self) {
    _screenTitle = [title copy];
  }
}

- (NSString *)currentScreenTitle
{
  if (!self.isMetaDataCollectionEnabled) {
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
