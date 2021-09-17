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

@import FacebookGamingServices;

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKVideoUploaderDelegate;
@protocol FBSDKGraphRequestFactory;

@interface FBSDKVideoUploader (Testing)

@property (nonatomic, copy) NSNumber *uploadSessionID;

- (void)start;

- (instancetype)initWithVideoName:(NSString *)videoName
                        videoSize:(NSUInteger)videoSize
                       parameters:(NSDictionary<NSString *, id> *)parameters
                         delegate:(id<FBSDKVideoUploaderDelegate>)delegate
                  graphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
NS_SWIFT_NAME(init(videoName:videoSize:parameters:delegate:graphRequestFactory:));

- (void)_postFinishRequest;

- (void)_startTransferRequestWithOffsetDictionary:(NSDictionary<NSString *, id> *)offsetDictionary;

- (NSNumberFormatter *)numberFormatter;

- (NSDictionary<NSString *, id> *)_extractOffsetsFromResultDictionary:(id)result;

- (void)_startTransferRequestWithNewOffset:(NSDictionary<NSString *, id> *)offsetDictionary
                                                data:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
