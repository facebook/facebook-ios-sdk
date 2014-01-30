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

#import "FBTestBlocker.h"
#import <SenTestingKit/SenTestingKit.h>

@interface FBTestBlocker ()

- (void)reset;

@end

@implementation FBTestBlocker {
    int _signalsRemaining;
    int _expectedSignalCount;
}

- (instancetype)init {
    return [self initWithExpectedSignalCount:1];
}

- (instancetype)initWithExpectedSignalCount:(NSInteger)expectedSignalCount {
    if ((self = [super init])) {
        _expectedSignalCount = expectedSignalCount;
        [self reset];
    }
    return self;
}

- (void)wait {
    [self waitWithTimeout:0];
}

- (void)waitWithPeriodicHandler:(FBTestBlockerPeriodicHandler)handler {
    [self waitWithTimeout:0
          periodicHandler:handler];
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout {
    return [self waitWithTimeout:timeout
                 periodicHandler:nil];
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout
        periodicHandler:(FBTestBlockerPeriodicHandler)handler {
    NSDate *start = [NSDate date];

    // loop until the previous call completes
    while (_signalsRemaining > 0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
        if (timeout > 0 &&
            [[NSDate date] timeIntervalSinceDate:start] > timeout) {
            [self reset];
            return NO;
        }
        if (handler) {
            handler(self);
        }
    };
    [self reset];
    return YES;
}

- (void)signal {
    --_signalsRemaining;
}

- (void)reset {
    _signalsRemaining = _expectedSignalCount;
}

+ (void)waitForVerifiedMock:(OCMockObject *)inMock delay:(NSTimeInterval)inDelay
{
    NSTimeInterval i = 0;
    while (i < inDelay)
    {
        @try
        {
            [inMock verify];
            return;
        }
        @catch (NSException *e) {}
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
        i+=0.5;
    }
    [inMock verify];
}

@end


// this is unrelated to test-blocker, but is a useful hack to make it easy to retarget the url
// without checking certs
@interface NSURLRequest (NSURLRequestWithIgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host;
@end

@implementation NSURLRequest (NSURLRequestWithIgnoreSSL)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
    return YES;
}
@end
