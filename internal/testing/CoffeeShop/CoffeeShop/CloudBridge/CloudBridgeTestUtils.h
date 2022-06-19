// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(CloudBridgeTestUtils)
@interface CloudBridgeTestUtils : NSObject

+ (void)setup;

+ (void)recordAndUpdateEvent:(NSString *)event
              endpointValues:(NSString *)endpointValues
                    currency:(NSString *)currency
                       value:(NSString *)value
              eventParameter:(NSString *)eventParameter
                     console:(UITextView *)console;

@end

NS_ASSUME_NONNULL_END
