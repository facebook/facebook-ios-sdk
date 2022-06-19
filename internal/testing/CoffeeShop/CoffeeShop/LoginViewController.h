// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LoginViewController : UIViewController

@property (nonatomic, strong) UIView *loginView;
@property (nonatomic, strong) UIView *textFieldLoginView;
@property (nonatomic, strong) UIView *textViewLoginView;
@property (nonatomic, assign) BOOL isSelectTextFieldLoginView;

@end

NS_ASSUME_NONNULL_END
