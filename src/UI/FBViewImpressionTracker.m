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

#import "FBViewImpressionTracker.h"

#import "FBAppEvents+Internal.h"
#import "FBSession.h"

@implementation FBViewImpressionTracker
{
    NSHashTable *_trackedImpressions;
}

#pragma mark - Class Methods

+ (instancetype)impressionTrackerWithEventName:(NSString *)eventName
{
    static NSMutableDictionary *_impressionTrackers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _impressionTrackers = [[NSMutableDictionary alloc] init];
    });

    FBViewImpressionTracker *impressionTracker = _impressionTrackers[eventName];
    if (!impressionTracker) {
        impressionTracker = [[self alloc] initWithEventName:eventName];
        _impressionTrackers[eventName] = impressionTracker;
    }
    return impressionTracker;
}

#pragma mark - Object Lifecycle

- (instancetype)initWithEventName:(NSString *)eventName
{
    if ((self = [super init])) {
        _eventName = [eventName copy];
        _trackedImpressions = [[NSHashTable weakObjectsHashTable] retain];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_applicationDidEnterBackgroundNotification:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:[UIApplication sharedApplication]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_eventName release];
    [_session release];
    [_trackedImpressions release];
    [super dealloc];
}

#pragma mark - Public API

- (void)logImpressionWithView:(UIView *)view
                   identifier:(NSString *)identifier
                   parameters:(NSDictionary *)parameters
{
    NSMutableDictionary *keys = [NSMutableDictionary dictionary];
    keys[@"__view_impression_identifier__"] = identifier;
    [keys addEntriesFromDictionary:parameters];
    NSDictionary *impressionKey = [[keys copy] autorelease];

    if ([_trackedImpressions containsObject:impressionKey]) {
        return;
    }
    [_trackedImpressions addObject:impressionKey];

    [FBAppEvents logImplicitEvent:self.eventName
                       valueToSum:nil
                       parameters:parameters
                          session:self.session ?: [FBSession activeSession]];
}

#pragma mark - Helper Methods

- (void)_applicationDidEnterBackgroundNotification:(NSNotification *)notification
{
    // reset all tracked impressions when the app backgrounds so we will start tracking them again the next time they
    // are triggered.
    [_trackedImpressions removeAllObjects];
}

@end
