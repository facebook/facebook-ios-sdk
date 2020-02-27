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

#import "FBSDKGamingImageUploader.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKGamingImageUploaderConfiguration.h"
#import "FBSDKGamingServiceController.h"

@interface FBSDKGamingImageUploader ()
@end

@implementation FBSDKGamingImageUploader

+ (void)uploadImageWithConfiguration:(FBSDKGamingImageUploaderConfiguration * _Nonnull)configuration
                andCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  if ([FBSDKAccessToken currentAccessToken] == nil) {
    completionHandler(false, [FBSDKError
                              errorWithCode:FBSDKErrorAccessTokenRequired
                              message:@"A valid access token is required to upload Images"]);

    return;
  }

  if (configuration.image == nil) {
    completionHandler(false, [FBSDKError
                              errorWithCode:FBSDKErrorInvalidArgument
                              message:@"Attempting to upload a nil image"]);

    return;
  }

  [[[FBSDKGraphRequest alloc]
    initWithGraphPath:@"me/photos"
    parameters:@{
      @"caption": configuration.caption ?: @"",
      @"picture": UIImagePNGRepresentation(configuration.image)
    }
    HTTPMethod:FBSDKHTTPMethodPOST]
   startWithCompletionHandler:^(FBSDKGraphRequestConnection * _Nullable connection, id  _Nullable result, NSError * _Nullable error) {
    if (error || !result) {
      completionHandler(false, [FBSDKError
                                errorWithCode:FBSDKErrorGraphRequestGraphAPI
                                message:@"Image upload failed"
                                underlyingError:error]);
      return;
    }

    if (!configuration.shouldLaunchMediaDialog) {
      completionHandler(true, nil);
      return;
    }

    FBSDKGamingServiceController *const controller =
    [[FBSDKGamingServiceController alloc]
     initWithServiceType:FBSDKGamingServiceTypeMediaAsset
     completionHandler:completionHandler];

    [controller callWithArgument:result[@"id"]];
  }];
}

@end
