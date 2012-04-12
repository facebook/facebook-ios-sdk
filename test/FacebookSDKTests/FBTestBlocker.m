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

@implementation FBTestBlocker {
    BOOL _keepRunning;
}

- (id)init {
    self = [super init];
    if (self) {
        _keepRunning = YES;
    }
    return self;
}

- (void)signal {
    // loop until the previous call completes
    do {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
    } while (_keepRunning);
}

- (void)wait {
    _keepRunning = false;
}

@end
