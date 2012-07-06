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

#import <UIKit/UIKit.h>

@class FBSession;

// FBSample logic
// This view presents a simple UI with a Login button that will log the user in to Facebook,
// using SSO if possible, otherwise using the web dialog UI.
@interface SCLoginViewController : UIViewController

// FBSample logic
// This method should be called to indicate that a login which was in progress has
// resulted in a failure.
- (void)loginFailed;

@end
