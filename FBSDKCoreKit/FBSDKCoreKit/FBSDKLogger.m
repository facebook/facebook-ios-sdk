/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKLogger.h"
#import "FBSDKLogger+Internal.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKSettings.h"

static NSUInteger g_serialNumberCounter = 1111;
static NSMutableDictionary<NSString *, id> *g_stringsToReplace = nil;
static NSMutableDictionary<NSNumber *, id> *g_startTimesWithTags = nil;

@interface FBSDKLogger ()

@property (nonatomic) NSUInteger loggerSerialNumber;
@property (nonatomic, copy) FBSDKLoggingBehavior loggingBehavior;
@property (nonatomic, getter = isActive) BOOL active;
@property (nonatomic, readonly, strong) NSMutableString *internalContents;
@end

@implementation FBSDKLogger

// Lifetime

// Deprecating the method requires it to be implemented.
// This should be removed in the next major release.
+ (instancetype)new
{
  return [super new];
}

// Deprecating the method requires it to be implemented.
// This should be removed in the next major release.
- (instancetype)init
{
  return [super init];
}

- (instancetype)initWithLoggingBehavior:(NSString *)loggingBehavior
{
  if ((self = [super init])) {
    _active = [FBSDKSettings.sharedSettings.loggingBehaviors containsObject:loggingBehavior];
    _loggingBehavior = loggingBehavior;
    if (_active) {
      _internalContents = [NSMutableString new];
      _loggerSerialNumber = [FBSDKLogger generateSerialNumber];
    }
  }

  return self;
}

// Public properties

- (NSString *)contents
{
  return _internalContents;
}

- (void)setContents:(NSString *)contents
{
  if (_active) {
    _internalContents = [NSMutableString stringWithString:contents];
  }
}

// Public instance methods

- (void)appendString:(NSString *)string
{
  if (_active) {
    [_internalContents appendString:string];
  }
}

- (void)appendFormat:(NSString *)formatString, ...
{
  if (_active) {
    va_list vaArguments;
    va_start(vaArguments, formatString);
    NSString *logString = [[NSString alloc] initWithFormat:formatString arguments:vaArguments];
    va_end(vaArguments);

    [self appendString:logString];
  }
}

- (void)appendKey:(NSString *)key value:(NSString *)value
{
  if (_active && value.length) {
    [_internalContents appendFormat:@"  %@:\t%@\n", key, value];
  }
}

- (void)emitToNSLog
{
  if (_active) {
    for (NSString *key in [g_stringsToReplace keyEnumerator]) {
      [_internalContents replaceOccurrencesOfString:key
                                         withString:g_stringsToReplace[key]
                                            options:NSLiteralSearch
                                              range:NSMakeRange(0, _internalContents.length)];
    }

    // Xcode 4.4 hangs on extremely long NSLog output (http://openradar.appspot.com/11972490).  Truncate if needed.
    const int MAX_LOG_STRING_LENGTH = 10000;
    NSString *logString = _internalContents;
    if (_internalContents.length > MAX_LOG_STRING_LENGTH) {
      logString = [NSString stringWithFormat:@"TRUNCATED: %@", [_internalContents substringToIndex:MAX_LOG_STRING_LENGTH]];
    }
    NSLog(@"FBSDKLog: %@", logString);

    _internalContents.string = @"";
  }
}

// Public static methods

+ (NSUInteger)generateSerialNumber
{
  @synchronized(self) {
    return ++g_serialNumberCounter;
  }
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
                  logEntry:(NSString *)logEntry
{
  FBSDKLogger *logger = [[FBSDKLogger alloc] initWithLoggingBehavior:loggingBehavior];
  [logger logEntry:logEntry];
}

- (void)logEntry:(NSString *)logEntry
{
  if ([FBSDKSettings.sharedSettings.loggingBehaviors containsObject:_loggingBehavior]) {
    [self appendString:logEntry];
    [self emitToNSLog];
  }
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              timestampTag:(NSObject *)timestampTag
              formatString:(NSString *)formatString, ...
{
  if ([FBSDKSettings.sharedSettings.loggingBehaviors containsObject:loggingBehavior]) {
    va_list vaArguments;
    va_start(vaArguments, formatString);
    NSString *logString = [[NSString alloc] initWithFormat:formatString arguments:vaArguments];
    va_end(vaArguments);

    // Start time of this "timestampTag" is stashed in the dictionary.
    // Treat the incoming object tag simply as an address, since it's only used to identify during lifetime.  If
    // we send in as an object, the dictionary will try to copy it.
    NSNumber *tagAsNumber = @((unsigned long)(__bridge void *)timestampTag);
    NSNumber *startTimeNumber = g_startTimesWithTags[tagAsNumber];

    // Only log if there's been an associated start time.
    if (startTimeNumber != nil) {
      uint64_t elapsed = [FBSDKInternalUtility.sharedUtility currentTimeInMilliseconds] - startTimeNumber.unsignedLongLongValue;
      [g_startTimesWithTags removeObjectForKey:tagAsNumber]; // served its purpose, remove

      // Log string is appended with "%d msec", with nothing intervening.  This gives the most control to the caller.
      logString = [NSString stringWithFormat:@"%@%llu msec", logString, elapsed];

      [self singleShotLogEntry:loggingBehavior logEntry:logString];
    }
  }
}

+ (void)registerCurrentTime:(NSString *)loggingBehavior
                    withTag:(NSObject *)timestampTag
{
  if ([FBSDKSettings.sharedSettings.loggingBehaviors containsObject:loggingBehavior]) {
    if (!g_startTimesWithTags) {
      g_startTimesWithTags = [NSMutableDictionary new];
    }

    if (g_startTimesWithTags.count >= 1000) {
      [FBSDKLogger singleShotLogEntry:FBSDKLoggingBehaviorDeveloperErrors logEntry:
       @"Unexpectedly large number of outstanding perf logging start times, something is likely wrong."];
    }

    uint64_t currTime = [FBSDKInternalUtility.sharedUtility currentTimeInMilliseconds];

    // Treat the incoming object tag simply as an address, since it's only used to identify during lifetime.  If
    // we send in as an object, the dictionary will try to copy it.
    unsigned long tagAsNumber = (unsigned long)(__bridge void *)timestampTag;
    [FBSDKTypeUtility dictionary:g_startTimesWithTags setObject:@(currTime) forKey:@(tagAsNumber)];
  }
}

+ (void)registerStringToReplace:(NSString *)replace
                    replaceWith:(NSString *)replaceWith
{
  // Strings sent in here never get cleaned up, but that's OK, don't ever expect too many.

  if (FBSDKSettings.sharedSettings.loggingBehaviors.count > 0) { // otherwise there's no logging.
    if (!g_stringsToReplace) {
      g_stringsToReplace = [NSMutableDictionary new];
    }

    [g_stringsToReplace setValue:replaceWith forKey:replace];
  }
}

@end
