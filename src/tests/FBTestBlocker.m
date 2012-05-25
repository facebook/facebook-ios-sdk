/*
 * Copyright 2012 Facebook
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

#import "FBTestBlocker.h"
#import <SenTestingKit/SenTestingKit.h>

@interface FBTestBlocker ()

- (void)reset;

@end

@implementation FBTestBlocker {
    BOOL _keepRunning;
}

- (id)init {
    if (self = [super init]) {
        _keepRunning = YES;
    }
    return self;
}

- (void)wait {
    [self waitWithTimeout:0];
}

- (BOOL)waitWithTimeout:(NSUInteger)timeout {
    NSDate *start = [NSDate date];
    
    // loop until the previous call completes
    while (_keepRunning) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        if (timeout > 0 &&
            [[NSDate date] timeIntervalSinceDate:start] > timeout) {
            [self reset];
            return NO;
        } 
    };
    [self reset];
    return YES;
}

- (void)signal {
    _keepRunning = NO;
}

- (void)reset {
    _keepRunning = YES;
}
@end


// this is unrelated to test-blocker, but is a useful hack to make it easy to retarget the url
// without checking certs
@interface NSURLRequest (NSURLRequestWithIgnoreSSL) 
+(BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
@end

@implementation NSURLRequest (NSURLRequestWithIgnoreSSL) 
+(BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
    return YES;
}
@end