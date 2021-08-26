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

NS_SWIFT_NAME(InternalUtilityProtocol)
@protocol FBSDKInternalUtility

#pragma mark - FB Apps Installed

@property (nonatomic, readonly) BOOL isFacebookAppInstalled;

/**
  Constructs an NSURL.
 @param scheme The scheme for the URL.
 @param host The host for the URL.
 @param path The path for the URL.
 @param queryParameters The query parameters for the URL.  This will be converted into a query string.
 @param errorRef If an error occurs, upon return contains an NSError object that describes the problem.
 @return The URL.
 */
- (nullable NSURL *)URLWithScheme:(NSString *)scheme
                             host:(NSString *)host
                             path:(NSString *)path
                  queryParameters:(NSDictionary *)queryParameters
                            error:(NSError *__autoreleasing *)errorRef;

/**
  Registers a transient object so that it will not be deallocated until unregistered
 @param object The transient object
 */
- (void)registerTransientObject:(id)object;

/**
  Unregisters a transient object that was previously registered with registerTransientObject:
 @param object The transient object
 */
- (void)unregisterTransientObject:(__weak id)object;

- (void)checkRegisteredCanOpenURLScheme:(NSString *)urlScheme;

@end

NS_ASSUME_NONNULL_END
