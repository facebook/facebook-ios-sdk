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
#import "FBUtility.h"

// Given a byte array, returns an NSString containing those bytes encoded in Base64 encoding.
extern NSString *FBEncodeBase64(NSData *data);

// Given a Base64-encoded string, decodes the string and returns an
// NSData containing the decoded bytes.
extern NSData *FBDecodeBase64(NSString *base64);
