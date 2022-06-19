// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <objc/runtime.h>

#import "PerformanceBenchmarkUtils-Swift.h"

@interface PerfTestSwizzler : NSObject
@end

@implementation PerfTestSwizzler

+ (void)load
{
  NSDictionary *environment = NSProcessInfo.processInfo.environment;

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  // disable advertiser ID when integrate to 1pd app
  Class cls = NSClassFromString(@"FBSDKAppEventsUtility");
  SEL original = NSSelectorFromString(@"advertiserID");
  SEL replacement = NSSelectorFromString(@"_advertiserID");

  Method method1 = class_getClassMethod(cls, original);
  Method method2 = class_getClassMethod(cls, replacement);
  method_exchangeImplementations(method1, method2);

  // override app id to make sure all SDK features are ON
  cls = NSClassFromString(@"FBSDKSettings");
  original = NSSelectorFromString(@"appID");
  replacement = NSSelectorFromString(@"_appID");

  method1 = class_getClassMethod(cls, original);
  method2 = class_getClassMethod(cls, replacement);
  method_exchangeImplementations(method1, method2);

  // override text from button to trigger suggested event prediction
  cls = NSClassFromString(@"FBSDKViewHierarchy");
  original = NSSelectorFromString(@"getText:");
  replacement = NSSelectorFromString(@"_getText");

  method1 = class_getClassMethod(cls, original);
  method2 = class_getClassMethod(cls, replacement);
  method_exchangeImplementations(method1, method2);

  if ([environment[@"XPC_SERVICE_NAME"] containsString:@"com.facebook.Wilde"]) {
    cls = NSClassFromString(@"FBSDKInternalUtility");
    original = NSSelectorFromString(@"validateFacebookReservedURLSchemes");
    replacement = NSSelectorFromString(@"_validateFacebookReservedURLSchemes");

    method1 = class_getInstanceMethod(cls, original);
    method2 = class_getInstanceMethod(cls, replacement);
    method_exchangeImplementations(method1, method2);
  }
  cls = NSClassFromString(@"FBSDKApplicationDelegate");
  SEL sel = NSSelectorFromString(@"initializeSDK:");
  if ([cls respondsToSelector:sel]) {
    [cls performSelector:sel withObject:nil];
  }
  #pragma clang diagnostic pop
}

@end
