// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "FBSDKMessengerApplicationStateManager.h"
#import "FBSDKMessengerURLHandler.h"
#import "FBSDKMessengerURLHandlerCancelContext.h"
#import "FBSDKMessengerURLHandlerOpenFromComposerContext+Internal.h"
#import "FBSDKMessengerURLHandlerReplyContext+Internal.h"
#import "FBSDKMessengerUtils.h"

static NSString *const kMessengerBundleProd = @"com.facebook.Messenger";
static NSString *const kMessengerBundleDevelopment = @"com.facebook.MessengerDev";
static NSString *const kMessengerBundleInHouse = @"com.facebook.OrcaDevelopment";

// Hosts
static NSString *const kMessengerHostReply = @"messenger-share-reply";
static NSString *const kMessengerHostOpenFromComposer = @"messenger-share-open-from-composer";
static NSString *const kMessengerHostCancel = @"messenger-share-cancel";

// extras key names
static NSString *const kMessengerExtrasMetadata = @"metadata";
static NSString *const kMessengerExtrasIsContentPlatform = @"is_messenger_content_platform";
static NSString *const kMessengerExtrasContext = @"context";
static NSString *const kMessengerExtrasOtherAppIds = @"other_user_app_scoped_ids";

@implementation FBSDKMessengerURLHandler

#pragma mark - Public

- (BOOL)canOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
  if (![sourceApplication isEqualToString:kMessengerBundleProd] &&
      ![sourceApplication isEqualToString:kMessengerBundleInHouse] &&
      ![sourceApplication isEqualToString:kMessengerBundleDevelopment]) {
    return NO;
  }

  if (![url.scheme isEqualToString:FBSDKMessengerDefaultAppIDURLScheme()]) {
    return NO;
  }

  NSDictionary *appLinksDictionary = [self _appLinksDictionary:url];
  NSDictionary *extras = appLinksDictionary[@"extras"];
  BOOL isMessengerPlatform = [extras[kMessengerExtrasIsContentPlatform] boolValue];
  if (!isMessengerPlatform) {
    return NO;
  }

  NSString *context = extras[kMessengerExtrasContext];
  if (![context isEqualToString:kMessengerHostReply] &&
      ![context isEqualToString:kMessengerHostOpenFromComposer] &&
      ![context isEqualToString:kMessengerHostCancel]) {
    return NO;
  }

  return YES;
}

- (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
  if (![self canOpenURL:url sourceApplication:sourceApplication]) {
    return NO;
  }

  NSDictionary *appLinksDictionary = [self _appLinksDictionary:url];
  NSDictionary *extras = appLinksDictionary[@"extras"];
  NSString *context = extras[kMessengerExtrasContext];

  if ([context isEqualToString:kMessengerHostReply]) {
    [self _processReply:extras];
    return YES;
  } else if ([context isEqualToString:kMessengerHostOpenFromComposer]) {
    [self _processOpenFromComposer:extras];
    return YES;
  } else if ([context isEqualToString:kMessengerHostCancel]) {
    [self _processCancel];
    return YES;
  }

  return NO;
}

#pragma mark - Private

- (NSDictionary *)_appLinksDictionary:(NSURL *)url
{
  NSError *error;
  NSString *json = [self _appLinkParamsForURL:url];
  NSData *jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];

  if (jsonData) {
    return [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
  }

  return nil;
}

- (NSString *)_appLinkParamsForURL:(NSURL *)url
{
  NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  NSString *appLinkParams = [self _valueForKey:@"al_applink_data" fromComponents:urlComponents];
  return appLinkParams;
}

- (NSSet *)_appIDsForExtras:(NSDictionary *)extras
{
  NSString *otherAppIds = extras[kMessengerExtrasOtherAppIds];
  NSSet *otherAppIdsSet = [NSSet setWithArray:[otherAppIds componentsSeparatedByString:@","]];
  return otherAppIdsSet;
}

- (void)_processReply:(NSDictionary *)extras
{
  NSString *metadata = extras[kMessengerExtrasMetadata];
  NSSet *otherAppIdsSet = [self _appIDsForExtras:extras];
  FBSDKMessengerURLHandlerReplyContext *context = [[FBSDKMessengerURLHandlerReplyContext alloc] initWithMetadata:metadata
                                                                                                        userIDs:otherAppIdsSet];

  [FBSDKMessengerApplicationStateManager sharedInstance].currentContext = context;
  if ([_delegate respondsToSelector:@selector(messengerURLHandler:didHandleReplyWithContext:)]) {
    [_delegate messengerURLHandler:self didHandleReplyWithContext:context];
  }
}

- (void)_processOpenFromComposer:(NSDictionary *)extras
{
  NSString *metadata = extras[kMessengerExtrasMetadata];
  NSSet *otherAppIdsSet = [self _appIDsForExtras:extras];
  FBSDKMessengerURLHandlerOpenFromComposerContext *context = [[FBSDKMessengerURLHandlerOpenFromComposerContext alloc] initWithMetadata:metadata
                                                                                                                               userIDs:otherAppIdsSet];
  [FBSDKMessengerApplicationStateManager sharedInstance].currentContext = context;
  if ([_delegate respondsToSelector:@selector(messengerURLHandler:didHandleOpenFromComposerWithContext:)]) {
    [_delegate messengerURLHandler:self didHandleOpenFromComposerWithContext:context];
  }
}

- (void)_processCancel
{
  FBSDKMessengerURLHandlerCancelContext *context = [[FBSDKMessengerURLHandlerCancelContext alloc] init];
  [FBSDKMessengerApplicationStateManager sharedInstance].currentContext = context;
  if ([_delegate respondsToSelector:@selector(messengerURLHandler:didHandleCancelWithContext:)]) {
    [_delegate messengerURLHandler:self didHandleCancelWithContext:context];
  }
}

- (NSString *)_valueForKey:(NSString *)key fromComponents:(NSURLComponents *)urlComponents
{
  if (!key) {
    return nil;
  }

  if ([urlComponents respondsToSelector:@selector(queryItems)]) {
      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name=%@", key];
      NSURLQueryItem *queryItem = [[urlComponents.queryItems filteredArrayUsingPredicate:predicate] firstObject];
      return queryItem.value;
  } else {
    // IOS 7
    for (NSString *param in [urlComponents.query componentsSeparatedByString:@"&"]) {
      NSArray *keyAndValue = [param componentsSeparatedByString:@"="];
      if (keyAndValue.count < 2) {
        continue;
      }
      if ([keyAndValue[0] isEqualToString:key]) {
        return [[keyAndValue[1]
                 stringByReplacingOccurrencesOfString:@"+" withString:@" "]
                stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      }
    }
  }
  return nil;
}

@end
