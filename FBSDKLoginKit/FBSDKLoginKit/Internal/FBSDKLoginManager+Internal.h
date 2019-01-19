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

#import <UIKit/UIKit.h>

#import <FBSDKLoginKit/FBSDKLoginManager.h>

#import "FBSDKCoreKit+Internal.h"

@class FBSDKAccessToken;
@class FBSDKLoginCompletionParameters;

/**
 Success Block
 */
typedef void (^FBSDKBrowserLoginSuccessBlock)(BOOL didOpen, NSString *authMethod, NSError *error)
NS_SWIFT_NAME(BrowserLoginSuccessBlock);

NS_SWIFT_NAME(LoginManagerSystemAccountState)
@interface FBSDKLoginManagerSystemAccountState : NSObject
@property (nonatomic, assign) BOOL didShowDialog;
@property (nonatomic, getter=isReauthorize) BOOL reauthorize;
@property (nonatomic, getter=isUnTOSedDevice) BOOL unTOSedDevice;
@end

@interface FBSDKLoginManager ()
@property (nonatomic, weak) UIViewController *fromViewController;
@property (nonatomic, readonly) NSSet *requestedPermissions;

// for testing only
@property (nonatomic, readonly, copy) NSString *loadExpectedChallenge;

- (void)completeAuthentication:(FBSDKLoginCompletionParameters *)parameters expectChallenge:(BOOL)expectChallenge;

// available to internal types to trigger login without checking read/publish mixtures.
- (void)logInWithPermissions:(NSSet *)permissions handler:(FBSDKLoginManagerLoginResultBlock)handler;
- (void)logInWithBehavior:(FBSDKLoginBehavior)loginBehavior;

// made available for testing only
- (NSDictionary *)logInParametersWithPermissions:(NSSet *)permissions serverConfiguration:(FBSDKServerConfiguration *)serverConfiguration;
// made available for testing only
- (void)validateReauthentication:(FBSDKAccessToken *)currentToken withResult:(FBSDKLoginManagerLoginResult *)loginResult;

// for testing only
- (void)setHandler:(FBSDKLoginManagerLoginResultBlock)handler;
// for testing only
- (void)setRequestedPermissions:(NSSet *)requestedPermissions;

@end

// the category is made available for testing only
@interface FBSDKLoginManager (Native) <FBSDKURLOpening>

- (void)performNativeLogInWithParameters:(NSDictionary *)loginParams handler:(FBSDKSuccessBlock)handler;
- (void)performBrowserLogInWithParameters:(NSDictionary *)loginParams handler:(FBSDKBrowserLoginSuccessBlock)handler;

@end

// the category is made available for testing only
@interface FBSDKLoginManager (Accounts)

- (void)beginSystemLogIn;
- (void)performSystemLogIn;
- (void)continueSystemLogInWithTokenString:(NSString *)oauthToken error:(NSError *)accountStoreError state:(FBSDKLoginManagerSystemAccountState *)state;

- (void)fallbackToNativeBehavior;

@end

// the category is made available for testing only
@interface FBSDKLoginManager (WebDialog) <FBSDKWebDialogDelegate>

- (void)performWebLogInWithParameters:(NSDictionary *)loginParams handler:(FBSDKSuccessBlock)handler;

@end
