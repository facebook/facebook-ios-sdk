/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKGameRequestFrictionlessRecipientCache.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@interface FBSDKGameRequestFrictionlessRecipientCache ()
@property (nonatomic) NSSet<NSString *> *recipientIDs;
@end

@implementation FBSDKGameRequestFrictionlessRecipientCache

#pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init])) {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(_accessTokenDidChangeNotification:)
                                               name:FBSDKAccessTokenDidChangeNotification
                                             object:nil];
    [self _updateCache];
  }
  return self;
}

#pragma mark - Public API

- (BOOL)recipientsAreFrictionless:(id)recipients
{
  if (!recipients) {
    return NO;
  }
  NSArray *recipientIDArray = [FBSDKTypeUtility arrayValue:recipients];
  if (!recipientIDArray && [recipients isKindOfClass:NSString.class]) {
    recipientIDArray = [recipients componentsSeparatedByString:@","];
  }
  if (recipientIDArray) {
    NSSet<NSString *> *recipientIDs = [[NSSet alloc] initWithArray:recipientIDArray];
    return [recipientIDs isSubsetOfSet:_recipientIDs];
  } else {
    return NO;
  }
}

- (void)updateWithResults:(NSDictionary<NSString *, id> *)results
{
  if ([FBSDKTypeUtility boolValue:results[@"updated_frictionless"]]) {
    [self _updateCache];
  }
}

- (void)_accessTokenDidChangeNotification:(NSNotification *)notification
{
  if (![notification.userInfo[FBSDKAccessTokenDidChangeUserIDKey] boolValue]) {
    return;
  }
  _recipientIDs = nil;
  [self _updateCache];
}

- (void)_updateCache
{
  if (!FBSDKAccessToken.currentAccessToken) {
    _recipientIDs = nil;
    return;
  }
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/apprequestformerrecipients"
                                                                 parameters:@{@"fields" : @""}
                                                                      flags:(FBSDKGraphRequestFlagDoNotInvalidateTokenOnError
                                                                        | FBSDKGraphRequestFlagDisableErrorRecovery)];
  [request startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
    if (!error) {
      NSArray *items = [FBSDKTypeUtility arrayValue:result[@"data"]];
      NSArray *recipientIDs = [items valueForKey:@"recipient_id"];
      self->_recipientIDs = [[NSSet alloc] initWithArray:recipientIDs];
    }
  }];
}

@end

#endif
