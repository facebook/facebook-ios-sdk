// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKImpressionTrackingButton.h>
@class FBSDKIcon;

NS_ASSUME_NONNULL_BEGIN

/**
  A base class for common SDK buttons.
 */
NS_SWIFT_NAME(FBButton)
@interface FBSDKButton : FBSDKImpressionTrackingButton

@property (nonatomic, readonly, getter = isImplicitlyDisabled) BOOL implicitlyDisabled;

- (void)checkImplicitlyDisabled;
- (void)configureWithIcon:(nullable FBSDKIcon *)icon
                    title:(nullable NSString *)title
          backgroundColor:(nullable UIColor *)backgroundColor
         highlightedColor:(nullable UIColor *)highlightedColor;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
- (void) configureWithIcon:(nullable FBSDKIcon *)icon
                     title:(nullable NSString *)title
           backgroundColor:(nullable UIColor *)backgroundColor
          highlightedColor:(nullable UIColor *)highlightedColor
             selectedTitle:(nullable NSString *)selectedTitle
              selectedIcon:(nullable FBSDKIcon *)selectedIcon
             selectedColor:(nullable UIColor *)selectedColor
  selectedHighlightedColor:(nullable UIColor *)selectedHighlightedColor;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
- (UIColor *)defaultBackgroundColor;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
- (CGSize)sizeThatFits:(CGSize)size title:(NSString *)title;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
- (CGSize)textSizeForText:(NSString *)text font:(UIFont *)font constrainedSize:(CGSize)constrainedSize lineBreakMode:(NSLineBreakMode)lineBreakMode;

/**
 Internal method exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning UNSAFE - DO NOT USE
 */
- (void)logTapEventWithEventName:(NSString *)eventName
                      parameters:(nullable NSDictionary<NSString *, id> *)parameters;
@end

NS_ASSUME_NONNULL_END
