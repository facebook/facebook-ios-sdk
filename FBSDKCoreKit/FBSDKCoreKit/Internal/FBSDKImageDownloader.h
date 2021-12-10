/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Describes the callback for downloadImageWithURL:ttl:completion:.
 @param image the optional image returned
 */
typedef void (^ FBSDKImageDownloadBlock)(UIImage *_Nullable image)
NS_SWIFT_NAME(ImageDownloadBlock);

/*
  simple class to manage image downloads

 this class is not smart enough to dedupe identical requests in flight.
 */
NS_SWIFT_NAME(ImageDownloader)
@interface FBSDKImageDownloader : NSObject

@property (class, nonatomic, readonly, strong) FBSDKImageDownloader *sharedInstance;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/*
  download an image or retrieve it from cache
 @param url the url to download
 @param ttl the amount of time (in seconds) that using a cached version is acceptable.
 @param completion the callback with the image - for simplicity nil is returned rather than surfacing an error.
 */
- (void)downloadImageWithURL:(NSURL *)url
                         ttl:(NSTimeInterval)ttl
                  completion:(nullable FBSDKImageDownloadBlock)completion;

- (void)removeAll;

@end

NS_ASSUME_NONNULL_END
