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

#import <FBSDKShareKit/FBSDKSharing.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A dialog for sharing content through Messenger.

 SUPPORTED SHARE TYPES
 - FBSDKShareLinkContent
 - FBSDKShareMessengerOpenGraphMusicTemplateContent
 - FBSDKShareMessengerMediaTemplateContent
 - FBSDKShareMessengerGenericTemplateContent

 UNSUPPORTED SHARE TYPES (DEPRECATED AUGUST 2018)
 - FBSDKShareOpenGraphContent
 - FBSDKSharePhotoContent
 - FBSDKShareVideoContent
 - Any other types that are not one of the four supported types listed above
 */
NS_SWIFT_NAME(MessageDialog)
@interface FBSDKMessageDialog : NSObject <FBSDKSharingDialog>

/**
 Convenience method to return a Message Share Dialog with content and a delegate.
 @param content The content to be shared.
 @param delegate The receiver's delegate.
 */
+ (instancetype)dialogWithContent:(id<FBSDKSharingContent>)content
                         delegate:(nullable id<FBSDKSharingDelegate>)delegate
NS_SWIFT_NAME(init(content:delegate:));

/**
 Convenience method to show a Message Share Dialog with content and a delegate.
 @param content The content to be shared.
 @param delegate The receiver's delegate.
 */
+ (instancetype)showWithContent:(id<FBSDKSharingContent>)content
                       delegate:(nullable id<FBSDKSharingDelegate>)delegate
NS_SWIFT_UNAVAILABLE("Use init(content:delegate:).show() instead");

@end

NS_ASSUME_NONNULL_END
