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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKSuggestedEventsIndexer.h"

 #import <UIKit/UIKit.h>

 #import <objc/runtime.h>
 #import <sys/sysctl.h>
 #import <sys/utsname.h>

 #import "FBSDKAppEvents.h"
 #import "FBSDKAppEvents+EventLogging.h"
 #import "FBSDKAppEventsUtility.h"
 #import "FBSDKCoreKitBasicsImport.h"
 #import "FBSDKEventProcessing.h"
 #import "FBSDKFeatureExtracting.h"
 #import "FBSDKFeatureExtractor.h"
 #import "FBSDKGraphRequestFactory.h"
 #import "FBSDKInternalUtility.h"
 #import "FBSDKMLMacros.h"
 #import "FBSDKModelManager.h"
 #import "FBSDKModelUtility.h"
 #import "FBSDKServerConfigurationManager+ServerConfigurationProviding.h"
 #import "FBSDKSettings+Internal.h"
 #import "FBSDKSettings+SettingsProtocols.h"
 #import "FBSDKSwizzler+Swizzling.h"
 #import "FBSDKSwizzling.h"
 #import "FBSDKViewHierarchy.h"
 #import "FBSDKViewHierarchyMacros.h"

NSString *const OptInEvents = @"production_events";
NSString *const UnconfirmedEvents = @"eligible_for_prediction_events";

@interface FBSDKSuggestedEventsIndexer ()

@property (nonatomic, readonly) id<FBSDKGraphRequestProviding> requestProvider;
@property (nonatomic, readonly) Class<FBSDKServerConfigurationProviding> serverConfigurationProvider;
@property (nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonatomic, readonly) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, readonly) Class<FBSDKFeatureExtracting> featureExtractor;
@property (nonatomic, readonly) NSMutableSet<NSString *> *optInEvents;
@property (nonatomic, readonly) NSMutableSet<NSString *> *unconfirmedEvents;
@property (nonatomic, readonly, weak) id<FBSDKEventProcessing> eventProcessor;

@end

@implementation FBSDKSuggestedEventsIndexer

- (instancetype)init
{
  return [self initWithGraphRequestProvider:[FBSDKGraphRequestFactory new]
                serverConfigurationProvider:FBSDKServerConfigurationManager.class
                                   swizzler:FBSDKSwizzler.class
                                   settings:FBSDKSettings.sharedSettings
                                eventLogger:FBSDKAppEvents.singleton
                           featureExtractor:FBSDKFeatureExtractor.class
                             eventProcessor:FBSDKModelManager.shared];
}

- (instancetype)initWithGraphRequestProvider:(id<FBSDKGraphRequestProviding>)requestProvider
                 serverConfigurationProvider:(Class<FBSDKServerConfigurationProviding>)serverConfigurationProvider
                                    swizzler:(Class<FBSDKSwizzling>)swizzler
                                    settings:(id<FBSDKSettings>)settings
                                 eventLogger:(id<FBSDKEventLogging>)eventLogger
                            featureExtractor:(Class<FBSDKFeatureExtracting>)featureExtractor
                              eventProcessor:(id<FBSDKEventProcessing>)eventProcessor
{
  if ((self = [super init])) {
    _optInEvents = [NSMutableSet set];
    _unconfirmedEvents = [NSMutableSet set];
    _requestProvider = requestProvider;
    _serverConfigurationProvider = serverConfigurationProvider;
    _swizzler = swizzler;
    _settings = settings;
    _eventLogger = eventLogger;
    _featureExtractor = featureExtractor;
    _eventProcessor = eventProcessor;
  }
  return self;
}

// Transitional singleton introduced as a way to change the usage semantics
// from a type-based interface to an instance-based interface.
+ (instancetype)shared
{
  static dispatch_once_t nonce;
  static id instance;
  dispatch_once(&nonce, ^{
    instance = [self new];
  });
  return instance;
}

- (void)enable
{
  __weak typeof(self) weakSelf = self;
  [self.serverConfigurationProvider loadServerConfigurationWithCompletionBlock:^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
    if (error) {
      return;
    }

    NSDictionary<NSString *, id> *suggestedEventsSetting = serverConfiguration.suggestedEventsSetting;
    if ([suggestedEventsSetting isKindOfClass:[NSNull class]] || !suggestedEventsSetting[OptInEvents] || !suggestedEventsSetting[UnconfirmedEvents]) {
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
                           onClass:[UIControl class]
                         withBlock:^(UIControl *control) {
                           if (control.window && [control isKindOfClass:[UIButton class]]) {
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
                           onClass:[UITableView class]
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
                           onClass:[UICollectionView class]
                         withBlock:collectionViewBlock
                             named:@"suggested_events"];

    fb_dispatch_on_main_thread(^{
      [self rematchBindings];
    });
  });
}

- (void)rematchBindings
{
  NSArray *windows = [UIApplication sharedApplication].windows;
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
    if ([subview isKindOfClass:[UITableView class]]) {
      UITableView *tableView = (UITableView *)subview;
      [self handleView:tableView withDelegate:tableView.delegate];
    } else if ([subview isKindOfClass:[UICollectionView class]]) {
      UICollectionView *collectionView = (UICollectionView *)subview;
      [self handleView:collectionView withDelegate:collectionView.delegate];
    } else if ([subview isKindOfClass:[UIButton class]]) {
      [(UIButton *)subview addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchDown];
    }

    if (![subview isKindOfClass:[UIControl class]]) {
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

  if ([view isKindOfClass:[UITableView class]]
      && [delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
    void (^block)(id, SEL, id, id) = ^(id target, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
      UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
      [self predictEventWithUIResponder:cell
                                   text:[self getTextFromContentView:[cell contentView]]];
    };
    [self.swizzler swizzleSelector:@selector(tableView:didSelectRowAtIndexPath:)
                           onClass:[delegate class]
                         withBlock:block
                             named:@"suggested_events"];
  } else if ([view isKindOfClass:[UICollectionView class]]
             && [delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)]) {
    void (^block)(id, SEL, id, id) = ^(id target, SEL command, UICollectionView *collectionView, NSIndexPath *indexPath) {
      UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
      [self predictEventWithUIResponder:cell
                                   text:[self getTextFromContentView:[cell contentView]]];
    };
    [self.swizzler swizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:)
                           onClass:[delegate class]
                         withBlock:block
                             named:@"suggested_events"];
  }
}

- (void)predictEventWithUIResponder:(UIResponder *)uiResponder text:(NSString *)text
{
  if (text.length > 100 || text.length == 0 || [FBSDKAppEventsUtility isSensitiveUserData:text]) {
    return;
  }

  NSMutableArray<NSDictionary<NSString *, id> *> *trees = [NSMutableArray array];

  fb_dispatch_on_main_thread(^{
    NSMutableSet<NSObject *> *objAddressSet = [NSMutableSet set];
    NSArray<UIWindow *> *windows = [UIApplication sharedApplication].windows;
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
    UIViewController *topMostViewController = [FBSDKInternalUtility topMostViewController];
    if (topMostViewController) {
      screenName = NSStringFromClass([topMostViewController class]);
    }

    [FBSDKTypeUtility dictionary:viewTree setObject:trees forKey:VIEW_HIERARCHY_VIEW_KEY];
    [FBSDKTypeUtility dictionary:viewTree setObject:screenName ?: @"" forKey:VIEW_HIERARCHY_SCREEN_NAME_KEY];

    __weak typeof(self) weakSelf = self;
    dispatch_block_t predictAndLogBlock = ^{
      NSMutableDictionary<NSString *, id> *viewTreeCopy = [viewTree mutableCopy];
      float *denseData = [weakSelf.featureExtractor getDenseFeatures:viewTree];
      NSString *textFeature = [FBSDKModelUtility normalizedText:[FBSDKFeatureExtractor getTextFeature:text withScreenName:viewTreeCopy[@"screenname"]]];
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

  #ifdef FBSDKTEST
    predictAndLogBlock();
  #else
    fb_dispatch_on_default_thread(predictAndLogBlock);
  #endif
  });
}

 #pragma mark - Helper Methods

- (NSString *)getDenseFeaure:(float *)denseData
{
  // Get dense feature string
  NSMutableArray *denseDataArray = [NSMutableArray array];
  for (int i = 0; i < 30; i++) {
    [FBSDKTypeUtility array:denseDataArray addObject:[NSNumber numberWithFloat:denseData[i]]];
  }
  return [denseDataArray componentsJoinedByString:@","];
}

- (NSString *)getTextFromContentView:(UIView *)contentView
{
  NSMutableArray<NSString *> *textArray = [NSMutableArray array];
  for (UIView *subView in [contentView subviews]) {
    NSString *label = [FBSDKViewHierarchy getText:subView];
    if (label.length > 0) {
      [FBSDKTypeUtility array:textArray addObject:label];
    }
  }
  return [textArray componentsJoinedByString:@" "];
}

- (void)logSuggestedEvent:(NSString *)event
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

  id<FBSDKGraphRequest> request = [self.requestProvider createGraphRequestWithGraphPath:[NSString stringWithFormat:@"%@/suggested_events", [self.settings appID]]
                                                                             parameters:@{
                                     @"event_name" : event,
                                     @"metadata" : metadata,
                                   }
                                                                             HTTPMethod:FBSDKHTTPMethodPOST];
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}];
  return;
}

 #pragma mark - Testability

 #ifdef FBSDKTEST

+ (void)reset
{
  if (setupNonce) {
    setupNonce = 0;
  }
}

 #endif

@end

#endif
