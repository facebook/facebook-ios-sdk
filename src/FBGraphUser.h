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

/*!
 @protocol 
 
 @abstract
 A graph accessor protocol used to access facebook user information
 
 @discussion
 Represents commonly used properties of a Facebook User object, may be used to access an
 NSDictionary object for which the treatAsGraphObject method has been called; graph accessors 
 enable typed access to Facebook graph objects
 */
@protocol FBGraphUser<FBGraphObject>

/*!
 @property
 @abstract Typed access to user's id
 */
@property (retain, nonatomic) NSString *id;

/*!
 @property
 @abstract Typed access to user's name
 */
@property (retain, nonatomic) NSString *name;

/*!
 @property
 @abstract Typed access to user's first name
 */
@property (retain, nonatomic) NSString *first_name;

/*!
 @property
 @abstract Typed access to user's middle name
 */
@property (retain, nonatomic) NSString *middle_name;

/*!
 @property
 @abstract Typed access to user's last name
 */
@property (retain, nonatomic) NSString *last_name;

/*!
 @property 
 @abstract Typed access to user's link
 */
@property (retain, nonatomic) NSString *link;

/*!
 @property 
 @abstract Typed access to user's username
 */
@property (retain, nonatomic) NSString *username;

/*!
 @property 
 @abstract Typed access to user's birthday
 */
@property (retain, nonatomic) NSString *birthday;

/*!
 @property 
 @abstract Typed access to user's location
 */
@property (retain, nonatomic) id<FBGraphLocation> location;

@end