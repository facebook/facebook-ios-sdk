// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#if TARGET_OS_SIMULATOR

NS_ASSUME_NONNULL_BEGIN
@interface FBE2EViewForWWWTestRun : UIView

@property (nonatomic, readwrite, weak) UIView *rootView;

@end
NS_ASSUME_NONNULL_END

#endif
