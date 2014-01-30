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

#import <Foundation/Foundation.h>

#import <FacebookSDK/FacebookSDK.h>

// FBSample logic
// The protocols here show how to setup typed access to graph and open graph objects.
// The SDK automatically implements the properties of any protocol derived from
// FBGraphObject in terms of objectForKey and setObject:forKey; allowing applications
// to describe the expected structure of the objects used by the application in a
// lightweight and maintanable fashion. See the FBGraphObject.h header file for more
// details about FBGraphObject and related types.

// RPSGraphGesture protocol (graph accessors)
//
// Summary:
// Used to create and consume Gesture open graph objects
@protocol RPSGraphGesture<FBGraphObject>

@property (retain, nonatomic) NSString *id;
@property (retain, nonatomic) NSString *url;
@property (retain, nonatomic) NSString *title;

@end

// RPSGraphThrowAction protocol (graph accessors)
//
// Summary:
// Used to create and consume Throw open graph actions
@protocol RPSGraphThrowAction<FBOpenGraphAction>

@property (retain, nonatomic) id<RPSGraphGesture> gesture;
@property (retain, nonatomic) id<RPSGraphGesture> opposing_gesture;

@end

// RPSGraphPublishedThrowAction protocol (graph accessors)
//
// Summary:
// Used to consume published Throw open graph actions
@protocol RPSGraphPublishedThrowAction<FBOpenGraphAction>

@property (retain, nonatomic) id<RPSGraphThrowAction> data;
@property (retain, nonatomic) NSString *publish_time;
@property (retain, nonatomic) NSDate *publish_date;

@end

// RPSGraphActionList protocol (graph accessors)
//
// Summary:
// Used to consume published collections of open graph actions
@protocol RPSGraphActionList<FBOpenGraphAction>

@property (retain, nonatomic) NSArray *data;

@end


