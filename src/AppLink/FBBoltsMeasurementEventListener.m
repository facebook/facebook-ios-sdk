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

#import "FBBoltsMeasurementEventListener.h"

#import "FBAppEvents+Internal.h"


static NSString *const BoltsMeasurementEventNotificationName = @"com.parse.bolts.measurement_event";
static NSString *const BoltsMeasurementEventName = @"event_name";
static NSString *const BoltsMeasurementEventArgs = @"event_args";
static NSString *const BoltsMeasurementEventPrefix = @"bf_";

@implementation FBBoltsMeasurementEventListener

+ (instancetype)defaultListener {
    static dispatch_once_t dispatchOnceLocker = 0;
    static FBBoltsMeasurementEventListener *defaultListener = nil;
    dispatch_once(&dispatchOnceLocker, ^{
        defaultListener = [[self alloc] init];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:defaultListener
                   selector:@selector(logFBAppEventForNotification:)
                       name:BoltsMeasurementEventNotificationName
                     object:nil];
    });
    return defaultListener;
}

- (void)logFBAppEventForNotification:(NSNotification *)note{
    [FBAppEvents logImplicitEvent:[BoltsMeasurementEventPrefix stringByAppendingString:note.userInfo[BoltsMeasurementEventName]]
                       valueToSum:nil
                       parameters:note.userInfo[BoltsMeasurementEventArgs]
                          session:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

@end
