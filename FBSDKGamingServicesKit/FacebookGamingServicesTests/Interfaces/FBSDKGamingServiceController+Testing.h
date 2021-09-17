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

@import FacebookGamingServices;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKGamingServiceController (Testing)

- (instancetype)initWithServiceType:(FBSDKGamingServiceType)serviceType
                  completionHandler:(FBSDKGamingServiceResultCompletion)completion
                      pendingResult:(id)pendingResult
                          urlOpener:(id<FBSDKURLOpener>)urlOpener
                           settings:(id<FBSDKSettings>)settings;

- (id<FBSDKSettings>)settings;

- (void)callWithArgument:(nullable NSString *)argument;

- (void)applicationDidBecomeActive:(UIApplication *)application;

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation;

- (BOOL)isValidCallbackURL:(NSURL *)url forService:(NSString *)service;

- (BOOL)isAuthenticationURL:(NSURL *)url;

- (void)handleBridgeAPIError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
