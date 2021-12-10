/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import <FBSDKCoreKit/FBSDKLoggingBehavior.h>

#import "FBSDKLogger.h"
#import "FBSDKLogging.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLogger (Internal) <FBSDKLogging>

// MARK: - Properties

// Access current accumulated contents of the logger.
@property (nonatomic, readonly, copy) NSString *contents;

// Each FBSDKLogger gets a unique serial number to allow the client to log these numbers and, for instance, correlation of Request/Response
@property (nonatomic, readonly) NSUInteger loggerSerialNumber;

// The logging behavior of this logger.
@property (nonatomic, readonly, copy) FBSDKLoggingBehavior loggingBehavior;

// Is the current logger instance active, based on its loggingBehavior?
@property (nonatomic, readonly, getter = isActive) BOOL active;

// MARK: - Instance Methods

// Create with specified logging behavior
- (instancetype)initWithLoggingBehavior:(FBSDKLoggingBehavior)loggingBehavior;

// Append string, or key/value pair
- (void)appendString:(NSString *)string;
- (void)appendFormat:(NSString *)formatString, ... NS_FORMAT_FUNCTION(1, 2);
- (void)appendKey:(NSString *)key value:(NSString *)value;

/// Logs entry if the current Settings contains the logging behavior for this logger instance
- (void)logEntry:(NSString *)logEntry;

// Emit log, clearing out the logger contents.
- (void)emitToNSLog;

// MARK: - Class Methods

// Return a globally unique serial number to be used for correlating multiple output from the same logger.
//
+ (NSUInteger)generateSerialNumber;

+ (void)singleShotLogEntry:(FBSDKLoggingBehavior)loggingBehavior
              timestampTag:(NSObject *)timestampTag
              formatString:(NSString *)formatString, ... NS_FORMAT_FUNCTION(3, 4);

// Register a timestamp label with the "current" time, to then be retrieved by singleShotLogEntry
// to include a duration.
+ (void)registerCurrentTime:(NSString *)loggingBehavior
                    withTag:(NSObject *)timestampTag;

// When logging strings, replace all instances of 'replace' with instances of 'replaceWith'.
+ (void)registerStringToReplace:(NSString *)replace
                    replaceWith:(NSString *)replaceWith;
@end

NS_ASSUME_NONNULL_END
