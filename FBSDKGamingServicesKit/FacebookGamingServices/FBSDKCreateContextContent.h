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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

#import <Foundation/Foundation.h>

#import <FacebookGamingServices/FBSDKDialogProtocol.h>
NS_ASSUME_NONNULL_BEGIN

/**
 A model for an instant games createAsync cross play request.
 */
NS_SWIFT_NAME(CreateContextContent)
@interface FBSDKCreateContextContent : NSObject <NSSecureCoding, FBSDKValidatable>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
  Builds a content object that will be use to display a create context dialog
 @param playerID The player ID of the user being challenged which will be used  to create a game context
 */
- (instancetype)initDialogContentWithPlayerID:(NSString*)playerID
NS_SWIFT_NAME(init(playerID:));

/**
 The ID of the player that is being challenged.
 @return The ID for the player being challenged
 */
@property (nonatomic, copy) NSString *playerID;
@end

NS_ASSUME_NONNULL_END

#endif
