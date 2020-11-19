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

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "FBSDKURLOpening.h"

NS_ASSUME_NONNULL_BEGIN

/// Duplicate minimal interface for `FBSDKLoginManager` that can fulfill the `FBSDKBridgeAPI`'s runtime requirement.
/// Used in the `FBSDKBridgeAPITests` as a spy since it will be discovered by the real class and used instead of the actual
/// `FBSDKLoginManager`.
@interface FBSDKLoginManager : NSObject <FBSDKURLOpening>

// The reason some of these properties are static is that there are cases where we dynamically
// check for the existence of the login manager at runtime. Since we don't have a handle to the
// instance we can make sure the properties are set on the type so that we can examine them there
// ultimately this is a pattern we need to get away from but this allows it to be tested while
// we refactor.
@property (class, nullable, copy) NSURL *capturedOpenUrl;
@property (class, nullable, copy) NSString *capturedSourceApplication;
@property (class, nullable, copy) NSString *capturedAnnotation;
@property (class) BOOL stubbedOpenUrlSuccess;
@property BOOL openUrlWasCalled;
@property (nullable, copy) NSURL *capturedCanOpenUrl;
@property (nullable, copy) NSString *capturedCanOpenSourceApplication;
@property (nullable, copy) NSString *capturedCanOpenAnnotation;
@property BOOL stubbedCanOpenUrl;
@property BOOL stubbedIsAuthenticationUrl;

+ (void)resetTestEvidence;

- (void)stubShouldStopPropagationOfURL:(NSURL *)url withValue:(BOOL)shouldStop;
- (BOOL)shouldStopPropagationOfURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
