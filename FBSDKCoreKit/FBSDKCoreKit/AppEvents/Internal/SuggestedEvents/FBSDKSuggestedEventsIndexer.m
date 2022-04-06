/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKSuggestedEventsIndexer.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#import "FBSDKAppEvents+Internal.h"
#import "FBSDKAppEventsUtility.h"
#import "FBSDKFeatureExtracting.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKMLMacros.h"
#import "FBSDKModelUtility.h"
#import "FBSDKServerConfiguration.h"
#import "FBSDKViewHierarchy.h"
#import "FBSDKViewHierarchyMacros.h"

NSString *const OptInEvents = @"production_events";
NSString *const UnconfirmedEvents = @"eligible_for_prediction_events";

@interface FBSDKSuggestedEventsIndexer ()

@property (nonatomic, readonly) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, readonly) id<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) Class<FBSDKFeatureExtracting> featureExtractor;
@property (nonatomic, readonly) NSMutableSet<NSString *> *optInEvents;
@property (nonatomic, readonly) NSMutableSet<NSString *> *unconfirmedEvents;
@property (nonatomic, readonly, weak) id<FBSDKEventProcessing> eventProcessor;

@end

@implementation FBSDKSuggestedEventsIndexer

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                serverConfigurationProvider:(id<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                   swizzler:(Class<FBSDKSwizzling>)swizzler
                                   settings:(id<FBSDKSettings>)settings
                                eventLogger:(id<FBSDKEventLogging>)eventLogger
                           featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                             eventProcessor:(id<FBSDKEventProcessing>)eventProcessor
{
  if ((self = [super init])) {
    _optInEvents = [NSMutableSet set];
    _unconfirmedEvents = [NSMutableSet set];
    _graphRequestFactory = graphRequestFactory;
    _serverConfigurationProvider = serverConfigurationProvider;
    _swizzler = swizzler;
    _settings = settings;
    _eventLogger = eventLogger;
    _featureExtractor = featureExtractor;
    _eventProcessor = eventProcessor;
  }
  return self;
}

- (void)enable
{
  __weak typeof(self) weakSelf = self;
  [self.serverConfigurationProvider loadServerConfigurationWithCompletionBlock:^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
    if (error) {
      return;
    }

    NSDictionary<NSString *, id> *suggestedEventsSetting = serverConfiguration.suggestedEventsSetting;
    if ([suggestedEventsSetting isKindOfClass:NSNull.class] || !suggestedEventsSetting[OptInEvents] || !suggestedEventsSetting[UnconfirmedEvents]) {
      return;
    }

    [weakSelf.optInEvents addObjectsFromArray:suggestedEventsSetting[OptInEvents]];
    [weakSelf.unconfirmedEvents addObjectsFromArray:suggestedEventsSetting[UnconfirmedEvents]];

    [weakSelf setup];
  }];
}

static dispatch_once_t setupNonce;
- (void)setup
{
  // won't do the model prediction when there is no opt-in event and unconfirmed event
  if (_optInEvents.count == 0 && _unconfirmedEvents.count == 0) {
    return;
  }

  dispatch_once(&setupNonce, ^{
    // swizzle UIButton
    [self.swizzler swizzleSelector:@selector(didMoveToWindow)
                           onClass:UIControl.class
                         withBlock:^(UIControl *control) {
                           if (control.window && [control isKindOfClass:UIButton.class]) {
                             [((UIButton *)control) addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchDown];
                           }
                         }
                             named:@"suggested_events"];

    // UITableView
    void (^tableViewBlock)(UITableView *tableView,
                           SEL cmd,
                           id<UITableViewDelegate> delegate) =
    ^(UITableView *tableView, SEL cmd, id<UITableViewDelegate> delegate) {
      [self handleView:tableView withDelegate:delegate];
    };
    [self.swizzler swizzleSelector:@selector(setDelegate:)
                           onClass:UITableView.class
                         withBlock:tableViewBlock
                             named:@"suggested_events"];

    // UICollectionView
    void (^collectionViewBlock)(UICollectionView *collectionView,
                                SEL cmd,
                                id<UICollectionViewDelegate> delegate) =
    ^(UICollectionView *collectionView, SEL cmd, id<UICollectionViewDelegate> delegate) {
      [self handleView:collectionView withDelegate:delegate];
    };
    [self.swizzler swizzleSelector:@selector(setDelegate:)
                           onClass:UICollectionView.class
                         withBlock:collectionViewBlock
                             named:@"suggested_events"];

    fb_dispatch_on_main_thread(^{
      [self rematchBindings];
    });
  });
}

- (void)rematchBindings
{
  NSArray<__kindof UIWindow *> *windows = UIApplication.sharedApplication.windows;
  for (UIWindow *window in windows) {
    [self matchSubviewsIn:window];
  }
}

- (void)matchSubviewsIn:(UIView *)view
{
  if (!view) {
    return;
  }

  for (UIView *subview in view.subviews) {
    if ([subview isKindOfClass:UITableView.class]) {
      UITableView *tableView = (UITableView *)subview;
      [self handleView:tableView withDelegate:tableView.delegate];
    } else if ([subview isKindOfClass:UICollectionView.class]) {
      UICollectionView *collectionView = (UICollectionView *)subview;
      [self handleView:collectionView withDelegate:collectionView.delegate];
    } else if ([subview isKindOfClass:UIButton.class]) {
      [(UIButton *)subview addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchDown];
    }

    if (![subview isKindOfClass:UIControl.class]) {
      [self matchSubviewsIn:subview];
    }
  }
}

- (void)buttonClicked:(UIButton *)button
{
  [self predictEventWithUIResponder:button
                               text:[FBSDKViewHierarchy getText:button]];
}

- (void)handleView:(UIView *)view withDelegate:(id)delegate
{
  if (!delegate) {
    return;
  }

  if ([view isKindOfClass:UITableView.class]
      && [delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
    void (^block)(id, SEL, id, id) = ^(id target, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      [self predictEventWithUIResponder:cell
                                   text:[self getTextFromContentView:cell.contentView]];
    };
    [self.swizzler swizzleSelector:@selector(tableView:didSelectRowAtIndexPath:)
                           onClass:[delegate class]
                         withBlock:block
                             named:@"suggested_events"];
  } else if ([view isKindOfClass:UICollectionView.class]
             && [delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
    void (^block)(id, SEL, id, id) = ^(id target, SEL command, UICollectionView *collectionView, NSIndexPath *indexPath) {
      UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
      [self predictEventWithUIResponder:cell
                                   text:[self getTextFromContentView:cell.contentView]];
    };
    [self.swizzler swizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:)
                           onClass:[delegate class]
                         withBlock:block
                             named:@"suggested_events"];
  }
}

- (void)predictEventWithUIResponder:(UIResponder *)uiResponder text:(NSString *)text
{
  if (text.length > 100 || text.length == 0 || [FBSDKAppEventsUtility.shared isSensitiveUserData:text]) {
    return;
  }

  NSMutableArray<NSDictionary<NSString *, id> *> *trees = [NSMutableArray array];

  fb_dispatch_on_main_thread(^{
    NSMutableSet<NSObject *> *objAddressSet = [NSMutableSet set];
    NSArray<UIWindow *> *windows = UIApplication.sharedApplication.windows;
    for (UIWindow *window in windows) {
      NSDictionary<NSString *, id> *tree = [FBSDKViewHierarchy recursiveCaptureTreeWithCurrentNode:window
                                                                                        targetNode:uiResponder
                                                                                     objAddressSet:objAddressSet
                                                                                              hash:NO];
      if (tree) {
        if (window.isKeyWindow) {
          [trees insertObject:tree atIndex:0];
        } else {
          [FBSDKTypeUtility array:trees addObject:tree];
        }
      }
    }
    NSMutableDictionary<NSString *, id> *viewTree = [NSMutableDictionary dictionary];

    NSString *screenName = nil;
    UIViewController *topMostViewController = [FBSDKInternalUtility.sharedUtility topMostViewController];
    if (topMostViewController) {
      screenName = NSStringFromClass(topMostViewController.class);
    }

    [FBSDKTypeUtility dictionary:viewTree setObject:trees forKey:VIEW_HIERARCHY_VIEW_KEY];
    [FBSDKTypeUtility dictionary:viewTree setObject:screenName ?: @"" forKey:VIEW_HIERARCHY_SCREEN_NAME_KEY];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t predictAndLogBlock = ^{
      NSMutableDictionary<NSString *, id> *viewTreeCopy = viewTree.mutableCopy;
      float *denseData = [weakSelf.featureExtractor getDenseFeatures:viewTree];
      NSString *textFeature = [FBSDKModelUtility normalizedText:[weakSelf.featureExtractor getTextFeature:text withScreenName:viewTreeCopy[@"screenname"]]];
      NSString *event = [weakSelf.eventProcessor processSuggestedEvents:textFeature denseData:denseData];
      if (!event || [event isEqualToString:SUGGESTED_EVENT_OTHER]) {
        return;
      }
      if ([weakSelf.optInEvents containsObject:event]) {
        [weakSelf.eventLogger logEvent:event
                            parameters:@{@"_is_suggested_event" : @"1",
                                         @"_button_text" : text}];
      } else if ([weakSelf.unconfirmedEvents containsObject:event] && denseData) {
        // Only send back not confirmed events to advertisers
        [weakSelf logSuggestedEvent:event text:text denseFeature:[self getDenseFeaure:denseData] ?: @""];
      }
      free(denseData);
    };

  #if FBTEST
    predictAndLogBlock();
  #else
    fb_dispatch_on_default_thread(predictAndLogBlock);
  #endif
  });
}

- (NSString *)getDenseFeaure:(float *)denseData
{
  // Get dense feature string
  NSMutableArray<NSNumber *> *denseDataArray = [NSMutableArray array];
  for (int i = 0; i < 30; i++) {
    [FBSDKTypeUtility array:denseDataArray addObject:@(denseData[i])];
  }
  return [denseDataArray componentsJoinedByString:@","];
}

- (NSString *)getTextFromContentView:(UIView *)contentView
{
  NSMutableArray<NSString *> *textArray = [NSMutableArray array];
  for (UIView *subView in contentView.subviews) {
    NSString *label = [FBSDKViewHierarchy getText:subView];
    if (label.length > 0) {
      [FBSDKTypeUtility array:textArray addObject:label];
    }
  }
  return [textArray componentsJoinedByString:@" "];
}

- (void)logSuggestedEvent:(FBSDKAppEventName)event
                     text:(NSString *)text
             denseFeature:(NSString *)denseFeature
{
  if (!denseFeature) {
    return;
  }
  NSString *metadata = [FBSDKBasicUtility JSONStringForObject:@{@"button_text" : text,
                                                                @"dense" : denseFeature, }
                                                        error:nil
                                         invalidObjectHandler:nil];
  if (!metadata) {
    return;
  }

  id<FBSDKGraphRequest> request = [self.graphRequestFactory createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/suggested_events", [self.settings appID]]
                                                                                 parameters:@{
                                     @"event_name" : event,
                                     @"metadata" : metadata,
                                   }
                                                                                 HTTPMethod:FBSDKHTTPMethodPOST];
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}];
  return;
}

#pragma mark - Testability

#if FBTEST

+ (void)reset
{
  if (setupNonce) {
    setupNonce = 0;
  }
}

#endif

@end

#endif
