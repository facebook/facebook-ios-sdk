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

#import "FBSessionAppEventsState.h"
#import "FBUtility.h"

NSString *const kFBAppEventIsImplicit = @"isImplicit";

@interface FBSessionAppEventsState ()

@property (readwrite, retain) NSMutableArray *accumulatedEvents;
@property (readwrite, retain) NSMutableArray *inFlightEvents;

@end

@implementation FBSessionAppEventsState

static const int MAX_ACCUMULATED_LOG_EVENTS = 1000;

- (instancetype)init {
    if ((self = [super init])) {
        _accumulatedEvents = [[NSMutableArray alloc] init];
        _inFlightEvents = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    self.accumulatedEvents = nil;
    self.inFlightEvents = nil;

    [super dealloc];
}

- (void)addEvent:(NSDictionary *)eventDictionary
      isImplicit:(BOOL)isImplicit {

    @synchronized (self) {
        if (self.accumulatedEvents.count + self.inFlightEvents.count >= MAX_ACCUMULATED_LOG_EVENTS) {
            // Skip, but record that we've done so.  This gets sent in the post when we do flush.
            self.numSkippedEventsDueToFullBuffer++;
        } else {
            [self.accumulatedEvents addObject:@{@"event" : eventDictionary,
                                                kFBAppEventIsImplicit : [NSNumber numberWithBool:isImplicit],
                                                }];
        }
    }
}

- (NSUInteger)getAccumulatedEventCount {
    @synchronized (self) {
        return self.accumulatedEvents.count;
    }
}

- (void)clearInFlightAndStats {
    @synchronized (self) {
        [self.inFlightEvents removeAllObjects];
        self.numSkippedEventsDueToFullBuffer = 0;
    }
}

- (BOOL)areAllEventsImplicit {
    for (NSDictionary *eventAndImplicitFlag in self.inFlightEvents) {
        if (![[eventAndImplicitFlag objectForKey:kFBAppEventIsImplicit] boolValue]) {
            return NO;
        }
    }
    return YES;
}

// JSON representation of the in-flight events, potentially excluding those marked as implicit.  Return
// nil if the resultant set of events is empty.
- (NSString *)jsonEncodeInFlightEvents:(BOOL)includeImplicitEvents {

    NSMutableArray *eventArray = [[NSMutableArray alloc] initWithCapacity:self.inFlightEvents.count];

    for (NSDictionary *eventAndImplicitFlag in self.inFlightEvents) {
        if (!includeImplicitEvents && [[eventAndImplicitFlag objectForKey:kFBAppEventIsImplicit] boolValue]) {
            continue;
        }
        [eventArray addObject:[eventAndImplicitFlag objectForKey:@"event"]];
    }

    NSString *jsonEncodedEvents = nil;
    if (eventArray.count != 0) {
        jsonEncodedEvents = [FBUtility simpleJSONEncode:eventArray];
    }

    [eventArray release];

    return jsonEncodedEvents;
}


@end

