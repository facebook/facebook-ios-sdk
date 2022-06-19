// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "SKANTestUtils.h"

#import <StoreKit/SKAdNetwork.h>

@import FBSDKCoreKit;
#import <objc/message.h>

void extern dispatch_on_main_thread(dispatch_block_t block);

static UITextView *_console;

@implementation SKANTestUtils

+ (void)reset:(UITextView *)console
{
  NSDate *date = [NSDate date];
  [[NSUserDefaults standardUserDefaults] setObject:date forKey:@"com.facebook.sdk:FBSDKSettingsInstallTimestamp"];
  console.text = [NSString stringWithFormat:@"New Install %@\t\t", date];
}

+ (void)recordAndUpdateEvent:(NSString *)event
                    currency:(NSString *)currency
                       value:(NSString *)value
                     console:(UITextView *)console
{
  console.text = [console.text stringByAppendingFormat:@"Recording event: %@\t\twith currency: %@\t\twith value: %@\t\t", event, currency, value];
  NSMutableDictionary *parameters = [NSMutableDictionary new];
  if (currency) {
    parameters[@"fb_currency"] = currency;
  }
  [FBSDKAppEvents.shared logEvent:event
                       valueToSum:[value doubleValue]
                       parameters:parameters];
}

+ (void)swizzleReporterForConsole:(UITextView *)console
{
  _console = console;
  if (@available(iOS 11.3, *)) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      SEL original = @selector(updateConversionValue:);
      SEL replacement = @selector(SKANTestUtils_updateConversionValue:);

      Method method1 = class_getClassMethod(SKAdNetwork.class, original);
      Method method2 = class_getClassMethod([self class], replacement);
      method_exchangeImplementations(method1, method2);
    });
  }
}

+ (void)SKANTestUtils_updateConversionValue:(NSInteger)value
{
  dispatch_on_main_thread(^{
    _console.text = [_console.text stringByAppendingFormat:@"update_conversion_value: %@\t\t", @(value)];
  });
}

@end
