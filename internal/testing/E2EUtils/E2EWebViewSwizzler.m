// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <objc/runtime.h>

#import <E2EUtils/E2EUtils-Swift.h>

@interface E2EWebViewSwizzler : NSObject
@end

@implementation E2EWebViewSwizzler

+ (void)load
{
  NSDictionary *environment = NSProcessInfo.processInfo.environment;

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if (environment[@"IS_TESTING"]) {
    Class cls = NSClassFromString(@"FBSDKBridgeAPI");
    SEL original = NSSelectorFromString(@"openURLWithAuthenticationSession:");
    SEL replacement = @selector(_openURLWithAuthenticationSessionWithUrl:);

    Method method1 = class_getInstanceMethod(cls, original);
    Method method2 = class_getInstanceMethod(cls, replacement);
    method_exchangeImplementations(method1, method2);
  }
  #pragma clang diagnostic pop
}

@end
