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

#import "FBSDKAtePublisherFactory.h"

#import "FBSDKAppEventsAtePublisher.h"
#import "FBSDKDataPersisting.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKAtePublisherFactory ()

@property (nonnull, nonatomic, readonly) id<FBSDKGraphRequestProviding> graphRequestFactory;
@property (nonnull, nonatomic, readonly) id<FBSDKSettings> settings;
@property (nonnull, nonatomic, readonly) id<FBSDKDataPersisting> store;

@end

@implementation FBSDKAtePublisherFactory

- (instancetype)initWithStore:(id<FBSDKDataPersisting>)store
          graphRequestFactory:(id<FBSDKGraphRequestProviding>)graphRequestFactory
                     settings:(id<FBSDKSettings>)settings
{
  if ((self = [super init])) {
    _store = store;
    _graphRequestFactory = graphRequestFactory;
    _settings = settings;
  }
  return self;
}

- (nullable id<FBSDKAtePublishing>)createPublisherWithAppID:(NSString *)appID
{
  return [[FBSDKAppEventsAtePublisher alloc] initWithAppIdentifier:appID
                                               graphRequestFactory:self.graphRequestFactory
                                                          settings:self.settings
                                                             store:self.store];
}

@end

NS_ASSUME_NONNULL_END
