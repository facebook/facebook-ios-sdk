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

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

// FBSample logic
// The protocols here show how to setup typed access to graph and open graph objects.
// The SDK automatically implements the properties of any protocol derived from
// FBGraphObject in terms of objectForKey and setObject:forKey; allowing applications
// to describe the expected structure of the objects used by the application in a
// lightweight and maintanable fashion. See the FBGraphObject.h header file for more
// details about FBGraphObject and related types.

// BOGGraphTruthValue protocol (graph accessors)
//
// Summary:
// Used to create and consume TruthValue open graph objects
@protocol BOGGraphTruthValue<FBGraphObject>

@property (retain, nonatomic) NSString                  *id;
@property (retain, nonatomic) NSString                  *url;
@property (retain, nonatomic) NSString                  *title;

@end

// BOGBooleanGraphAction protocol (graph accessors)
//
// Summary:
// Used to create and consume Or and And open graph actions
@protocol BOGGraphBooleanAction<FBOpenGraphAction>

@property (retain, nonatomic) NSString                  *result;
@property (retain, nonatomic) id<BOGGraphTruthValue>    truthvalue;
@property (retain, nonatomic) id<BOGGraphTruthValue>    anothertruthvalue;

@end

// BOGGraphPublishedBooleanAction protocol (graph accessors)
//
// Summary:
// Used to consume published Or and And open graph actions
@protocol BOGGraphPublishedBooleanAction<FBOpenGraphAction>

@property (retain, nonatomic) id<BOGGraphBooleanAction> data;
@property (retain, nonatomic) NSNumber                  *publish_time;
@property (retain, nonatomic) NSDate                    *publish_date;
@property (retain, nonatomic) NSString                  *verb;

@end

// BOGGraphBooleanActionList protocol (graph accessors)
//
// Summary:
// Used to consume published collections of Or and And open graph actions
@protocol BOGGraphBooleanActionList<FBOpenGraphAction>

@property (retain, nonatomic) NSArray                   *data;

@end


