/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 Web Share Block
 */

NS_ASSUME_NONNULL_BEGIN

typedef void (^ FBSDKWebPhotoContentBlock)(BOOL, NSString *, NSDictionary<NSString *, id> *)
NS_SWIFT_NAME(WebPhotoContentBlock);

NS_SWIFT_NAME(ShareUtilityProtocol)
@protocol FBSDKShareUtility

+ (nullable NSDictionary<NSString *, id> *)feedShareDictionaryForContent:(id<FBSDKSharingContent>)content;

+ (void)buildAsyncWebPhotoContent:(FBSDKSharePhotoContent *)content
                completionHandler:(FBSDKWebPhotoContentBlock)completion;

+ (BOOL)buildWebShareContent:(id<FBSDKSharingContent>)content
                  methodName:(NSString *_Nonnull *_Nullable)methodNameRef
                  parameters:(NSDictionary<NSString *, id> *_Nonnull *_Nullable)parametersRef
                       error:(NSError *_Nullable *)errorRef;

+ (nullable NSString *)hashtagStringFromHashtag:(nullable FBSDKHashtag *)hashtag;

+ (NSDictionary<NSString *, id> *)parametersForShareContent:(id<FBSDKSharingContent>)shareContent
                                              bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
                                      shouldFailOnDataError:(BOOL)shouldFailOnDataError;

+ (void)testShareContent:(id<FBSDKSharingContent>)shareContent
           containsMedia:(nullable BOOL *)containsMediaRef
          containsPhotos:(BOOL *)containsPhotosRef
          containsVideos:(BOOL *)containsVideosRef;

+ (BOOL)shareMediaContentContainsPhotosAndVideos:(FBSDKShareMediaContent *)shareMediaContent;

+ (BOOL)validateShareContent:(id<FBSDKSharingContent>)shareContent
               bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
                       error:(NSError *_Nullable *)errorRef;

@end

NS_ASSUME_NONNULL_END
