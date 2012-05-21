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
#import "FBGraphObject.h"

/*!
 @protocol
 
 @abstract
 A graph accessor protocol used to access location information
 
 @discussion
 Represents commonly used properties of a Facebook place object, may be used to access an NSDictionary object for which
 the graphObjectWrappingDictionary method has been called; graph accessors enable typed access to Facebook graph objects
 */
@protocol FBGraphLocation<FBGraphObject>

/*!
 @property
 @abstract Typed access to location's street
 */
@property (retain, nonatomic) NSString *street;

/*!
 @property
 @abstract Typed access to location's city
 */
@property (retain, nonatomic) NSString *city;

/*!
 @property
 @abstract Typed access to location's state
 */
@property (retain, nonatomic) NSString *state;

/*!
 @property
 @abstract Typed access to location's country
 */
@property (retain, nonatomic) NSString *country;

/*!
 @property
 @abstract Typed access to location's zip
 */
@property (retain, nonatomic) NSString *zip;

/*!
 @property
 @abstract Typed access to location's latitude
 */
@property (retain, nonatomic) NSNumber *latitude; 

/*!
 @property
 @abstract Typed access to location's longitude
 */
@property (retain, nonatomic) NSNumber *longitude;

@end