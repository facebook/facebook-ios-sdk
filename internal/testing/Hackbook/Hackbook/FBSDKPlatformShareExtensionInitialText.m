// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "FBSDKPlatformShareExtension.h"

// Shameless fork of internal ShareKit function FBSDKShareExtensionInitialText
NSString *HackbookShareExtensionInitialText(NSString *appID,
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

NSString *FBSDKPlatformShareExtensionInitialText(NSString *appID,
                                                 NSString *hashtag,
                                                 NSString *quote)
{
  NSMutableDictionary<NSString *, id> *const parameters = [NSMutableDictionary new];
  if (appID.length > 0) {
    parameters[@"app_id"] = appID;
  }
  if (hashtag.length > 0) {
    parameters[@"hashtags"] = @[hashtag];
  }
  if (quote.length > 0) {
    parameters[@"quotes"] = @[quote];
  }
  NSData *const data = (parameters.count > 0 && [NSJSONSerialization isValidJSONObject:parameters]
    ? [NSJSONSerialization dataWithJSONObject:parameters options:0 error:NULL]
    : nil);
  NSString *const jsonString = (data
    ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
    : nil);
  return HackbookShareExtensionInitialText(appID, hashtag, jsonString);
}
