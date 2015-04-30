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

/*!
 @abstract
 Defines what visual style a UIButton should have
 */
typedef NS_ENUM(NSUInteger, FBSDKMessengerShareButtonStyle) {
  FBSDKMessengerShareButtonStyleBlue = 0,
  FBSDKMessengerShareButtonStyleWhite = 1,
  FBSDKMessengerShareButtonStyleWhiteBordered = 2,
};

/*!
 @class FBSDKMessengerShareButton

 @abstract
 Provides a helper method to return a UIButton intended for sharing to Messenger
 */
@interface FBSDKMessengerShareButton : NSObject

/*!
 @abstract
 Returns a rounded rectangular UIButton customized for sharing to Messenger

 @param style Specifies how the button should look

 @discussion
 This button can be resized after creation

 There is 1 string in the implemention of this button which needs to be translated
 by your app:

 NSLocalizedString(@"Send", @"Button label for sending a message")
 */
+ (UIButton *)rectangularButtonWithStyle:(FBSDKMessengerShareButtonStyle)style;


/*!
 @abstract
 Returns a circular UIButton customized for sharing to Messenger

 @param style Specifies how the button should look
 @param width The desired frame width (and height) of this button.

 @discussion
 This button's asset is drawn as a vector such that it scales appropriately
 using the width parameter as a hint. This hint is to prevent button resizing artifacts.
 */
+ (UIButton *)circularButtonWithStyle:(FBSDKMessengerShareButtonStyle)style
                                width:(CGFloat)width;

/*!
 @abstract
 Returns a circular UIButton customized for sharing to Messenger of default size

 @param style Specifies how the button should look
 */
+ (UIButton *)circularButtonWithStyle:(FBSDKMessengerShareButtonStyle)style;

@end
