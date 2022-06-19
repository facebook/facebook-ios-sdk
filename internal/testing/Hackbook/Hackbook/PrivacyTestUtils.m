// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "PrivacyTestUtils.h"

#import <AdSupport/ASIdentifierManager.h>

@import FBSDKCoreKit;
#import <objc/message.h>

static NSString *const FBSDKSettingsAdvertisingTrackingStatus = @"com.facebook.sdk:FBSDKSettingsAdvertisingTrackingStatus";
static NSUInteger _defaultATEStatus = 2; // default is unspecified
static NSUInteger _ATEStatus = 2; // default is unspecified
static BOOL _isIOS14 = false;
static BOOL _isLATEnabled = false;
static BOOL _appEventCollectionEnabled = false;
static BOOL _advertiserIDCollectionEnabled = false;

typedef void (*send_type)(Class, SEL, SEL, Class, id, id);

void dispatch_on_main_thread(dispatch_block_t block)
{
  if (block != nil) {
    if ([NSThread isMainThread]) {
      block();
    } else {
      dispatch_async(dispatch_get_main_queue(), block);
    }
  }
}

@interface FBSDKAppEvents ()

- (void)publishInstall;

@end

@interface FBSDKSettings ()

- (void)setAdvertiserTrackingStatus:(NSUInteger)status;

- (NSUInteger)advertisingTrackingStatus;

@end

@implementation PrivacyTestUtils

+ (void)setAdvertiserTrackingStatus:(NSUInteger)status
{
  _ATEStatus = status;
  if (status == 2) {
    [self setDefaultAdvertiserTrackingStatus:_defaultATEStatus];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:FBSDKSettingsAdvertisingTrackingStatus];
  } else {
    [FBSDKSettings.sharedSettings setAdvertiserTrackingStatus:status];
  }
}

+ (NSUInteger)getAdvertisingTrackingStatus
{
  return [FBSDKSettings.sharedSettings advertisingTrackingStatus];
}

+ (void)setDefaultAdvertiserTrackingStatus:(NSUInteger)status
{
  _defaultATEStatus = status;
  if (_ATEStatus == 2) {
    [FBSDKSettings.sharedSettings setAdvertiserTrackingStatus:status];
  }
}

+ (void)setIsIOS14:(BOOL)iOS14
{
  _isIOS14 = iOS14;
}

+ (void)setIsLATEnabled:(BOOL)enabled
{
  _isLATEnabled = enabled;
}

+ (void)swizzleOSVersionCheck
{
  Class FBSDKSettingsClass = [FBSDKSettings class];
  SEL original = @selector(advertisingTrackingStatus);
  SEL replacement = @selector(PrivacyTestUtils_getAdvertisingTrackingStatus);

  Method method1 = class_getClassMethod(FBSDKSettingsClass, original);
  Method method2 = class_getClassMethod([self class], replacement);
  method_exchangeImplementations(method1, method2);

  Class FBSDKAppEventsUtilityClass = NSClassFromString(@"FBSDKAppEventsUtility");
  original = NSSelectorFromString(@"shouldDropAppEvent");
  replacement = @selector(PrivacyTestUtils_shouldDropAppEvent);
  method1 = class_getClassMethod(FBSDKAppEventsUtilityClass, original);
  method2 = class_getClassMethod([self class], replacement);
  method_exchangeImplementations(method1, method2);

  original = NSSelectorFromString(@"advertiserID");
  replacement = @selector(PrivacyTestUtils_advertiserID);
  method1 = class_getClassMethod(FBSDKAppEventsUtilityClass, original);
  method2 = class_getClassMethod([self class], replacement);
  method_exchangeImplementations(method1, method2);
}

+ (NSUInteger)PrivacyTestUtils_getAdvertisingTrackingStatus
{
  if (_isIOS14) {
    NSNumber *advertiserTrackingStatus = [[NSUserDefaults standardUserDefaults] objectForKey:FBSDKSettingsAdvertisingTrackingStatus] ?: @(_defaultATEStatus);
    return advertiserTrackingStatus.unsignedIntegerValue;
  } else {
    if (_isLATEnabled) {
      return 1;
    }
    return 0;
  }
}

+ (BOOL)PrivacyTestUtils_shouldDropAppEvent
{
  return [PrivacyTestUtils shouldDropAppEvent];
}

+ (NSString *)PrivacyTestUtils_advertiserID
{
  if (!FBSDKSettings.sharedSettings.isAdvertiserIDCollectionEnabled) {
    return nil;
  }

  if (_isIOS14) {
    if (!_advertiserIDCollectionEnabled) {
      return nil;
    }
  }

  if (_isLATEnabled) {
    return @"00000000-0000-0000-0000-000000000000";
  }
  return @"11111111-1111-1111-1111-1111111111";
}

+ (BOOL)shouldDropAppEvent
{
  if (_isIOS14) {
    if ([FBSDKSettings.sharedSettings advertisingTrackingStatus] == 1 && !_appEventCollectionEnabled) {
      return YES;
    }
  }
  return NO;
}

+ (void)swizzleLoggerForConsole:(UITextView *)console
{
  Class aClass = NSClassFromString(@"FBSDKSwizzler");
  SEL aSelector = NSSelectorFromString(@"swizzleSelector:onClass:withBlock:named:");
  if (![aClass respondsToSelector:aSelector]) {
    return;
  }

  Class swizzledClass = NSClassFromString(@"FBSDKLogger");
  SEL swizzledRequestSelector = NSSelectorFromString(@"appendKey:value:");
  void (^requestBlock)(id target, SEL cmd, NSString *key, NSString *value) =
  ^(id target, SEL cmd, NSString *key, NSString *value) {
    if ([key isEqualToString:@"Attachments"]) {
      NSArray<NSString *> *items = [[value stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@"\n"];
      NSString *advertiserID = [PrivacyTestUtils getInfo:@"advertiser_id:" FromLog:items];
      NSString *advertiserTrackingEnabled = [PrivacyTestUtils getInfo:@"advertiser_tracking_enabled:" FromLog:items];
      NSString *event = [PrivacyTestUtils getInfo:@"event:" FromLog:items];
      NSString *installTimestamp = [PrivacyTestUtils getInfo:@"install_timestamp:" FromLog:items];
      NSString *events = [PrivacyTestUtils getInfo:@"custom_events:" FromLog:items];
      NSString *log = [NSString stringWithFormat:@"Events are sent with\t%@\t%@\t%@\t%@\t%@\t", (advertiserID ?: @"advertiser_id:\tnull"), (advertiserTrackingEnabled ?: @"advertiser_tracking_enabled:\tnull"), (event ?: @"event: null"), (events ?: @"custom_events:\tnull"), (installTimestamp ?: @"install_timestamp:\tnull")];
      dispatch_on_main_thread(^{
        console.text = [console.text stringByAppendingString:log];
        NSRange range = NSMakeRange(console.text.length, 0);
        [console scrollRangeToVisible:range];
      });
    }
  };
  SEL swizzledResponseSelector = NSSelectorFromString(@"appendString:");
  void (^responseBlock)(id target, SEL cmd, NSString *logEntry) =
  ^(id target, SEL cmd, NSString *logEntry) {
    logEntry = [logEntry stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSRange range = [logEntry rangeOfString:@"Flush Result"];
    if (range.location != NSNotFound) {
      NSString *log = [NSString stringWithFormat:@"%@\t", [logEntry substringFromIndex:range.location]];
      dispatch_on_main_thread(^{
        console.text = [console.text stringByAppendingString:log];
      });
    }
  };
  send_type msgSend = (send_type)objc_msgSend;
  msgSend(aClass, aSelector, swizzledRequestSelector, swizzledClass, requestBlock, @"iOS14TestRequest");
  msgSend(aClass, aSelector, swizzledResponseSelector, swizzledClass, responseBlock, @"iOS14TestResponse");
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
+ (void)logEventsStateToConsole:(UITextView *)console;
{
  FBSDKAppEvents *appEvents = [FBSDKAppEvents shared];
  Ivar eventsStateVar = class_getInstanceVariable([appEvents class], "_appEventsState");
  id eventsState = object_getIvar(appEvents, eventsStateVar);
  SEL eventsSelector = NSSelectorFromString(@"events");
  NSInteger count = 0;
  if ([eventsState respondsToSelector:eventsSelector]) {
    NSArray<NSDictionary *> *events = [eventsState performSelector:eventsSelector];
    count = events.count;
  }
  NSString *log = [NSString stringWithFormat:@"Number of events in queue: %@\t", @(count)];
  dispatch_on_main_thread(^{
    console.text = [console.text stringByAppendingString:log];
    NSRange range = NSMakeRange(console.text.length, 0);
    [console scrollRangeToVisible:range];
  });
}

#pragma clang diagnostic pop

+ (NSString *)getInfo:(NSString *)info
              FromLog:(NSArray<NSString *> *)items
{
  for (NSString *item in items) {
    if ([item containsString:info]) {
      return item;
    }
  }
  return nil;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
+ (void)setFlag:(NSString *)flag value:(BOOL)value
{
  if ([flag isEqualToString:@"_eventCollectionEnabled"]) {
    _appEventCollectionEnabled = value;
  }
  if ([flag isEqualToString:@"_advertiserIDCollectionEnabled"]) {
    _advertiserIDCollectionEnabled = value;
  }
  Class configurationManagerClass = NSClassFromString(@"FBSDKAppEventsConfigurationManager");
  SEL selector = NSSelectorFromString(@"cachedAppEventsConfiguration");
  if (![configurationManagerClass respondsToSelector:selector]) {
    return;
  }
  id cachedConfiguration = [configurationManagerClass performSelector:selector];
  Class configurationClass = NSClassFromString(@"FBSDKAppEventsConfiguration");
  Ivar ivar = class_getInstanceVariable(configurationClass, flag.UTF8String);
  ptrdiff_t offset = ivar_getOffset(ivar);
  // BOOL var is a char
  char *value_ptr = (__bridge void *)cachedConfiguration + offset;
  *value_ptr = value;
}

#pragma clang diagnostic pop

+ (void)publishInstall
{
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"com.facebook.sdk:lastAttributionPing%@", [[FBSDKSettings sharedSettings] appID]]];
  [FBSDKAppEvents.shared publishInstall];
}

@end
