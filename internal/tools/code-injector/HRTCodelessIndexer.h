// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^HRTCodelessSettingLoadBlock)(BOOL isCodelessSetupEnabled, NSError *_Nullable error);

NS_SWIFT_NAME(CodelessIndexer)
@interface HRTCodelessIndexer : NSObject

+ (void)enable;

@end

NS_ASSUME_NONNULL_END
