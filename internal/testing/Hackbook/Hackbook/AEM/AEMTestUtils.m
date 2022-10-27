// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "AEMTestUtils.h"

@import FBSDKCoreKit;
#import <objc/message.h>

static NSString *campaignId = @"";
static NSString *advertiserID = @"";

void extern dispatch_on_main_thread(dispatch_block_t block);

@interface FBSDKSettings ()

+ (void)setLoggingBehaviors:(NSSet<FBSDKLoggingBehavior> *)loggingBehaviors;

@end

@interface FBSDKAppEvents ()

- (void)publishInstall;

@end

@implementation AEMTestUtils

+ (void) reset:(nonnull UITextView *)console
      campaign:(nullable NSString *)campaign
    businessID:(nullable NSString *)businessID
  deeplinkType:(AEMDeeplinkURLType)deeplinkType
{
  campaignId = campaign;
  advertiserID = businessID;

  NSString *applinkPrefix = nil;
  switch (deeplinkType) {
    case AEMDeeplinkURLTypeCustomURLScheme:
      applinkPrefix = @"fb421415891237674://test.com";
      break;
    case AEMDeeplinkURLTypeUniversalLink:
      applinkPrefix = @"https://www.test.com";
      break;
  }
  NSString *const autoAppLink = [NSString stringWithFormat:@"%@?al_applink_data=", applinkPrefix];
  NSMutableDictionary<NSString *, NSString *> *data = [NSMutableDictionary new];
  data[@"acs_token"] = @"test_acstoken";
  data[@"campaign_ids"] = campaignId;
  if (businessID.length) {
    data[@"advertiser_id"] = businessID;
  }
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
  if (jsonData) {
    NSString *encodeData = [FBSDKUtility URLEncode:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    NSString *encodeURL = [autoAppLink stringByAppendingString:encodeData];
    NSURL *url = [NSURL URLWithString:encodeURL];

    [[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication]
                                                   openURL:url
                                         sourceApplication:nil
                                                annotation:nil];
    [self reset:console];
  }
}

+ (void)setCampaignFromUrl:(nullable NSURL *)url
{
  if (!url) {
    return;
  }

  NSDictionary<NSString *, NSString *> *params = [FBSDKUtility dictionaryWithQueryString:url.query];
  NSString *applinkDataString = params[@"al_applink_data"];
  if (!applinkDataString) {
    return;
  }

  NSDictionary<NSString *, id> *applinkData =
  [NSJSONSerialization JSONObjectWithData:[applinkDataString dataUsingEncoding:NSUTF8StringEncoding]
                                  options:0
                                    error:nil];
  if (!applinkData) {
    return;
  }
  campaignId = applinkData[@"campaign_ids"];
  advertiserID = applinkData[@"advertiser_id"];
}

+ (void)reset:(UITextView *)console
{
  if (campaignId.length > 0) {
    console.text = [NSString stringWithFormat:@"Jumped From Campaign: %@\t\tBusinessID: %@\t\t", campaignId, advertiserID];;
  }
}

+ (void)recordAndUpdateEvent:(NSString *)event
                    currency:(NSString *)currency
                       value:(NSString *)value
              eventParameter:(NSString *)eventParameter
                     console:(UITextView *)console
{
  console.text = [console.text stringByAppendingFormat:@"Recording event: %@\t\twith currency: %@\t\twith value: %@\t\twith parameter: %@\t\t", event, currency, value, eventParameter];
  eventParameter = eventParameter ?: @"";
  NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[eventParameter dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] ?: @{};
  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:json];
  parameters[@"fb_currency"] = currency;
  NSLog(@"param %@", parameters);
  [FBSDKAppEvents.shared logEvent:event
                       valueToSum:[value doubleValue]
                       parameters:parameters];
}

+ (void)publishInstall:(UITextView *)console
{
  console.text = [console.text stringByAppendingFormat:@"Publish Install with ATE: %@\t\t", @([[FBSDKSettings sharedSettings] isAdvertiserTrackingEnabled])];
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"com.facebook.sdk:lastAttributionPing%@", [[FBSDKSettings sharedSettings] appID]]];
  [FBSDKAppEvents.shared publishInstall];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
+ (void)swizzleReporterForConsole:(UITextView *)console
{
  Class aClass = NSClassFromString(@"FBSDKSwizzler");
  SEL aSelector = NSSelectorFromString(@"swizzleSelector:onClass:withBlock:named:");
  if (![aClass respondsToSelector:aSelector]) {
    return;
  }

  Class swizzledClass = NSClassFromString(@"FBSDKLogger");
  SEL swizzledResponseSelector = NSSelectorFromString(@"appendKey:value:");
  void (^requestBlock)(id target, SEL cmd, NSString *key, NSString *value) =
  ^(id target, SEL cmd, NSString *key, NSString *value) {
    if ([key isEqualToString:@"Attachments"]) {
      if ([value containsString:@"aem_conversions"]) {
        value = [value stringByReplacingOccurrencesOfString:@"\""
                                                 withString:@""];
        NSArray<NSString *> *items = [[value stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@"\n"];
        for (NSString *item in items) {
          if ([item containsString:@"aem_conversions"]) {
            dispatch_on_main_thread(^{
              console.text = [console.text stringByAppendingFormat:@"%@\t\t", item];
            });
          }
        }
      }
    }
  };

  typedef void (*send_type)(Class, SEL, SEL, Class, id, id);
  send_type msgSend = (send_type)objc_msgSend;
  msgSend(aClass, aSelector, swizzledResponseSelector, swizzledClass, requestBlock, @"ATETestConversion");
}

+ (void)setLoggingBehaviorsForNetworkRuquest
{
  FBSDKSettings.sharedSettings.loggingBehaviors = [NSSet setWithArray:@[@"developer_errors", @"network_requests"]];
}

#pragma clang diagnostic pop

@end
