// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "GamingPayloadDelegate.h"

#ifndef RELEASED_SDK_ONLY
@implementation GamingPayloadDelegate

- (void)parsedGameRequestURLContaining:(FBSDKGamingPayload *)payload
                         gameRequestID:(NSString *_Nonnull)gameRequestID
{
  ConsoleLog(@"Parsed Gaming payload returned the following payload: %@", payload);
  ConsoleLog(@"Parsed Gaming payload returned the following game request ID: %@", gameRequestID);
}

- (void)parsedTournamentURLContaining:(FBSDKGamingPayload *)payload
                         tournamentID:(NSString *_Nonnull)tournamentiD
{
  ConsoleLog(@"Parsed Gaming payload returned the following payload: %@", payload);
  ConsoleLog(@"Parsed Gaming payload returned the following game request ID: %@", tournamentiD);
}

@end
#endif
