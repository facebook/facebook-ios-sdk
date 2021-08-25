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

/**
 Web Share Block
 */
typedef void (^FBSDKWebPhotoContentBlock)(BOOL, NSString *, NSDictionary<NSString *, id> *)
NS_SWIFT_NAME(WebPhotoContentBlock);

NS_SWIFT_NAME(ShareUtilityProtocol)
@protocol FBSDKShareUtility

+ (NSDictionary<NSString *, id> *)feedShareDictionaryForContent:(id<FBSDKSharingContent>)content;

+ (void)buildAsyncWebPhotoContent:(FBSDKSharePhotoContent *)content
                completionHandler:(FBSDKWebPhotoContentBlock)completion;

+ (BOOL)buildWebShareContent:(id<FBSDKSharingContent>)content
                  methodName:(NSString *__autoreleasing *)methodNameRef
                  parameters:(NSDictionary<NSString *, id> *__autoreleasing *)parametersRef
                       error:(NSError *__autoreleasing *)errorRef;

+ (NSString *)hashtagStringFromHashtag:(FBSDKHashtag *)hashtag;

+ (NSDictionary<NSString *, id> *)parametersForShareContent:(id<FBSDKSharingContent>)shareContent
                                              bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
                                      shouldFailOnDataError:(BOOL)shouldFailOnDataError;

+ (void)testShareContent:(id<FBSDKSharingContent>)shareContent
           containsMedia:(BOOL *)containsMediaRef
          containsPhotos:(BOOL *)containsPhotosRef
          containsVideos:(BOOL *)containsVideosRef;

+ (BOOL)shareMediaContentContainsPhotosAndVideos:(FBSDKShareMediaContent *)shareMediaContent;

+ (BOOL)validateShareContent:(id<FBSDKSharingContent>)shareContent
               bridgeOptions:(FBSDKShareBridgeOptions)bridgeOptions
                       error:(NSError *__autoreleasing *)errorRef;

@end
