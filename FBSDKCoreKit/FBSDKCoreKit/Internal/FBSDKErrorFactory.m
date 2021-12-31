/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKErrorFactory+Internal.h"

#import "FBSDKConstants.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBSDKErrorFactory

// MARK: - Class Dependencies

static id<FBSDKErrorReporting> _defaultReporter;

+ (nullable id<FBSDKErrorReporting>)defaultReporter
{
  return _defaultReporter;
}

+ (void)setDefaultReporter:(nullable id<FBSDKErrorReporting>)defaultReporter
{
  _defaultReporter = defaultReporter;
}

+ (void)configureWithDefaultReporter:(id<FBSDKErrorReporting>)defaultReporter
{
  self.defaultReporter = defaultReporter;
}

#if FBTEST

+ (void)resetClassDependencies
{
  self.defaultReporter = nil;
}

#endif

// MARK: - Lifecycle

- (instancetype)initWithReporter:(id<FBSDKErrorReporting>)reporter
{
  if ((self = [self init])) {
    _reporter = reporter;
  }

  return self;
}

// MARK: - General Errors

- (NSError *)errorWithCode:(NSInteger)code
                  userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                   message:(nullable NSString *)message
           underlyingError:(nullable NSError *)underlyingError
{
  return [self errorWithDomain:FBSDKErrorDomain
                          code:code
                      userInfo:userInfo
                       message:message
               underlyingError:underlyingError];
}

- (NSError *)errorWithDomain:(NSErrorDomain)domain
                        code:(NSInteger)code
                    userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
                     message:(nullable NSString *)message
             underlyingError:(nullable NSError *)underlyingError
{
  NSMutableDictionary<NSString *, id> *fullUserInfo = [[NSMutableDictionary alloc] initWithDictionary:userInfo];

  if (message) {
    fullUserInfo[FBSDKErrorDeveloperMessageKey] = message;
  }

  if (underlyingError) {
    fullUserInfo[NSUnderlyingErrorKey] = underlyingError;
  }

  userInfo = fullUserInfo.count ? [fullUserInfo copy] : nil;
  [self reportErrorWithCode:code domain:domain message:message];

  return [[NSError alloc] initWithDomain:domain code:code userInfo:userInfo];
}

// MARK: - Invalid Argument Errors

- (NSError *)invalidArgumentErrorWithName:(NSString *)name
                                    value:(nullable id)value
                                  message:(nullable NSString *)message
                          underlyingError:(nullable NSError *)underlyingError
{
  return [self invalidArgumentErrorWithDomain:FBSDKErrorDomain
                                         name:name
                                        value:value
                                      message:message
                              underlyingError:underlyingError];
}

- (NSError *)invalidArgumentErrorWithDomain:(NSErrorDomain)domain
                                       name:(NSString *)name
                                      value:(nullable id)value
                                    message:(nullable NSString *)optionalMessage
                            underlyingError:(nullable NSError *)underlyingError
{
  NSString *message = optionalMessage ?: [NSString stringWithFormat:@"Invalid value for %@: %@", name, value];
  NSMutableDictionary<NSString *, id> *userInfo = [NSMutableDictionary new];
  userInfo[FBSDKErrorArgumentNameKey] = name;

  if (value) {
    userInfo[FBSDKErrorArgumentValueKey] = value;
  }

  return [self errorWithDomain:domain
                          code:FBSDKErrorInvalidArgument
                      userInfo:userInfo
                       message:message
               underlyingError:underlyingError];
}

// MARK: - Required Argument Errors

- (nonnull NSError *)requiredArgumentErrorWithName:(NSString *)name
                                           message:(nullable NSString *)message
                                   underlyingError:(nullable NSError *)underlyingError
{
  return [self requiredArgumentErrorWithDomain:FBSDKErrorDomain
                                          name:name
                                       message:message
                               underlyingError:underlyingError];
}

- (NSError *)requiredArgumentErrorWithDomain:(NSErrorDomain)domain
                                        name:(NSString *)name
                                     message:(nullable NSString *)optionalMessage
                             underlyingError:(nullable NSError *)underlyingError
{
  NSString *message = optionalMessage ?: [NSString stringWithFormat:@"Value for %@ is required.", name];

  return [self invalidArgumentErrorWithDomain:domain
                                         name:name
                                        value:nil
                                      message:message
                              underlyingError:underlyingError];
}

// MARK: - Unknown Errors

- (NSError *)unknownErrorWithMessage:(nullable NSString *)message
                            userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)userInfo
{
  return [self errorWithCode:FBSDKErrorUnknown
                    userInfo:userInfo
                     message:message
             underlyingError:nil];
}

// MARK: - Reporting

- (void)reportErrorWithCode:(NSInteger)code
                     domain:(NSString *)domain
                    message:(nullable NSString *)message
{
  id<FBSDKErrorReporting> reporter = self.reporter ?: self.class.defaultReporter;
  [reporter saveError:code errorDomain:domain message:message];
}

@end

NS_ASSUME_NONNULL_END
