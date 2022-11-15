// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "FBSDKBetaAppDelegate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//#import <FBAEMKit/FBAEMKit.h>
#import "FBAEMKit/FBAEMKit-Swift.h"

#import "FBSDKBetaSwizzler.h"

@implementation FBSDKBetaAppDelegate

+ (void)setup
{
  id<UIApplicationDelegate> delegate = [[UIApplication sharedApplication] delegate];
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class clazz = delegate.class;
    [FBSDKBetaSwizzler swizzleSelector:@selector(application:openURL:options:) onClass:clazz withBlock:^(id delegate, SEL cmd, id application, NSURL *url, id options) {
      [FBAEMReporter enable];
      [FBAEMReporter handle:url];
    } named:@"AEMDeeplinkAutoSetup"];
    
    
    [FBSDKBetaSwizzler swizzleSelector:@selector(application:continueUserActivity:restorationHandler:) onClass:clazz withBlock:^(id delegate, SEL cmd, id application, NSUserActivity *userActivity, id restorationHandler) {
      [FBAEMReporter enable];
      [FBAEMReporter handle:userActivity.webpageURL];
    } named:@"AEMUniversallinkAutoSetup"];
    
    if (@available(iOS 13.0, *)) {
      NSSet<UIScene *> *scenes = [[UIApplication sharedApplication] connectedScenes];
      for (UIScene* scene in scenes) {
        id<UISceneDelegate> sceneDelegate = scene.delegate;
        Class sceneClass = sceneDelegate.class;
        [FBSDKBetaSwizzler swizzleSelector:@selector(scene:openURLContexts:) onClass:sceneClass withBlock:^(id sceneDelegate, SEL cmd, id scene, NSSet<UIOpenURLContext *> *urlContexts) {
          [FBAEMReporter enable];
          for(UIOpenURLContext* urlContext in urlContexts) {
            [FBAEMReporter handle:urlContext.URL];
          }
        } named:@"AEMSceneDeeplinkAutoSetup"];
        
        [FBSDKBetaSwizzler swizzleSelector:@selector(scene:continueUserActivity:) onClass:sceneClass withBlock:^(id sceneDelegate, SEL cmd, id scene, NSUserActivity *userActivity) {
          [FBAEMReporter enable];
          [FBAEMReporter handle:userActivity.webpageURL];
        } named:@"AEMSceneUniversallinkAutoSetup"];
      }
      
    }
    
  });
}

@end
