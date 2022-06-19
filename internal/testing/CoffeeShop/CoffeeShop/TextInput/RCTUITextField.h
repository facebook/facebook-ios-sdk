// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "RCTBackedTextInputViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

// Just a very simple UITextField conforming to RCTBackedTextInputViewProtocol
@interface RCTUITextField : UITextField <RCTBackedTextInputViewProtocol>

@end

NS_ASSUME_NONNULL_END
