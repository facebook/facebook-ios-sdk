// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <objc/runtime.h>

#import <E2EUtils/E2EUtils-Swift.h>

@interface E2EProxySwizzler : NSObject
@end

@implementation E2EProxySwizzler

+ (void)load
{
  NSDictionary *environment = NSProcessInfo.processInfo.environment;

  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  if (environment[@"IS_TESTING"]) {
    Class cls = NSURLSessionConfiguration.class;
    SEL original = @selector(defaultSessionConfiguration);
    SEL replacement = @selector(_defaultSessionConfiguration);

    Method method1 = class_getClassMethod(cls, original);
    Method method2 = class_getClassMethod(cls, replacement);
    method_exchangeImplementations(method1, method2);

    cls = NSClassFromString(@"FBSDKSettings");
    original = NSSelectorFromString(@"facebookDomainPart");
    replacement = NSSelectorFromString(@"_facebookDomainPart");
    method1 = class_getClassMethod(cls, original);
    method2 = class_getClassMethod(cls, replacement);
    method_exchangeImplementations(method1, method2);
  }
  #pragma clang diagnostic pop
}

@end
