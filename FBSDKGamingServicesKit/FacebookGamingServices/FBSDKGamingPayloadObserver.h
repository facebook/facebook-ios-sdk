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

#import <Foundation/Foundation.h>

@class FBSDKGamingPayload;

NS_SWIFT_NAME(GamingPayloadDelegate)
@protocol FBSDKGamingPayloadDelegate

// MARK: Game Request
@optional
- (void)updatedURLContaining:(FBSDKGamingPayload* _Nonnull)payload
DEPRECATED_MSG_ATTRIBUTE("This method is deprecated and will be removed in the next major release. Please use `parsedGameRequestURLContaining:gameRequestID:` instead");

/**
  Delegate method will be triggered when a `GamingPayloadObserver` parses a url with a payload and game request ID
 @param payload The payload recieved in the url
 @param gameRequestID The game request ID recieved in the url
 */
@optional
- (void)parsedGameRequestURLContaining:(FBSDKGamingPayload* _Nonnull)payload gameRequestID:(NSString* _Nonnull)gameRequestID;

/**
 Delegate method will be triggered when a `GamingPayloadObserver` parses a gaming context url with a payload and game context token ID. The current gaming context will be update with the context ID.
 @param payload The payload recieved in the url
 */
@optional
- (void)parsedGamingContextURLContaining:(FBSDKGamingPayload* _Nonnull)payload;

@end


NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GamingPayloadObserver)
@interface FBSDKGamingPayloadObserver : NSObject

@property (nonatomic, weak) id<FBSDKGamingPayloadDelegate> delegate;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)shared DEPRECATED_MSG_ATTRIBUTE("The shared instance of the gaming payload observer is deprecated and will be removed in the next major release. Please create and use instances of this object directly as needed.");

- (instancetype)initWithDelegate:(id<FBSDKGamingPayloadDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
