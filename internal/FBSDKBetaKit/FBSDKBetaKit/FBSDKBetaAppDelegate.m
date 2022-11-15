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
  });
}

@end
