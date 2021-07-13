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
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(GamingImageUploaderConfiguration)
@interface FBSDKGamingImageUploaderConfiguration : NSObject

@property (nonatomic, strong, readonly, nonnull) UIImage *image;
@property (nonatomic, strong, readonly, nullable) NSString *caption;
@property (nonatomic, assign, readonly) BOOL shouldLaunchMediaDialog;

- (instancetype _Nonnull )init NS_SWIFT_UNAVAILABLE("Should not create instances of this class");

/**
 A model for Gaming image upload content to be shared.

 @param image the image that will be shared.
 @param caption and optional caption that will appear along side the image on Facebook.
 @param shouldLaunchMediaDialog whether or not to open the media dialog on
  Facebook when the upload completes.
 */
- (instancetype)initWithImage:(UIImage * _Nonnull)image
                      caption:(NSString * _Nullable)caption
      shouldLaunchMediaDialog:(BOOL)shouldLaunchMediaDialog;

@end

NS_ASSUME_NONNULL_END
