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

 #import <UIKit/UIKit.h>

 #import <FBSDKCoreKit/FBSDKCoreKit.h>
 #import <FBSDKLoginKit/FBSDKLoginManager.h>

 #import "FBSDKLoginProviding.h"

NS_ASSUME_NONNULL_BEGIN

@class FBSDKLoginCompletionParameters;
@class FBSDKLoginManagerLogger;
@class FBSDKPermission;

/**
 Success Block
 */
typedef void (^ FBSDKBrowserLoginSuccessBlock)(BOOL didOpen, NSError *error)
NS_SWIFT_NAME(BrowserLoginSuccessBlock);

typedef NS_ENUM(NSInteger, FBSDKLoginManagerState) {
  FBSDKLoginManagerStateIdle,
  // We received a call to start login.
  FBSDKLoginManagerStateStart,
  // We're calling out to the Facebook app or Safari to perform a log in
  FBSDKLoginManagerStatePerformingLogin,
};

@interface FBSDKLoginManager () <FBSDKURLOpening, FBSDKLoginProviding>
@property (nullable, nonatomic, weak) UIViewController *fromViewController;
@property (nullable, nonatomic, readonly) NSSet<FBSDKPermission *> *requestedPermissions;
@property (nullable, nonatomic, strong) FBSDKLoginManagerLogger *logger;
@property (nullable, nonatomic, strong) FBSDKLoginConfiguration *config;
@property (nonatomic) FBSDKLoginManagerState state;
@property (nonatomic) BOOL usedSFAuthSession;

@property (nullable, nonatomic, readonly, copy) NSString *loadExpectedChallenge;
@property (nullable, nonatomic, readonly, copy) NSString *loadExpectedNonce;

- (void)completeAuthentication:(FBSDKLoginCompletionParameters *)parameters expectChallenge:(BOOL)expectChallenge;

- (void)logIn;

// made available for testing only
- (nullable NSDictionary<NSString *, id> *)logInParametersWithConfiguration:(nullable FBSDKLoginConfiguration *)configuration
                                                               loggingToken:(NSString *)loggingToken
                                                                     logger:(FBSDKLoginManagerLogger *)logger
                                                                 authMethod:(NSString *)authMethod;

// for testing only
- (void)setHandler:(FBSDKLoginManagerLoginResultBlock)handler;
// for testing only
- (void)setRequestedPermissions:(NSSet *)requestedPermissions;

// available to internal modules
- (void)handleImplicitCancelOfLogIn;
- (void)invokeHandler:(nullable FBSDKLoginManagerLoginResult *)result error:(nullable NSError *)error;
- (BOOL)validateLoginStartState;
- (BOOL)isPerformingLogin;
+ (NSString *)stringForChallenge;
- (void)storeExpectedChallenge:(nullable NSString *)expectedChallenge;

@end

#endif

NS_ASSUME_NONNULL_END
