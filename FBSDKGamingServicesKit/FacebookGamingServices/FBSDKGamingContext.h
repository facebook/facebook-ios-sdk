/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, FBSDKGamingContextType) {
  FBSDKGamingContextGeneric = 0,
  FBSDKGamingContextLink,
};

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GamingContext)
@interface FBSDKGamingContext : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/**
A shared object that holds data about the current user's  game instance which could be solo game or multiplayer game with other users.
*/
@property (class, nullable, nonatomic) FBSDKGamingContext *currentContext;

/**
 A unique identifier for the current game context. This represents a specific game instance that the user is playing in.
 */
@property (nonatomic, readonly) NSString *identifier;

/**
  The number of players in the current user's  game instance
 */
@property (readonly) NSInteger size;

/**
 Internal Type exposed to facilitate transition to Swift.
 API Subject to change or removal without warning. Do not use.

 Creates a context with an identifier. If the identifier is nil or empty, a context will not be created.

 @warning UNSAFE - DO NOT USE
 */
+ (nullable instancetype)createContextWithIdentifier:(NSString *)identifier size:(NSInteger)size;

@end

NS_ASSUME_NONNULL_END
