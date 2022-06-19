// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// This protocol is used to test customized UITextInput in AAM and keeps text-related properties of React Natice's protocol
// https://github.com/facebook/react-native/blob/master/Libraries/Text/TextInput/RCTBackedTextInputViewProtocol.h
@protocol RCTBackedTextInputViewProtocol <UITextInput>

@property (nullable, nonatomic, copy) NSAttributedString *attributedText;
@property (nullable, nonatomic, copy) NSString *placeholder;

// This protocol disallows direct access to `selectedTextRange` property because
// unwise usage of it can break the `delegate` behavior. So, we always have to
// explicitly specify should `delegate` be notified about the change or not.
// If the change was initiated programmatically, we must NOT notify the delegate.
// If the change was a result of user actions (like typing or touches), we MUST notify the delegate.
- (void)setSelectedTextRange:(nullable UITextRange *)selectedTextRange NS_UNAVAILABLE;
- (void)setSelectedTextRange:(nullable UITextRange *)selectedTextRange notifyDelegate:(BOOL)notifyDelegate;

// This protocol disallows direct access to `text` property because
// unwise usage of it can break the `attributeText` behavior.
// Use `attributedText.string` instead.
@property (nullable, nonatomic, copy) NSString *text NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
