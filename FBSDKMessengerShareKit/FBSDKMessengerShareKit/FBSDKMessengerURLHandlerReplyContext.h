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

/**

  This object represents a user tapping reply from a message in Messenger. Passing
 this context into a share method will trigger the reply flow
 */
@interface FBSDKMessengerURLHandlerReplyContext : FBSDKMessengerContext

/**
  Additional information that was passed along with the original media that was replied to

 

 If content shared to Messenger incuded metadata and the user replied to that message,
 that metadata is passed along with the reply back to the app. If no metadata was included
 this is nil
 */
@property (nonatomic, copy, readonly) NSString *metadata;

/**
  The user IDs of the other participants on the thread.

 

 User IDs can be used with the Facebook SDK and Graph API (https://developers.facebook.com/docs/graph-api)
 to query names, photos, and other data. This will only contain IDs of users that
 have also logged into your app via their Facebook account.
 */
@property (nonatomic, copy, readonly) NSSet *userIDs;

@end
