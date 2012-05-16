/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/xlicenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "FBGraphObject.h"

@protocol FBGraphPlace;
@protocol FBGraphUser;

// FBOpenGraphAction protocol (graph accessor)
//
// Summary:
// represents an Open Graph custom action, to be used directly, or from which to
// derive custom action protocols with custom properties
@protocol FBOpenGraphAction<FBGraphObject>

@property (retain, nonatomic) NSString              *id;
@property (retain, nonatomic) NSString              *start_time;
@property (retain, nonatomic) NSString              *end_time;
@property (retain, nonatomic) NSString              *publish_time;
@property (retain, nonatomic) NSString              *created_time;
@property (retain, nonatomic) NSString              *expires_time;
@property (retain, nonatomic) NSString              *ref;
@property (retain, nonatomic) NSString              *user_message;

@property (retain, nonatomic) id<FBGraphPlace>      place;
@property (retain, nonatomic) NSArray               *tags;
@property (retain, nonatomic) NSArray               *image;
@property (retain, nonatomic) id<FBGraphUser>       from;
@property (retain, nonatomic) NSArray               *likes;
@property (retain, nonatomic) id<FBGraphObject>     application;
@property (retain, nonatomic) NSArray               *comments;

@end