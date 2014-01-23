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

// Wraps an Open Graph object (of type "scrumps:meal") that has just two properties,
// an ID and a URL. The FBGraphObject allows us to create an FBGraphObject instance
// and treat it as an SCOGMeal with typed property accessors.
@protocol SCOGMeal<FBGraphObject>

@property (retain, nonatomic) NSString        *id;
@property (retain, nonatomic) NSString        *url;

@end

// Wraps an Open Graph object (of type "scrumps:eat") with a relationship to a meal,
// as well as properties inherited from FBOpenGraphAction such as "place" and "tags".
@protocol SCOGEatMealAction<FBOpenGraphAction>

@property (retain, nonatomic) id<SCOGMeal>    meal;

@end


