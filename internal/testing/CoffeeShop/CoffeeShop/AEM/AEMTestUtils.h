// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AEMDeeplinkUrlType) {
  AEMDeeplinkUrlTypeCustomUrlScheme,
  AEMDeeplinkUrlTypeUniversalLink,
} NS_SWIFT_NAME(DeeplinkUrlType);

NS_SWIFT_NAME(AEMTestUtils)
@interface AEMTestUtils : NSObject

+ (void)reset:(nonnull UITextView *)console;

+ (void) reset:(nonnull UITextView *)console
      campaign:(nullable NSString *)campaign
  deeplinkType:(AEMDeeplinkUrlType)deeplinkType;

+ (void)setCampaignFromUrl:(nullable NSURL *)url;

+ (void)recordAndUpdateEvent:(nonnull NSString *)event
                    currency:(nullable NSString *)currency
                       value:(nullable NSString *)value
                     console:(nonnull UITextView *)console;

+ (void)swizzleReporterForConsole:(nonnull UITextView *)console;

+ (void)setLoggingBehaviorsForNetworkRuquest;

@end
