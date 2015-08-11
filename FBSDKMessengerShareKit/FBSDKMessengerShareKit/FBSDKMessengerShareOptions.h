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

#import <Foundation/Foundation.h>

#import "FBSDKMessengerContext.h"

/*!
 @class FBSDKMessengerShareOptions

 @abstract
 Optional parameters that change the way content is shared into Messenger
 */
@interface FBSDKMessengerShareOptions : NSObject

/*!
 @abstract Pass additional information to be sent to Messenger which is sent back to
 the user's app when they reply to an attributed message.
 */
@property (nonatomic, readwrite, copy) NSString *metadata;

/*!
@abstract Optional property describing the www source URL of the content

@discussion Setting this property improves performance by allowing Messenger to download
 the content directly rather than uploading the content from your app.
 This option is only used for animated GIFs and WebPs.
 */
@property (nonatomic, readwrite, copy) NSURL *sourceURL;

/*!
 @abstract Optional property describing whether the content should be rendered like a sticker

 @discussion Setting this property informs Messenger that the media content should be rendered
 as a sticker.
 This option is only used for static images.
 */
@property (nonatomic, readwrite, assign) BOOL renderAsSticker;

/*!
 @abstract Optional property that overrides the default way the content will be shared to messenger

 @discussion By default, if a user enters your app via a replyable context in Messenger
 (for instance, tapping Reply on a message or opening your app from composer), the next share
 out of your app will trigger the reply flow in Messenger by default. If you'd prefer to not
 trigger the reply flow, then overriding this with FBSDKMessengerBroadcastContext will trigger the
 broadcast flow in messenger.
 */
@property (nonatomic, readwrite, strong) FBSDKMessengerContext *contextOverride;

@end
