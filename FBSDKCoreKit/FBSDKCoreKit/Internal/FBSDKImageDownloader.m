/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKImageDownloader.h"

#import "NSURLSession+Protocols.h"

static NSString *const kImageDirectory = @"fbsdkimages";
static NSString *const kCachedResponseUserInfoKeyTimestamp = @"timestamp";

@interface FBSDKImageDownloader ()

@property (nonatomic, strong) id<FBSDKSessionProviding> sessionProvider;
@property (nonatomic, strong) NSURLCache *urlCache;

@end

@implementation FBSDKImageDownloader

+ (FBSDKImageDownloader *)sharedInstance
{
  static FBSDKImageDownloader *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [FBSDKImageDownloader new];
  });
  return instance;
}

- (instancetype)init
{
  return [self initWithSessionProvider:NSURLSession.sharedSession];
}

- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider
{
  if ((self = [super init])) {
  #if TARGET_OS_MACCATALYST
    _urlCache = [[NSURLCache alloc] initWithMemoryCapacity:1024 * 1024 * 8
                                              diskCapacity:1024 * 1024 * 100
                                              directoryURL:[NSURL URLWithString:kImageDirectory]];
  #else
    _urlCache = [[NSURLCache alloc] initWithMemoryCapacity:1024 * 1024 * 8
                                              diskCapacity:1024 * 1024 * 100
                                                  diskPath:kImageDirectory];
  #endif
    _sessionProvider = sessionProvider;
  }
  return self;
}

- (void)removeAll
{
  [self.urlCache removeAllCachedResponses];
}

- (void)downloadImageWithURL:(NSURL *)url
                         ttl:(NSTimeInterval)ttl
                  completion:(nullable FBSDKImageDownloadBlock)completion
{
  NSURLRequest *request = [NSURLRequest requestWithURL:url];
  NSCachedURLResponse *cachedResponse = [self.urlCache cachedResponseForRequest:request];
  NSDate *modificationDate = cachedResponse.userInfo[kCachedResponseUserInfoKeyTimestamp];
  BOOL isExpired = ([[modificationDate dateByAddingTimeInterval:ttl] compare:[NSDate date]] == NSOrderedAscending);

  void (^completionWrapper)(NSCachedURLResponse *) = ^(NSCachedURLResponse *responseData) {
    if (completion != NULL) {
      UIImage *image = [UIImage imageWithData:responseData.data];
      completion(image);
    }
  };

  if (cachedResponse == nil || isExpired) {
    id<FBSDKSessionDataTask> task = [self.sessionProvider dataTaskWithRequest:request
                                                            completionHandler:
                                     ^(NSData *data, NSURLResponse *response, NSError *error) {
                                       if ([response isKindOfClass:NSHTTPURLResponse.class]
                                           && ((NSHTTPURLResponse *)response).statusCode == 200
                                           && error == nil
                                           && data != nil) {
                                         NSCachedURLResponse *responseToCache =
                                         [[NSCachedURLResponse alloc] initWithResponse:response
                                                                                  data:data
                                                                              userInfo:@{ kCachedResponseUserInfoKeyTimestamp : [NSDate date] }
                                                                         storagePolicy:NSURLCacheStorageAllowed];
                                         [self->_urlCache storeCachedResponse:responseToCache forRequest:request];
                                         completionWrapper(responseToCache);
                                       } else if (completion != NULL) {
                                         completion(nil);
                                       }
                                     }];
    [task resume];
  } else {
    completionWrapper(cachedResponse);
  }
}

@end
