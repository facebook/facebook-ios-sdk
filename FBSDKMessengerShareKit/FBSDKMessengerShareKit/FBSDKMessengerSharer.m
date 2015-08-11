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

#import "FBSDKMessengerSharer.h"

#import "FBSDKMessengerApplicationStateManager.h"
#import "FBSDKMessengerContext+Internal.h"
#import "FBSDKMessengerInstallMessengerAlertPresenter.h"
#import "FBSDKMessengerInvalidOptionsAlertPresenter.h"
#import "FBSDKMessengerShareOptions.h"
#import "FBSDKMessengerURLHandlerReplyContext.h"
#import "FBSDKMessengerUtils.h"

// This SDK version, which is synchronized with Messenger. This is incremented with every SDK release
static NSString *const kFBSDKMessengerShareKitSendVersion = @"20150714";
// URLs to talk to messenger
static NSString *const kMessengerPlatformPrefix = @"fb-messenger-platform";

// Messenger actions
static NSString *const kMessengerActionBroadcast = @"broadcast";

// Pasteboard types
static NSString *const kMessengerPasteboardTypeVideo = @"com.messenger.video";
static NSString *const kMessengerPasteboardTypeImage = @"com.messenger.image";
static NSString *const kMessengerPasteboardTypeAudio = @"com.messenger.audio";

static NSString *const kMessengerPlatformMetadataParamName = @"metadata";
static NSString *const kMessengerPlatformSourceURLParamName = @"sourceURL";
static NSString *const kMessengerPlatformRenderAsStickerParamName = @"render_as_sticker";
static NSString *const kMessengerPlatformRenderAsStickerParamValue = @"1";

static NSString *const kMessengerPlatformQueryString = @"pasteboard_type=%@&app_id=%@&version=%@";

static NSString *URLSchemeForVersion(NSString *version)
{
  return [NSString stringWithFormat:@"%@-%@", kMessengerPlatformPrefix, version];
}

@implementation FBSDKMessengerSharer

// Returns string representing the version of messenger that's currently installed
+ (NSString *)currentlyInstalledMessengerVersion
{
  // Manually check every single version of the SDK that's been installed by trying
  // canOpenURL until we find one that matches
  NSDictionary *platformCapabilities = [FBSDKMessengerSharer messengerVersionCapabilities];

  NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCompare:)];
  NSArray* sortedReleases = [[platformCapabilities allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

  for (NSString *version in sortedReleases) {
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.scheme = URLSchemeForVersion(version);
    if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
      return version;
    }
  }

  return nil;
}

+ (NSDictionary *)messengerVersionCapabilities
{
  static NSDictionary *messengerShareKitVersionCapabilities = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    FBSDKMessengerPlatformCapability v2015_01_28 = (FBSDKMessengerPlatformCapabilityOpen |
                                                    FBSDKMessengerPlatformCapabilityImage |
                                                    FBSDKMessengerPlatformCapabilityVideo |
                                                    FBSDKMessengerPlatformCapabilityAnimatedGIF);

    FBSDKMessengerPlatformCapability v2015_02_18 = (v2015_01_28 | FBSDKMessengerPlatformCapabilityAudio);

    FBSDKMessengerPlatformCapability v2015_03_05 = (v2015_02_18 | FBSDKMessengerPlatformCapabilityAnimatedWebP);

    FBSDKMessengerPlatformCapability v2015_07_14 = (v2015_03_05 | FBSDKMessengerPlatformCapabilityRenderAsSticker);

    messengerShareKitVersionCapabilities = @{
                                             @"20150714": @(v2015_07_14),
                                             @"20150305": @(v2015_03_05),
                                             @"20150218": @(v2015_02_18),
                                             @"20150128": @(v2015_01_28)
                                             };
  });
  return messengerShareKitVersionCapabilities;
}

// Get the sorted release versions in descending order.
+ (NSArray *)sortedReleaseVersions
{
  static NSArray *sortedReleaseVersions = nil;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    NSDictionary *messengerShareKitVersionCapabilities = [FBSDKMessengerSharer messengerVersionCapabilities];
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCompare:)];
    sortedReleaseVersions = [[messengerShareKitVersionCapabilities allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  });
  return sortedReleaseVersions;
}

+ (void)_launchUrl:(NSString *)pasteboardType withOptions:(FBSDKMessengerShareOptions *)options minimumRequiredVersion:(NSString *)minimumVersion
{
  NSArray* sortedReleases = [FBSDKMessengerSharer sortedReleaseVersions];

  BOOL openURLDidSucceed = NO;
  for (NSString *messengerVersion in sortedReleases) {
    NSURL *url = [FBSDKMessengerSharer _generateUrl:pasteboardType withOptions:options messengerVersion:messengerVersion];
    if ([[UIApplication sharedApplication] openURL:url]) {
      [FBSDKMessengerApplicationStateManager sharedInstance].currentContext = nil;
      openURLDidSucceed = YES;
      break;
    } else if ([messengerVersion isEqualToString:minimumVersion]) {
      // Stop iterating when minimum required version of Messenger is unable to open.
      break;
    }
  }
  if (!openURLDidSucceed) {
    [[FBSDKMessengerInstallMessengerAlertPresenter sharedInstance] presentInstallMessengerAlert];
  }
}

+ (NSDictionary *)_parseQueryComponentsFromOptions:(FBSDKMessengerShareOptions *)options
{
  NSMutableDictionary *queryComponents = [NSMutableDictionary dictionary];

  // metadata
  if (options.metadata.length > 0) {
    [queryComponents setObject:options.metadata forKey:kMessengerPlatformMetadataParamName];
  }

  // sourceURL
  if (options.sourceURL.absoluteString.length > 0) {
    [queryComponents setObject:options.sourceURL.absoluteString forKey:kMessengerPlatformSourceURLParamName];
  }

  // context query string
  FBSDKMessengerContext *context;
  if (options.contextOverride) {
    context = options.contextOverride;
  } else {
    context = [FBSDKMessengerApplicationStateManager sharedInstance].currentContext;
  }
  if (context.queryComponents) {
    [queryComponents addEntriesFromDictionary:context.queryComponents];
  }

  // render as sticker flag
  if (options.renderAsSticker) {
    [queryComponents setObject:kMessengerPlatformRenderAsStickerParamValue forKey:kMessengerPlatformRenderAsStickerParamName];
  }

  return queryComponents;
}

+ (NSURL *)_generateUrl:(NSString *)pasteboardType withOptions:(FBSDKMessengerShareOptions *)options messengerVersion:(NSString *)messengerVersion
{
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = URLSchemeForVersion(messengerVersion);
  components.host = kMessengerActionBroadcast;

  __block NSString *queryString = [NSString stringWithFormat:kMessengerPlatformQueryString,
                                   pasteboardType,
                                   FBSDKMessengerDefaultAppID(),
                                   kFBSDKMessengerShareKitSendVersion];

  NSDictionary *queryComponents = [FBSDKMessengerSharer _parseQueryComponentsFromOptions:options];

  [queryComponents enumerateKeysAndObjectsUsingBlock:^(NSString *paramKey, NSString *paramVal, BOOL *stop) {
    NSString *component = [NSString stringWithFormat:@"&%@=%@", paramKey, FBSDKMessengerEncodingQueryURL(paramVal)];
    queryString = [queryString stringByAppendingString:component];
  }];

  components.percentEncodedQuery = queryString;
  return components.URL;
}

+ (NSString *)_minimumVersionToSupportCapability:(FBSDKMessengerPlatformCapability)capability withOptions:(FBSDKMessengerShareOptions *)options
{
  NSDictionary *allVersionCapabilites = [FBSDKMessengerSharer messengerVersionCapabilities];
  NSArray* sortedReleases = [FBSDKMessengerSharer sortedReleaseVersions];

  // Traversing from the oldest version to find the one that has enough capability to share the target content.
  for (NSString *version in [sortedReleases reverseObjectEnumerator]) {
    FBSDKMessengerPlatformCapability versionCapability = [allVersionCapabilites[version] unsignedIntegerValue];
    BOOL hasCapability = versionCapability & capability;
    if (options.renderAsSticker ? (versionCapability & FBSDKMessengerPlatformCapabilityRenderAsSticker) && hasCapability : hasCapability) {
      return version;
    }
  }
  return nil;
}

#pragma mark - Public

+ (FBSDKMessengerPlatformCapability)messengerPlatformCapabilities
{
  NSDictionary *allVersionCapabilites = [FBSDKMessengerSharer messengerVersionCapabilities];
  NSString *currentlyInstalledVersion = [FBSDKMessengerSharer currentlyInstalledMessengerVersion];
  return currentlyInstalledVersion ? [allVersionCapabilites[currentlyInstalledVersion] unsignedIntegerValue] : FBSDKMessengerPlatformCapabilityNone;
}

+ (void)openMessenger
{
  NSDictionary *allVersionCapabilites = [FBSDKMessengerSharer messengerVersionCapabilities];
  NSArray* sortedReleases = [FBSDKMessengerSharer sortedReleaseVersions];
  for (NSString *version in sortedReleases) {
    if ([allVersionCapabilites[version] unsignedIntegerValue] & FBSDKMessengerPlatformCapabilityOpen) {
      NSURLComponents *components = [[NSURLComponents alloc] init];
      components.scheme = URLSchemeForVersion(version);
      if ([[UIApplication sharedApplication] openURL:components.URL]) {
        return;
      }
    }
  }
}

#pragma mark - Image

+ (void)shareImage:(UIImage *)image
      withMetadata:(NSString *)metadata
       withContext:(FBSDKMessengerContext *)context
{
  FBSDKMessengerShareOptions *options = [[FBSDKMessengerShareOptions alloc] init];
  options.metadata = metadata;

  [FBSDKMessengerSharer shareImage:image withOptions:options];
}

+ (void)shareImage:(UIImage *)image withOptions:(FBSDKMessengerShareOptions *)options
{
  if (image == nil) {
    return;
  }

  NSData *data = UIImagePNGRepresentation(image);
  [[UIPasteboard generalPasteboard] setData:data
                          forPasteboardType:kMessengerPasteboardTypeImage];

  NSString *requiredVersion = [FBSDKMessengerSharer _minimumVersionToSupportCapability:FBSDKMessengerPlatformCapabilityImage withOptions:options];
  if (requiredVersion) {
    [FBSDKMessengerSharer _launchUrl:kMessengerPasteboardTypeImage
                         withOptions:options
              minimumRequiredVersion:requiredVersion];
  }
}

#pragma mark - Animated GIF

+ (void)shareAnimatedGIF:(NSData *)animatedGIFData
            withMetadata:(NSString *)metadata
             withContext:(FBSDKMessengerContext *)context
{
  FBSDKMessengerShareOptions *options = [[FBSDKMessengerShareOptions alloc] init];
  options.metadata = metadata;

  [FBSDKMessengerSharer shareAnimatedGIF:animatedGIFData withOptions:options];
}

+ (void)shareAnimatedGIF:(NSData *)animatedGIFData withOptions:(FBSDKMessengerShareOptions *)options
{
  if (animatedGIFData == nil) {
    return;
  }

  [[UIPasteboard generalPasteboard] setData:animatedGIFData
                          forPasteboardType:kMessengerPasteboardTypeImage];

  NSString *requiredVersion = [FBSDKMessengerSharer _minimumVersionToSupportCapability:FBSDKMessengerPlatformCapabilityAnimatedGIF withOptions:options];
  if (requiredVersion) {
    [FBSDKMessengerSharer _launchUrl:kMessengerPasteboardTypeImage
                         withOptions:options
              minimumRequiredVersion:requiredVersion];
  }
}

#pragma mark - Animated WebP

+ (void)shareAnimatedWebP:(NSData *)animatedWebPData
             withMetadata:(NSString *)metadata
              withContext:(FBSDKMessengerContext *)context
{
  FBSDKMessengerShareOptions *options = [[FBSDKMessengerShareOptions alloc] init];
  options.metadata = metadata;

  [FBSDKMessengerSharer shareAnimatedWebP:animatedWebPData withOptions:options];
}

+ (void)shareAnimatedWebP:(NSData *)animatedWebPData withOptions:(FBSDKMessengerShareOptions *)options
{
  if (animatedWebPData == nil) {
    return;
  }

  [[UIPasteboard generalPasteboard] setData:animatedWebPData
                          forPasteboardType:kMessengerPasteboardTypeImage];

  NSString *requiredVersion = [FBSDKMessengerSharer _minimumVersionToSupportCapability:FBSDKMessengerPlatformCapabilityAnimatedWebP withOptions:options];
  if (requiredVersion) {
    [FBSDKMessengerSharer _launchUrl:kMessengerPasteboardTypeImage
                         withOptions:options
              minimumRequiredVersion:requiredVersion];
  }
}

#pragma mark - Video

+ (void)shareVideo:(NSData *)videoData
      withMetadata:(NSString *)metadata
       withContext:(FBSDKMessengerContext *)context
{
  FBSDKMessengerShareOptions *options = [[FBSDKMessengerShareOptions alloc] init];
  options.metadata = metadata;

  [FBSDKMessengerSharer shareVideo:videoData withOptions:options];
}

+ (void)shareVideo:(NSData *)videoData withOptions:(FBSDKMessengerShareOptions *)options
{
  if (videoData == nil) {
    return;
  }

  if (options.renderAsSticker) {
    [[FBSDKMessengerInvalidOptionsAlertPresenter sharedInstance] presentInvalidOptionsAlert];
    return;
  }

  [[UIPasteboard generalPasteboard] setData:videoData
                          forPasteboardType:kMessengerPasteboardTypeVideo];

  NSString *requiredVersion = [FBSDKMessengerSharer _minimumVersionToSupportCapability:FBSDKMessengerPlatformCapabilityVideo withOptions:options];
  if (requiredVersion) {
    [FBSDKMessengerSharer _launchUrl:kMessengerPasteboardTypeVideo
                         withOptions:options
              minimumRequiredVersion:requiredVersion];
  }
}

#pragma mark - Audio

+ (void)shareAudio:(NSData *)audioData
      withMetadata:(NSString *)metadata
       withContext:(FBSDKMessengerContext *)context
{
  FBSDKMessengerShareOptions *options = [[FBSDKMessengerShareOptions alloc] init];
  options.metadata = metadata;

  [FBSDKMessengerSharer shareAudio:audioData withOptions:options];
}

+ (void)shareAudio:(NSData *)audioData withOptions:(FBSDKMessengerShareOptions *)options
{
  if (audioData == nil) {
    return;
  }

  if (options.renderAsSticker) {
    [[FBSDKMessengerInvalidOptionsAlertPresenter sharedInstance] presentInvalidOptionsAlert];
    return;
  }

  [[UIPasteboard generalPasteboard] setData:audioData
                          forPasteboardType:kMessengerPasteboardTypeAudio];

  NSString *requiredVersion = [FBSDKMessengerSharer _minimumVersionToSupportCapability:FBSDKMessengerPlatformCapabilityAudio withOptions:options];
  if (requiredVersion) {
    [FBSDKMessengerSharer _launchUrl:kMessengerPasteboardTypeAudio
                         withOptions:options
              minimumRequiredVersion:requiredVersion];
  }
}

@end
