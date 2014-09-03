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

#import "FBUtility.h"

#ifndef __IPHONE_8_0
// Once the SDK builds with the iOS 8.0 or later SDK this block can be removed.

typedef struct {
    NSInteger majorVersion;
    NSInteger minorVersion;
    NSInteger patchVersion;
} NSOperatingSystemVersion;

@interface NSProcessInfo (UIKit8)
@property (readonly) NSOperatingSystemVersion operatingSystemVersion;
@end
#endif/*__IPHONE_8_0*/

NSOperatingSystemVersion FBUtilityGetSystemVersion(void);
BOOL FBUtilityIsSystemVersionIOSVersionOrLater(NSOperatingSystemVersion systemVersion, FBIOSVersion version);
