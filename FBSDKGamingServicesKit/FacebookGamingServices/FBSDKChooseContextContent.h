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

typedef NS_ENUM(NSInteger, FBSDKChooseContextFilter) {
  FBSDKChooseContextFilterNone = 0,
  FBSDKChooseContextFilterNewContextOnly,
  FBSDKChooseContextFilterExistingChallenges,
  FBSDKChooseContextFilterNewPlayersOnly,
}NS_SWIFT_NAME(ChooseContextFilter);


NS_ASSUME_NONNULL_BEGIN

/**
 A model for an instant games choose context app switch dialog
 */
NS_SWIFT_NAME(ChooseContextContent)
@interface FBSDKChooseContextContent : NSObject <FBSDKValidatable>

/**
  This sets the filter which determines which context will show when the user is app switched to the choose context dialog.
 */
@property (nonatomic) FBSDKChooseContextFilter filter;

/**
  This sets the maximum number of participants that the suggested context(s) shown in the dialog should have.
 */
@property (nonatomic) int maxParticipants;

/**
  This sets the minimum number of participants that the suggested context(s) shown in the dialog should have.
 */
@property (nonatomic) int minParticipants;


+ (NSString *)filtersNameForFilters:(FBSDKChooseContextFilter)filter;

@end

NS_ASSUME_NONNULL_END

#endif
