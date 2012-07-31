/*
 * Copyright 2012 Facebook
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

#import <Foundation/Foundation.h>

/*
 * Constants defining logging behavior.  Use with <[FBSettings setLoggingBehavior]>.
 */

/*! Log requests from FBRequest* classes */
extern NSString *const FBLoggingBehaviorFBRequests;

/*! Log requests from FBURLConnection* classes */
extern NSString *const FBLoggingBehaviorFBURLConnections;

/*! Include access token in logging. */
extern NSString *const FBLoggingBehaviorAccessTokens;

/*! Log session state transitions. */
extern NSString *const FBLoggingBehaviorSessionStateTransitions;

/*! Log performance characteristics */
extern NSString *const FBLoggingBehaviorPerformanceCharacteristics;

@interface FBSettings : NSObject

/*!
 @method
 
 @abstract Retrieve the current Facebook SDK logging behavior.
 
 */
+ (NSSet *)loggingBehavior;

/*!
 @method
 
 @abstract Set the current Facebook SDK logging behavior.  This should consist of strings defined as
 constants with FBLogBehavior*, and can be constructed with [NSSet initWithObjects:].
 
 @param loggingBehavior A set of strings indicating what information should be logged.
 */
+ (void)setLoggingBehavior:(NSSet *)loggingBehavior;

@end
