/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Internal type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 @warning INTERNAL - DO NOT USE
 */
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
                  queryParameters:(NSDictionary<NSString *, id> *)queryParameters
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

/**
  Validates that the right URL schemes are registered, throws an NSException if not.
 */
- (void)validateURLSchemes;

@end

NS_ASSUME_NONNULL_END
