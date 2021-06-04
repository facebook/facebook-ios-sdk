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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBSDKBackgroundEventLogger.h"

 #import "FBSDKCoreKitBasicsImport.h"
 #import "FBSDKEventLogging.h"

@interface FBSDKBackgroundEventLogger ()

@property (nonnull, nonatomic, readonly) id<FBSDKInfoDictionaryProviding> infoDictionaryProvider;
@property (nonnull, nonatomic, readonly) id<FBSDKEventLogging> eventLogger;

@end

@implementation FBSDKBackgroundEventLogger

- (instancetype)initWithInfoDictionaryProvider:(id<FBSDKInfoDictionaryProviding>)infoDictionaryProvider
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger
{
  if ((self = [super init])) {
    _infoDictionaryProvider = infoDictionaryProvider;
    _eventLogger = eventLogger;
  }
  return self;
}

- (void)logBackgroundRefresStatus:(UIBackgroundRefreshStatus)status
{
  BOOL isNewVersion = [self _isNewBackgroundRefresh];
  switch (status) {
    case UIBackgroundRefreshStatusAvailable:
      [_eventLogger logInternalEvent:@"fb_sdk_background_status_available"
                          parameters:@{@"version" : @(isNewVersion ? 1 : 0)}
                  isImplicitlyLogged:YES];
      break;
    case UIBackgroundRefreshStatusDenied:
      [_eventLogger logInternalEvent:@"fb_sdk_background_status_denied"
                  isImplicitlyLogged:YES];
      break;
    case UIBackgroundRefreshStatusRestricted:
      [_eventLogger logInternalEvent:@"fb_sdk_background_status_restricted"
                  isImplicitlyLogged:YES];
      break;
  }
}

- (BOOL)_isNewBackgroundRefresh
{
  if ([_infoDictionaryProvider objectForInfoDictionaryKey:@"BGTaskSchedulerPermittedIdentifiers"]) {
    return YES;
  }
  return NO;
}

@end

#endif
