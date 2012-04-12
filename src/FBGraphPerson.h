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
#import "FBGraphLocation.h"
#import "FBGraphObject.h"

// FBGraphPerson protocol (graph accessor)
//
// Summary:
// represents commonly used properties of a Facebook place object, may be used to access an 
// NSDictionary object for which the treatAsGraphObject method has been called; graph accessors 
// enable typed access to Facebook graph objects
@protocol FBGraphPerson<FBGraphObject>

@property (copy, nonatomic) NSString *id;
@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *first_name;
@property (copy, nonatomic) NSString *last_name;
@property (copy, nonatomic) NSString *link;
@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *birthday;
@property (retain, nonatomic) NSDictionary<FBGraphLocation> *location;

@end