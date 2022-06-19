// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

@import FBSDKLoginKit;

extern NSString *const FacebookBaseDomain;

NSString *AsciiString(NSString *string);
NSString *StringForJSONObject(id JSONObject);
void SetAppSecret(NSString *appSecret);
NSString *GetAppSecret(void);
