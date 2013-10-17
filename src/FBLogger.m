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

#import "FBLogger.h"

#import "FBSession.h"
#import "FBSettings.h"
#import "FBUtility.h"

static NSUInteger g_serialNumberCounter = 1111;
static NSMutableDictionary *g_stringsToReplace = nil;
static NSMutableDictionary *g_startTimesWithTags = nil;

@interface FBLogger ()

@property (nonatomic, retain, readonly) NSMutableString *internalContents;

@end

@implementation FBLogger

@synthesize internalContents = _internalContents;
@synthesize isActive = _isActive;
@synthesize loggingBehavior = _loggingBehavior;
@synthesize loggerSerialNumber = _loggerSerialNumber;

// Lifetime

- (id)initWithLoggingBehavior:(NSString *)loggingBehavior {
    if (self = [super init]) {
        _isActive = [[FBSettings loggingBehavior] containsObject:loggingBehavior];
        _loggingBehavior = loggingBehavior;
        if (_isActive) {
            _internalContents = [[NSMutableString alloc] init];
            _loggerSerialNumber = [FBLogger newSerialNumber];
        }
    }

    return self;
}

- (void)dealloc {
    [_internalContents release];
    [super dealloc];
}

// Public properties

- (NSString *)contents {
    return _internalContents;
}

- (void)setContents:(NSString *)contents {
    if (_isActive) {
        [_internalContents release];
        _internalContents = [NSMutableString stringWithString:contents];
    }
}

// Public instance methods

- (void)appendString:(NSString *)string {
    if (_isActive) {
        [_internalContents appendString:string];
    }
}

- (void)appendFormat:(NSString *)formatString, ... {
    if (_isActive) {
        va_list vaArguments;
        va_start(vaArguments, formatString);
        NSString *logString = [[[NSString alloc] initWithFormat:formatString arguments:vaArguments] autorelease];
        va_end(vaArguments);

        [self appendString:logString];
    }
}


- (void)appendKey:(NSString *)key value:(NSString *)value {
    if (_isActive && [value length]) {
        [_internalContents appendFormat:@"  %@:\t%@\n", key, value];
    }
}

- (void)emitToNSLog {
    if (_isActive) {

        for (NSString *key in [g_stringsToReplace keyEnumerator]) {
            [_internalContents replaceOccurrencesOfString:key
                                               withString:[g_stringsToReplace objectForKey:key]
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

        [_internalContents setString:@""];
    }
}

// Public static methods

+ (NSUInteger)newSerialNumber {
    return g_serialNumberCounter++;
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
                  logEntry:(NSString *)logEntry {
    if ([[FBSettings loggingBehavior] containsObject:loggingBehavior]) {
        FBLogger *logger = [[FBLogger alloc] initWithLoggingBehavior:loggingBehavior];
        [logger appendString:logEntry];
        [logger emitToNSLog];
        [logger release];
    }
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              formatString:(NSString *)formatString, ... {

    if ([[FBSettings loggingBehavior] containsObject:loggingBehavior]) {
        va_list vaArguments;
        va_start(vaArguments, formatString);
        NSString *logString = [[[NSString alloc] initWithFormat:formatString arguments:vaArguments] autorelease];
        va_end(vaArguments);

        [self singleShotLogEntry:loggingBehavior logEntry:logString];
    }
}


+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              timestampTag:(NSObject *)timestampTag
              formatString:(NSString *)formatString, ... {

    if ([[FBSettings loggingBehavior] containsObject:loggingBehavior]) {
        va_list vaArguments;
        va_start(vaArguments, formatString);
        NSString *logString = [[[NSString alloc] initWithFormat:formatString arguments:vaArguments] autorelease];
        va_end(vaArguments);

        // Start time of this "timestampTag" is stashed in the dictionary.
        // Treat the incoming object tag simply as an address, since it's only used to identify during lifetime.  If
        // we send in as an object, the dictionary will try to copy it.
        NSNumber *tagAsNumber = [NSNumber numberWithUnsignedLong:(unsigned long)(void *)timestampTag];
        NSNumber *startTimeNumber = [g_startTimesWithTags objectForKey:tagAsNumber];

        // Only log if there's been an associated start time.
        if (startTimeNumber) {
            unsigned long elapsed = [FBUtility currentTimeInMilliseconds] - startTimeNumber.unsignedLongValue;
            [g_startTimesWithTags removeObjectForKey:tagAsNumber];  // served its purpose, remove

            // Log string is appended with "%d msec", with nothing intervening.  This gives the most control to the caller.
            logString = [NSString stringWithFormat:@"%@%lu msec", logString, elapsed];

            [self singleShotLogEntry:loggingBehavior logEntry:logString];
        }
    }
}

+ (void)registerCurrentTime:(NSString *)loggingBehavior
                    withTag:(NSObject *)timestampTag {

    if ([[FBSettings loggingBehavior] containsObject:loggingBehavior]) {

        if (!g_startTimesWithTags) {
            g_startTimesWithTags = [[NSMutableDictionary alloc] init];
        }

        if (g_startTimesWithTags.count >= 1000) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors logEntry:
                    @"Unexpectedly large number of outstanding perf logging start times, something is likely wrong."];
        }

        unsigned long currTime = [FBUtility currentTimeInMilliseconds];

        // Treat the incoming object tag simply as an address, since it's only used to identify during lifetime.  If
        // we send in as an object, the dictionary will try to copy it.
        unsigned long tagAsNumber = (unsigned long)(void *)timestampTag;
        [g_startTimesWithTags setObject:[NSNumber numberWithUnsignedLong:currTime]
                                 forKey:[NSNumber numberWithUnsignedLong:tagAsNumber]];
    }
}


+ (void)registerStringToReplace:(NSString *)replace
                    replaceWith:(NSString *)replaceWith {

    // Strings sent in here never get cleaned up, but that's OK, don't ever expect too many.

    if ([[FBSettings loggingBehavior] count] > 0) {  // otherwise there's no logging.

        if (!g_stringsToReplace) {
            g_stringsToReplace = [[NSMutableDictionary alloc] init];
        }

        [g_stringsToReplace setValue:replaceWith forKey:replace];
    }
}



@end
