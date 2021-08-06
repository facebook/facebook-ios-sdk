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

#import "FBSDKLogger.h"
#if FBSDK_SWIFT_PACKAGE
 #import "FBSDKLoggingBehavior.h"
#else
 #import <FBSDKCoreKit/FBSDKLoggingBehavior.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKLogger (Internal)

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
