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

NS_ASSUME_NONNULL_BEGIN

/// Constant used to describe the 'Like' dialog
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameLike;
/// Constant used to describe the 'Message' dialog
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameMessage;
/// Constant used to describe the 'Share' dialog
FOUNDATION_EXPORT NSString *const FBSDKDialogConfigurationNameShare;

@protocol FBSDKServerConfigurationProviding;

/**
 A lightweight interface to expose aspects of FBSDKServerConfiguration that are used by dialogs in ShareKit.

 Internal Use Only
 */
NS_SWIFT_NAME(ShareDialogConfiguration)
@interface FBSDKShareDialogConfiguration : NSObject

@property (nonatomic, copy, readonly) NSString *defaultShareMode;

- (BOOL)shouldUseNativeDialogForDialogName:(NSString *)dialogName;
- (BOOL)shouldUseSafariViewControllerForDialogName:(NSString *)dialogName;

@end

NS_ASSUME_NONNULL_END
