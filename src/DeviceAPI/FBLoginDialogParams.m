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

#import "FBLoginDialogParams.h"

#import "FBAppBridge.h"
#import "FBDialogsParams+Internal.h"
#import "FBSession+Internal.h"
#import "FBSettings+Internal.h"

static NSString *const SSOWritePrivacyPublic = @"EVERYONE";
static NSString *const SSOWritePrivacyFriends = @"ALL_FRIENDS";
static NSString *const SSOWritePrivacyOnlyMe = @"SELF";

@implementation FBLoginDialogParams

- (void)dealloc
{
    [_permissions release];
    [super dealloc];
}

- (NSDictionary *)dictionaryMethodArgs
{
    NSMutableDictionary *args = [NSMutableDictionary dictionary];

    NSString *permStr = [self.permissions componentsJoinedByString:@","];
    if (permStr && permStr.length) {
        args[@"permissions"] = permStr;
    } else {
        args[@"permissions"] = @"basic_info";
    }

    // This prevents the None case from being sent to the Facebook application
    // which doesn't support it.
    if (self.writePrivacy) {
        NSString *writePrivacyString = nil;
        switch (self.writePrivacy) {
            case FBSessionDefaultAudienceOnlyMe:
                writePrivacyString = SSOWritePrivacyOnlyMe;
                break;

            case FBSessionDefaultAudienceFriends:
                writePrivacyString = SSOWritePrivacyFriends;
                break;

            case FBSessionDefaultAudienceEveryone:
                writePrivacyString = SSOWritePrivacyPublic;
                break;

            default:
                // This will most likely result in the Facebook application
                // denying SSO.
                writePrivacyString = @"NONE";
                break;
        }
        args[@"write_privacy"] = writePrivacyString;
    }

    // to support token-import we always try the refresh flow. It will fallback to the permissions
    // dialog if the app is not installed or does not have the necessary permissions
    args[@"is_refresh_only"] = @"1";

    return args;
}

@end
