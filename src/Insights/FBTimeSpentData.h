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

// Class to encapsulate persisting of time spent data collected by [FBAppEvents activateApp].  The activate app App Event is
// logged when restore: is called with sufficient time since the last deactivation.
@interface FBTimeSpentData : NSObject

+ (void)suspend;
+ (void)restore:(BOOL)calledFromActivateApp;

@end
