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

@class FBSDKMessengerContext;
@class FBSDKMessengerShareOptions;

/**
 NS_OPTION(NSUInteger, FBSDKMessengerPlatformCapability)
  Used to test the platform capabilities the currently installed Messenger version has
 */
typedef NS_OPTIONS(NSUInteger, FBSDKMessengerPlatformCapability)
{
  FBSDKMessengerPlatformCapabilityNone            = 0,
  FBSDKMessengerPlatformCapabilityOpen            = 1 << 0,
  FBSDKMessengerPlatformCapabilityImage           = 1 << 1,
  FBSDKMessengerPlatformCapabilityAnimatedGIF     = 1 << 2,
  FBSDKMessengerPlatformCapabilityAnimatedWebP    = 1 << 3,
  FBSDKMessengerPlatformCapabilityVideo           = 1 << 4,
  FBSDKMessengerPlatformCapabilityAudio           = 1 << 5,
  FBSDKMessengerPlatformCapabilityRenderAsSticker = 1 << 6,
};

/**

  The FBSDKMessengerSharer is used to share media from apps into Messenger. The underlying
 mechanism used to share data between apps is UIPasteboard

 

 - FacebookAppID must be set in the your app's Info.plist with the Facebook App Id
 - Any existing data in the system's public pasteboard will get overwritten with the shared media
 - Once the data is shared in Messenger, the pasteboard with be cleared
 - The following strings need to be translated in your app:
    NSLocalizedString(@"Get Messenger", @"Alert title telling a user they need to install Messenger")
    NSLocalizedString(@"You are using an older version of Messenger that does not support this feature.", @"Alert message when an old version of messenger is installed")
    NSLocalizedString(@"Not Now", @"Button label when user doesn't want to install Messenger")
    NSLocalizedString(@"Install", @"Button label to install Messenger")
    NSLocalizedString(@"Send", @"Button label for sending a message")
 */
@interface FBSDKMessengerSharer : NSObject

/**
  This method checks the currently installed version of Messenger to see what SDK capabilities it has

 

 Before sharing any media, first use this bitmask to check to see if it can be shared to Messenger

 
- Warning: This method is deprecated as of iOS 9

 - Returns: bitmask of the Messenger capabilities
 */
+ (FBSDKMessengerPlatformCapability)messengerPlatformCapabilities __attribute__ ((deprecated("This is deprecated as of iOS 9. If you use this, you must configure your plist as described in https://developers.facebook.com/docs/ios/ios9")));

/**
  Call this method to open Messenger
 */
+ (void)openMessenger NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an image.

 
- Warning: use shareImage:withOptions: instead

 - Parameter image: The image to be shared in Messenger
 - Parameter metadata: Additional optional information to be sent to Messenger which is sent back to
 the user's app when they reply to an attributed message. This may be nil.
 - Parameter context: The way the content is to be shared in Messenger. If nil, a standard share will take place.

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareImage:(UIImage *)image
      withMetadata:(NSString *)metadata
       withContext:(FBSDKMessengerContext *)context __attribute__ ((deprecated("use use shareImage:withOptions: instead"))) NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an image.

 - Parameter image: The image to be shared in Messenger
 - Parameter options: Additional optional parameters that affect the way the content is shared

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareImage:(UIImage *)image withOptions:(FBSDKMessengerShareOptions *)options NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an animated GIF.

 
- Warning: use shareAnimatedGIF:withOptions: instead

 - Parameter animatedGIFData: The animated GIF to be shared in Messenger
 - Parameter metadata: Additional optional information to be sent to Messenger which is sent back to
 the user's app when they reply to an attributed message. This may be nil.
 - Parameter context: The way the content is to be shared in Messenger. If nil, a standard share will take place.

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareAnimatedGIF:(NSData *)animatedGIFData
            withMetadata:(NSString *)metadata
             withContext:(FBSDKMessengerContext *)context __attribute__ ((deprecated("use use shareAnimatedGIF:withOptions: instead"))) NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an animated GIF.

 - Parameter animatedGIFData: The animated GIF to be shared in Messenger
 - Parameter options: Additional optional parameters that affect the way the content is shared

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareAnimatedGIF:(NSData *)animatedGIFData withOptions:(FBSDKMessengerShareOptions *)options NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an animated GIF.

 
- Warning: use shareAnimatedWebP:withOptions: instead

 - Parameter animatedWebPData: The animated WebP image to be shared in Messenger
 - Parameter metadata: Additional optional information to be sent to Messenger which is sent back to
 the user's app when they reply to an attributed message. This may be nil.
 - Parameter context: The way the content is to be shared in Messenger. If nil, a standard share will take place.

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareAnimatedWebP:(NSData *)animatedWebPData
             withMetadata:(NSString *)metadata
              withContext:(FBSDKMessengerContext *)context __attribute__ ((deprecated("use use shareAnimatedWebP:withOptions: instead"))) NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an animated GIF.

 - Parameter animatedWebPData: The animated WebP image to be shared in Messenger
 - Parameter options: Additional optional parameters that affect the way the content is shared

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareAnimatedWebP:(NSData *)animatedWebPData withOptions:(FBSDKMessengerShareOptions *)options NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share a video.

 
- Warning: use shareVideo:withOptions: instead

 

 Note that there's no way to send an AVAsset between apps, so you may need to
 serialize your AVAsset to a file, and get an NSData representation of the video via
 [NSData dataWithContentsOfFile:filepath];

 - Parameter videoData: The image to be shared in Messenger
 - Parameter metadata: Additional optional information to be sent to Messenger which is sent back to
 the user's app when they reply to an attributed message. This may be nil.
 - Parameter context: The way the content is to be shared in Messenger. If nil, a standard share will take place.

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareVideo:(NSData *)videoData
      withMetadata:(NSString *)metadata
       withContext:(FBSDKMessengerContext *)context __attribute__ ((deprecated("use use shareVideo:withOptions: instead"))) NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share a video.

 

 Note that there's no way to send an AVAsset between apps, so you may need to
 serialize your AVAsset to a file, and get an NSData representation of the video via
 [NSData dataWithContentsOfFile:filepath];

 - Parameter videoData: The image to be shared in Messenger
 - Parameter options: Additional optional parameters that affect the way the content is shared

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareVideo:(NSData *)videoData withOptions:(FBSDKMessengerShareOptions *)options NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an audio file.

 
- Warning: use shareAudio:withOptions: instead

 

 Note that there's no way to send an AVAsset between apps, so you may need to
 serialize your AVAsset to a file, and get an NSData representation of the video via
 [NSData dataWithContentsOfFile:filepath];

 - Parameter audioData: The audio to be shared in Messenger
 - Parameter metadata: Additional optional information to be sent to Messenger

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
*/
+ (void)shareAudio:(NSData *)audioData
      withMetadata:(NSString *)metadata
       withContext:(FBSDKMessengerContext *)context __attribute__ ((deprecated("use use shareAudio:withOptions: instead"))) NS_EXTENSION_UNAVAILABLE_IOS("");

/**
  Call this method to open Messenger and share an audio file.

 

 Note that there's no way to send an AVAsset between apps, so you may need to
 serialize your AVAsset to a file, and get an NSData representation of the video via
 [NSData dataWithContentsOfFile:filepath];

 - Parameter audioData: The audio to be shared in Messenger
 - Parameter options: Additional optional parameters that affect the way the content is shared

 
 If there is not an installed version of Messenger on the device that supports the share, an alert will be presented to notify the user.
 */
+ (void)shareAudio:(NSData *)audioData withOptions:(FBSDKMessengerShareOptions *)options NS_EXTENSION_UNAVAILABLE_IOS("");

@end
