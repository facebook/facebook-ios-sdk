/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKShareExtension.h"

NSString *const FBSDKShareExtensionParamAppID = @"app_id"; // application identifier string
NSString *const FBSDKShareExtensionParamHashtags = @"hashtags"; // array of hashtag strings (max 1)
NSString *const FBSDKShareExtensionParamQuotes = @"quotes"; // array of quote strings (max 1)
NSString *const FBSDKShareExtensionParamOGData = @"og_data"; // dictionary of Open Graph data

NSString *FBSDKShareExtensionInitialText(NSString *appID,
                                         NSString *hashtag,
                                         NSString *jsonString)
{
  NSMutableString *const initialText = [NSMutableString new];

  // Not all versions of our Share Extension supported JSON.
  // Adding this text before the JSON payload supports backward compatibility.
  if (appID.length > 0) {
    [initialText appendString:[NSString stringWithFormat:@"fb-app-id:%@", appID]];
  }
  if (hashtag.length > 0) {
    if (initialText.length > 0) {
      [initialText appendString:@" "];
    }
    [initialText appendString:hashtag];
  }

  if (jsonString.length > 0) {
    [initialText appendString:@"|"]; // JSON start delimiter
    [initialText appendString:jsonString];
  }

  return initialText.length > 0 ? initialText : nil;
}

#endif
