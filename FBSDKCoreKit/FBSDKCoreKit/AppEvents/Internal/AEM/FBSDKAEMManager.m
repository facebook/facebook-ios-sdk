/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKAEMManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>

#import <UIKit/UIKit.h>

#import "FBSDKAppEventName+Internal.h"

@interface FBSDKAEMManager ()

@property (nullable, nonatomic) Class<FBSDKSwizzling> swizzler;
@property (nullable, nonatomic) Class<FBSDKAEMReporter> aemReporter;
@property (nullable, nonatomic) id<FBSDKEventLogging> eventLogger;
@property (nullable, nonatomic) id<FBSDKCrashHandler> crashHandler;
@property (nullable, nonatomic) id<FBSDKFeatureDisabling> featureChecker;
@property (nullable, nonatomic) id<FBSDKAppEventsUtility> appEventsUtility;

@end

static FBSDKAEMManager *_shared = nil;

@implementation FBSDKAEMManager

+ (FBSDKAEMManager *)shared
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shared = [self new];
  });
  return _shared;
}

- (void)configureWithSwizzler:(nonnull Class<FBSDKSwizzling>)swizzler
                  aemReporter:(nonnull Class<FBSDKAEMReporter>)aemReporter
                  eventLogger:(nonnull id<FBSDKEventLogging>)eventLogger
                 crashHandler:(nonnull id<FBSDKCrashHandler>)crashHandler
               featureChecker:(nonnull id<FBSDKFeatureDisabling>)featureChecker
             appEventsUtility:(nonnull id<FBSDKAppEventsUtility>)appEventsUtility
{
  self.swizzler = swizzler;
  self.aemReporter = aemReporter;
  self.eventLogger = eventLogger;
  self.crashHandler = crashHandler;
  self.featureChecker = featureChecker;
  self.appEventsUtility = appEventsUtility;
}

- (void)enableAutoSetup
{
  if (@available(iOS 14.0, *)) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      @try  {
        [self setup];
      } @catch (NSException *exception) {
        // Disable Auto Setup and log event if exception happens
        [self.featureChecker disableFeature:FBSDKFeatureAEMAutoSetup];
        [self.eventLogger logEvent:@"fb_mobile_auto_setup_exception" parameters:nil];
        fb_dispatch_on_default_thread(^{
          [self.crashHandler saveException:exception];
        });
      }
    });
  }
}

- (void)setup
{
  Class clazz = [[UIApplication sharedApplication] delegate].class;
  [self.swizzler swizzleSelector:@selector(application:openURL:options:) onClass:clazz withBlock:^(id delegate, SEL cmd, id application, NSURL *url, id options) {
    [self.aemReporter enable];
    [self.aemReporter handle:url];
    [self.appEventsUtility saveCampaignIDs:url];
    [self logAutoSetupStatus:YES source:@"appdelegate_dl"];
  } named:@"AEMDeeplinkAutoSetup"];
  
  
  [self.swizzler swizzleSelector:@selector(application:continueUserActivity:restorationHandler:) onClass:clazz withBlock:^(id delegate, SEL cmd, id application, NSUserActivity *userActivity, id restorationHandler) {
    [self.aemReporter enable];
    [self.aemReporter handle:userActivity.webpageURL];
    [self.appEventsUtility saveCampaignIDs:userActivity.webpageURL];
    [self logAutoSetupStatus:YES source:@"appdelegate_ul"];
  } named:@"AEMUniversallinkAutoSetup"];
  
  if (@available(iOS 13.0, *)) {
    NSSet<UIScene *> *scenes = [[UIApplication sharedApplication] connectedScenes];
    for (UIScene* thisScene in scenes) {
      Class sceneClass = thisScene.delegate.class;
      [self setupScene:sceneClass];
    }
    NSSet<NSString *> *sceneDelegates = [self getSceneDelegates];
    for (NSString *sceneDelegate in sceneDelegates) {
      [self setupScene:NSClassFromString(sceneDelegate)];
    }
  }
}

- (void)setupScene:(Class)sceneClass
{
  if (sceneClass == nil) {
    return;
  }
  if (@available(iOS 13.0, *)) {
    [self.swizzler swizzleSelector:@selector(scene:openURLContexts:) onClass:sceneClass withBlock:^(id sceneDelegate, SEL cmd, id scene, NSSet<UIOpenURLContext *> *urlContexts) {
      [self.aemReporter enable];
      for(UIOpenURLContext* urlContext in urlContexts) {
        [self.aemReporter handle:urlContext.URL];
        [self.appEventsUtility saveCampaignIDs:urlContext.URL];
      }
      [self logAutoSetupStatus:YES source:@"scenedelegate_dl"];
    } named:[NSString stringWithFormat:@"AEMSceneDeeplinkAutoSetup_%@", NSStringFromClass(sceneClass)]];
    
    [self.swizzler swizzleSelector:@selector(scene:continueUserActivity:) onClass:sceneClass withBlock:^(id sceneDelegate, SEL cmd, id scene, NSUserActivity *userActivity) {
      [self.aemReporter enable];
      [self.aemReporter handle:userActivity.webpageURL];
      [self.appEventsUtility saveCampaignIDs:userActivity.webpageURL];
      [self logAutoSetupStatus:YES source:@"scenedelegate_ul"];
    } named:[NSString stringWithFormat:@"AEMSceneUniversallinkAutoSetup_%@", NSStringFromClass(sceneClass)]];
    
    [self.swizzler swizzleSelector:@selector(scene:willConnectToSession:options:) onClass:sceneClass withBlock:^(id sceneDelegate, SEL cmd, id scene, UISceneSession *session, UISceneConnectionOptions *options) {
      [self.aemReporter enable];
      for(UIOpenURLContext* urlContext in options.URLContexts) {
        [self.aemReporter handle:urlContext.URL];
        [self.appEventsUtility saveCampaignIDs:urlContext.URL];
      }
      [self logAutoSetupStatus:YES source:@"scenedelegate_coldstart"];
    } named:[NSString stringWithFormat:@"AEMSceneColdStartAutoSetup_%@", NSStringFromClass(sceneClass)]];
  }
}

- (NSSet<NSString *> *)getSceneDelegates
{
  NSMutableSet<NSString *> *delegates = [NSMutableSet new];
  NSDictionary<NSString *, id> *sceneManifest = [FBSDKTypeUtility dictionaryValue:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIApplicationSceneManifest"]];
  NSDictionary<NSString *, id> *sceneConfigs = [FBSDKTypeUtility dictionaryValue:sceneManifest[@"UISceneConfigurations"]];
  NSArray<id> *sceneSessionRoleApplicaiton = [FBSDKTypeUtility arrayValue:sceneConfigs[@"UIWindowSceneSessionRoleApplication"]];
  for (id sceneSessionRole in sceneSessionRoleApplicaiton) {
    NSDictionary<NSString *, id> *item = [FBSDKTypeUtility dictionaryValue:sceneSessionRole];
    NSString *className = [FBSDKTypeUtility stringValueOrNil:item[@"UISceneDelegateClassName"]];
    if (className) {
      [delegates addObject:className];
    }
  }
  return [delegates copy];
}

- (void)logAutoSetupStatus:(BOOL)optin
                    source:(NSString *)source
{
  NSString *event = optin ? FBSDKAppEventNameOptinAEMAutoSetup : FBSDKAppEventNameOptoutAEMAutoSetup;
  [self.eventLogger logEvent:event parameters:@{
    @"source": source ?: @""
  }];
}

#if DEBUG

- (void)reset
{
  self.aemReporter = nil;
  self.swizzler = nil;
  self.eventLogger = nil;
  self.featureChecker = nil;
  self.crashHandler = nil;
  self.appEventsUtility = nil;
}

#endif

@end
