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

#if !TARGET_OS_TV

#import "FBSDKLoginManager+Internal.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Native;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Browser;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_SFVC;
FOUNDATION_EXPORT NSString *const FBSDKLoginManagerLoggerAuthMethod_Applink;


NS_SWIFT_NAME(LoginManagerLogger)
@interface FBSDKLoginManagerLogger : NSObject
+ (nullable FBSDKLoginManagerLogger *)loggerFromParameters:(nullable NSDictionary<NSString *, id> *)parameters
                                         tracking:(FBSDKLoginTracking)tracking;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithLoggingToken:(nullable NSString *)loggingToken
                            tracking:(FBSDKLoginTracking)tracking
NS_DESIGNATED_INITIALIZER;

// this must not retain loginManager - only used to conveniently grab various properties to log.
- (void)startSessionForLoginManager:(FBSDKLoginManager *)loginManager;
- (void)endSession;

- (void)startAuthMethod:(NSString *)authMethod;
- (void)endLoginWithResult:(nullable FBSDKLoginManagerLoginResult *)result error:(nullable NSError *)error;

- (void)postLoginHeartbeat;

+ (nullable NSString *)clientStateForAuthMethod:(nullable NSString *)authMethod
                      andExistingState:(nullable NSDictionary<NSString *, id> *)existingState
                                logger:(nullable FBSDKLoginManagerLogger *)logger;

- (void)willAttemptAppSwitchingBehavior;

- (void)logNativeAppDialogResult:(BOOL)result dialogDuration:(NSTimeInterval)dialogDuration;

- (void)addSingleLoggingExtra:(id)extra forKey:(nullable NSString *)key;
@end

#endif

NS_ASSUME_NONNULL_END
