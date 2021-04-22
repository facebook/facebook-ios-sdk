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

#import "FBSDKImageDownloader.h"

#import "FBSDKCoreKitBasicsImport.h"
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
                  completion:(FBSDKImageDownloadBlock)completion
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
                                       if ([response isKindOfClass:[NSHTTPURLResponse class]]
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
