/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBLogger.h"
#import "FBSession.h"
#import "FBUtility.h"

static NSUInteger g_serialNumberCounter = 1111; 
static NSMutableDictionary *g_stringsToReplace = nil;

@interface FBLogger ()

@property (nonatomic, retain, readonly) NSMutableString *internalContents;
@property (nonatomic, retain, readonly) NSMutableDictionary *stringsToReplace;

@end

@implementation FBLogger

@synthesize internalContents = _internalContents;
@synthesize isActive = _isActive;
@synthesize loggingBehavior = _loggingBehavior;
@synthesize loggerSerialNumber = _loggerSerialNumber;
@synthesize stringsToReplace = _stringsToReplace;

// Lifetime

- (id)initWithLoggingBehavior:(NSString *)loggingBehavior {
    if (self = [super init]) {
        _isActive = [[FBSession loggingBehavior] containsObject:loggingBehavior];
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
        NSString *logString = [[NSString alloc] initWithFormat:formatString arguments:vaArguments];
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
        
        NSLog(@"FBSDKLog: %@", _internalContents);
        [_internalContents setString:@""];
    }
}

// Public static methods

+ (NSUInteger)newSerialNumber {
    return g_serialNumberCounter++;
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
                  logEntry:(NSString *)logEntry {
    if ([[FBSession loggingBehavior] containsObject:loggingBehavior]) {
        FBLogger *logger = [[FBLogger alloc] initWithLoggingBehavior:loggingBehavior];
        [logger appendString:logEntry];
        [logger emitToNSLog];
        [logger release];
    }
}

+ (void)singleShotLogEntry:(NSString *)loggingBehavior
              formatString:(NSString *)formatString, ...; {
    
    if ([[FBSession loggingBehavior] containsObject:loggingBehavior]) {
        va_list vaArguments;
        va_start(vaArguments, formatString);                                                                                
        NSString *logString = [[NSString alloc] initWithFormat:formatString arguments:vaArguments];
        va_end(vaArguments);

        [self singleShotLogEntry:loggingBehavior logEntry:logString];
    }
}

+ (void)registerStringToReplace:(NSString *)replace
                    replaceWith:(NSString *)replaceWith {
    
    // Strings sent in here never get cleaned up, but that's OK, don't ever expect too many.
    
    if ([[FBSession loggingBehavior] count] > 0) {  // otherwise there's no logging.
        
        if (!g_stringsToReplace) {
            g_stringsToReplace = [[NSMutableDictionary alloc] init];
        }
        
        [g_stringsToReplace setValue:replaceWith forKey:replace];
    }
}



@end
