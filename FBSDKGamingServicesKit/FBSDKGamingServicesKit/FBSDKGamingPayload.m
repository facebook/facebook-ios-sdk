// (c) Facebook, Inc. and its affiliates. Confidential and proprietary.

#import "FBSDKGamingPayload.h"

#import "FBSDKCoreKitInternalImport.h"

NSString *const kGamingPayload = @"payload";
NSString *const kGamingPayloadGameRequestID = @"game_request_id";

@implementation FBSDKGamingPayload : NSObject

- (instancetype)initWithURL:(FBSDKURL *_Nonnull)url
{
  if (self = [super init]) {
    _URL = url;
  }
  return self;
}

- (NSString *)gameRequestID
{
  if (self.URL) {
    return self.URL.appLinkExtras[kGamingPayloadGameRequestID];
  }
  return @"";
}

- (NSString *)payload
{
  if (self.URL) {
    return self.URL.appLinkExtras[kGamingPayload];
  }
  return @"";
}

@end
