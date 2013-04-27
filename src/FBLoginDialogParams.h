/*
 * Copyright 2010-present Facebook.
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
#import "FBDialogsParams.h"
#import "FBSession.h"

@interface FBLoginDialogParams : FBDialogsParams

/*!
 Permissions being requested. Ex "basic_info,email"
 */
@property (nonatomic, copy) NSArray *permissions;

/*!
 When requesting publish permissions, this must be set to a value other than FBSessionDefaultAudienceNone.
 If not requesting publish permissions, leave this property unset.
 */
@property (nonatomic, assign) FBSessionDefaultAudience writePrivacy;

/*!
 When requesting for the access token to be renewed, set this property to YES.
 */
@property BOOL isRefreshOnly;

@end
