/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

/*!
 @class FBLogger

 @abstract
 Simple logging utility for conditionally logging strings and then emitting them
 via NSLog().

 @unsorted
 */
@interface FBLogger : NSObject

// Access current accumulated contents of the logger.
@property (copy, nonatomic) NSString *contents;

// Each FBLogger gets a unique serial number to allow the client to log these numbers and, for instance, correlation of Request/Response
@property (nonatomic, readonly) NSUInteger loggerSerialNumber;

// The logging behavior of this logger.  See the FB_LOG_BEHAVIOR* constants in FBSession.h
@property (copy, nonatomic, readonly) NSString *loggingBehavior;

// Is the current logger instance active, based on its loggingBehavior?
@property (nonatomic, readonly) BOOL isActive;

//
// Instance methods
//

// Create with specified logging behavior
- (instancetype)initWithLoggingBehavior:(NSString *)loggingBehavior;

// Append string, or key/value pair
- (void)appendString:(NSString *)string;
- (void)appendFormat:(NSString *)formatString, ... NS_FORMAT_FUNCTION(1,2);
- (void)appendKey:(NSString *)key value:(NSString *)value;

// Emit log, clearing out the logger contents.
- (void)emitToNSLog;

//
// Class methods
//

//
// Return a globally unique serial number to be used for correlating multiple output from the same logger.
//
+ (NSUInteger)newSerialNumber;

// Simple helper to write a single log entry, based upon whether the behavior matches a specified on.
+ (void)singleShotLogEntry:(NSString *)loggingBehavior
                  logEntry:(NSString *)logEntry;

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              formatString:(NSString *)formatString, ... NS_FORMAT_FUNCTION(2,3);

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              timestampTag:(NSObject *)timestampTag
              formatString:(NSString *)formatString, ... NS_FORMAT_FUNCTION(3,4);

// Register a timestamp label with the "current" time, to then be retrieved by singleShotLogEntry
// to include a duration.
+ (void)registerCurrentTime:(NSString *)loggingBehavior
                    withTag:(NSObject *)timestampTag;

// When logging strings, replace all instances of 'replace' with instances of 'replaceWith'.
+ (void)registerStringToReplace:(NSString *)replace
                    replaceWith:(NSString *)replaceWith;

@end
