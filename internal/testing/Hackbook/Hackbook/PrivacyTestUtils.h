// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

@import UIKit;

void dispatch_on_main_thread(dispatch_block_t block);

NS_SWIFT_NAME(PrivacyTestUtils)
@interface PrivacyTestUtils : NSObject

+ (void)setAdvertiserTrackingStatus:(NSUInteger)status;

+ (void)setDefaultAdvertiserTrackingStatus:(NSUInteger)status;

+ (NSUInteger)getAdvertisingTrackingStatus;

+ (void)swizzleOSVersionCheck;

+ (void)swizzleLoggerForConsole:(UITextView *)console;

+ (void)logEventsStateToConsole:(UITextView *)console;

+ (void)setIsIOS14:(BOOL)iOS14;

+ (void)setIsLATEnabled:(BOOL)enabled;

+ (void)setFlag:(NSString *)flag value:(BOOL)value;

+ (void)publishInstall;

@end
