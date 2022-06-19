// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "CloudBridgeTestUtils.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBSDKCoreKit/FBSDKCoreKit-Swift.h>

@interface FBSDKAppEvents ()

@property (nullable, nonatomic) id<FBSDKGraphRequestFactory> graphRequestFactory;

@end

@implementation CloudBridgeTestUtils

+ (void)setup
{
  [FBSDKAppEvents.shared flush];
  [FBSDKTransformerGraphRequestFactory.shared configureWithDatasetID:@"885075468745573" url:@"https://mar29-appsdk.iots.us" accessKey:@"ndREzKMtQP"];
  FBSDKAppEvents.shared.graphRequestFactory = FBSDKTransformerGraphRequestFactory.shared;
}

+ (void)recordAndUpdateEvent:(NSString *)event
              endpointValues:(NSString *)endpointValues
                    currency:(NSString *)currency
                       value:(NSString *)value
              eventParameter:(NSString *)eventParameter
                     console:(UITextView *)console
{
  console.text = [console.text stringByAppendingFormat:@"Recording event: %@\t\twith currency: %@\t\twith value: %@\t\twith parameter: %@\t\t endpoint: %@ \n\n", event, currency, value, eventParameter, endpointValues];
  eventParameter = eventParameter ?: @"";
  NSDictionary *json = [FBSDKTypeUtility JSONObjectWithData:[eventParameter dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] ?: @{};
  NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:json];
  parameters[@"fb_currency"] = currency;
  NSLog(@"param %@", parameters);
  [FBSDKAppEvents.shared logEvent:event
                       valueToSum:[value doubleValue]
                       parameters:parameters];
}

@end
