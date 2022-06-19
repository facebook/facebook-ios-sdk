// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "RCTBackedTextInputViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

// Just a very simple UITextView conforming to RCTBackedTextInputViewProtocol
@interface RCTUITextView : UITextView <RCTBackedTextInputViewProtocol>

@property (nullable, nonatomic, copy) NSString *placeholder;

@end

NS_ASSUME_NONNULL_END
