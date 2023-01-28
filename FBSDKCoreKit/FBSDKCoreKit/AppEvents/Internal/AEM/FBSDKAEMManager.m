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

@interface FBSDKAEMManager ()

@property (nonnull, nonatomic) Class<FBSDKSwizzling> swizzler;
@property (nullable, nonatomic) Class<FBSDKAEMReporter> aemReporter;

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
{
  self.swizzler = swizzler;
  self.aemReporter = aemReporter;
}

- (void)enableAutoSetup
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class clazz = [[UIApplication sharedApplication] delegate].class;
    [self.swizzler swizzleSelector:@selector(application:openURL:options:) onClass:clazz withBlock:^(id delegate, SEL cmd, id application, NSURL *url, id options) {
      [self.aemReporter enable];
      [self.aemReporter handle:url];
    } named:@"AEMDeeplinkAutoSetup"];
    
    
    [self.swizzler swizzleSelector:@selector(application:continueUserActivity:restorationHandler:) onClass:clazz withBlock:^(id delegate, SEL cmd, id application, NSUserActivity *userActivity, id restorationHandler) {
      [self.aemReporter enable];
      [self.aemReporter handle:userActivity.webpageURL];
    } named:@"AEMUniversallinkAutoSetup"];
    
    if (@available(iOS 13.0, *)) {
      NSSet<UIScene *> *scenes = [[UIApplication sharedApplication] connectedScenes];
      for (UIScene* thisScene in scenes) {
        Class sceneClass = thisScene.delegate.class;
        [self.swizzler swizzleSelector:@selector(scene:openURLContexts:) onClass:sceneClass withBlock:^(id sceneDelegate, SEL cmd, id scene, NSSet<UIOpenURLContext *> *urlContexts) {
          [self.aemReporter enable];
          for(UIOpenURLContext* urlContext in urlContexts) {
            [self.aemReporter handle:urlContext.URL];
          }
        } named:@"AEMSceneDeeplinkAutoSetup"];
        
        [self.swizzler swizzleSelector:@selector(scene:continueUserActivity:) onClass:sceneClass withBlock:^(id sceneDelegate, SEL cmd, id scene, NSUserActivity *userActivity) {
          [self.aemReporter enable];
          [self.aemReporter handle:userActivity.webpageURL];
        } named:@"AEMSceneUniversallinkAutoSetup"];
      }
      
    }
  });
}

@end
