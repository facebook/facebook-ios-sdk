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

#import "FBSDKLoginManager.h"

typedef NS_ENUM(NSUInteger, FBSDKLoginManagerLoggerResult) {
  FBSDKLoginManagerLoggerResultSuccess,
  FBSDKLoginManagerLoggerResultCancel,
  FBSDKLoginManagerLoggerResultError,
  FBSDKLoginManagerLoggerResultSkipped,
};

@interface FBSDKLoginManagerLogger : NSObject
+ (FBSDKLoginManagerLogger *)loggerFromParameters:(NSDictionary *)parameters;

- (void)startEventWithBehavior:(FBSDKLoginBehavior)loginBehavior isReauthorize:(BOOL)isReauthorize;
- (void)endEvent;

- (void)startLoginWithBehavior:(FBSDKLoginBehavior)loginBehavior;
- (void)endLoginWithResult:(FBSDKLoginManagerLoggerResult)result error:(NSError *)error;

- (NSDictionary *)parametersWithTimeStampAndClientState:(NSDictionary *)loginParams forLoginBehavior:(FBSDKLoginBehavior)loginBehavior;
- (void)willAttemptAppSwitchingBehavior;
- (void)systemAuthDidShowDialog:(BOOL)didShowDialog isUnTOSedDevice:(BOOL)isUnTOSedDevice;
@end

extern NSString *const FBSDKLoginManagerLoggerTryNative;
extern NSString *const FBSDKLoginManagerLoggerTryBrowser;
extern NSString *const FBSDKLoginManagerLoggerTrySystemAccount;
extern NSString *const FBSDKLoginManagerLoggerTryWebView;
