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

#import "FBSDKSuggestedEventsIndexer.h"

#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#import <UIKit/UIKit.h>

#import "FBSDKCoreKit+Internal.h"

#define ViewHierarchyKeyIsInteracted @"is_interacted"
#define ViewHierarchyKeyChildViews   @"childviews"
#define ViewHierarchyKeyScreenName @"screenname"
#define ViewHierarchyKeyView  @"view"

NSString * const OptInEvents = @"production_events";
NSString * const UnconfirmedEvents = @"eligible_for_prediction_events";

static NSMutableArray<NSMutableDictionary<NSString *, id> *> *_viewTrees;
static NSMutableSet<NSString *> *_optInEvents;
static NSMutableSet<NSString *> *_unconfirmedEvents;

@interface FBSDKViewHierarchy ()
+ (NSMutableDictionary<NSString *, id> *)getDetailAttributesOf:(NSObject *)obj withHash:(BOOL)hash;
@end

@implementation FBSDKSuggestedEventsIndexer

+ (void)initialize
{
  _viewTrees = [NSMutableArray array];
  _optInEvents = [NSMutableSet set];
  _unconfirmedEvents = [NSMutableSet set];
}

+ (void)enable
{
  [FBSDKServerConfigurationManager loadServerConfigurationWithCompletionBlock:^(FBSDKServerConfiguration *serverConfiguration, NSError *error) {
    if (error) {
      return;
    }

    NSDictionary<NSString *, id> *suggestedEventsSetting = serverConfiguration.suggestedEventsSetting;
    if ([suggestedEventsSetting isKindOfClass:[NSNull class]] || !suggestedEventsSetting[OptInEvents] || !suggestedEventsSetting[UnconfirmedEvents]) {
      return;
    }

    [_optInEvents addObjectsFromArray:suggestedEventsSetting[OptInEvents]];
    [_unconfirmedEvents addObjectsFromArray:suggestedEventsSetting[UnconfirmedEvents]];

    [FBSDKSuggestedEventsIndexer setup];
  }];
}

+ (void)setup
{
  // won't do the model prediction when there is no opt-in event and unconfirmed event
  if (_optInEvents.count == 0 && _unconfirmedEvents.count == 0) {
    return;
  }
}

@end
