// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SKANTestUtils)
@interface SKANTestUtils : NSObject

+ (void)reset:(UITextView *)console;

+ (void)recordAndUpdateEvent:(NSString *)event
                    currency:(NSString *)currency
                       value:(NSString *)value
                     console:(UITextView *)console;

+ (void)swizzleReporterForConsole:(UITextView *)console;

@end

NS_ASSUME_NONNULL_END
