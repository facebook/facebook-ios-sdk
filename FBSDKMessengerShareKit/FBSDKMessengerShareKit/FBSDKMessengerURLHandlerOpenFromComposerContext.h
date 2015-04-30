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

#import "FBSDKMessengerShareKit.h"

/*!
 @class FBSDKMessengerURLHandlerReplyContext

 @abstract
 This object represents a user selecting this app from the composer in Messenger
 Passing this context into a share method will trigger a the reply flow
 */
@interface FBSDKMessengerURLHandlerOpenFromComposerContext : FBSDKMessengerContext

/*!
 @abstract
 Additional information that was passed along with the original media

 @discussion
 Note that when opening your app from Messenger composer, the metadata is pulled from
 the most recent attributed message on the thread.
 If the most recent attributed message with metadata is not cached on the device, metadata will be nil
 */
@property (nonatomic, copy, readonly) NSString *metadata;

/*!
 @abstract
 The user IDs of the other participants on the thread.

 @discussion
 User IDs can be used with the Facebook SDK and Graph API (https://developers.facebook.com/docs/graph-api)
 to query names, photos, and other data. This will only contain IDs of users that
 have also logged into your app via their Facebook account.

 Note that when opening your app from Messenger composer, the userIDs are pulled from
 the most recent attributed message on the thread.
 If the most recent attributed message is not cached on the device, userIDs will be nil
 */
@property (nonatomic, copy, readonly) NSSet *userIDs;

@end
