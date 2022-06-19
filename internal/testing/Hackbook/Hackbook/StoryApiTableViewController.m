// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "StoryApiTableViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/PHPhotoLibrary.h>

#import "Console.h"
#import "FBSDKPlatformSharingToStories.h"
#import "IGSDKPlatformSharingToStories.h"
#import "SharingDialogViewController.h"

static NSString *const FBMusicApplicationSupportedIdSpotify = @"174829003346";

typedef NS_OPTIONS(NSInteger, FBSDKSharingToStoriesMediaType) {
  FBSDKSharingToStoriesMediaTypeNone = 0,
  FBSDKSharingToStoriesMediaTypeBackgroundImage = 1 << 1,
  FBSDKSharingToStoriesMediaTypeBackgroundVideo = 1 << 2,
  FBSDKSharingToStoriesMediaTypeStickerImage = 1 << 3,
};

typedef NS_OPTIONS(NSInteger, FBSDKSharingToStoriesMethod) {
  FBSDKSharingToStoriesMethodCamera = 0, // camera is the default for sharing to stories
  FBSDKSharingToStoriesMethodShare, // composer
  FBSDKSharingToStoriesMethodWhatsAppShare,
};

typedef NS_ENUM(NSInteger, FBSDKSharingToStoriesTargetApp) {
  FBSDKSharingToStoriesTargetAppFacebook = 0,
  FBSDKSharingToStoriesTargetAppInstagram,
};

const FBSDKSharingToStoriesTargetApp kTargetAppItems[] = {
  FBSDKSharingToStoriesTargetAppFacebook,
  FBSDKSharingToStoriesTargetAppInstagram,
};
const size_t kTargetAppCount = sizeof(kTargetAppItems) / sizeof(kTargetAppItems[0]);

NSString *const kFBSDKSharingToStoriesTargetApp = @"FBSDKSharingToStoriesTargetApp";

static FBSDKSharingToStoriesTargetApp DefaultTargetApp(void)
{
  const NSInteger defaultTargetApp = [[NSUserDefaults standardUserDefaults] integerForKey:kFBSDKSharingToStoriesTargetApp];
  for (size_t i = 0; i < kTargetAppCount; i++) {
    if (kTargetAppItems[i] == defaultTargetApp) {
      return defaultTargetApp;
    }
  }
  return kTargetAppItems[0];
}

static UIImage *ImageFromURL(NSString *imageURL)
{
  NSURL *const url = [NSURL URLWithString:imageURL];
  NSData *const data = [NSData dataWithContentsOfURL:url];
  return [UIImage imageWithData:data];
}

static UIImage *ImageThatFits(UIImage *image, CGSize size)
{
  if (image) {
    const CGSize imageSize = image.size;
    if (!CGSizeEqualToSize(imageSize, size)) {
      UIGraphicsBeginImageContextWithOptions(size, NO, 1);
      [image drawInRect:CGRectMake(
        (size.width / 2.0) - (imageSize.width / 2.0),
        (size.height / 2.0) - (imageSize.height / 2.0),
        imageSize.width,
        imageSize.height
       )];
      image = UIGraphicsGetImageFromCurrentImageContext();
      UIGraphicsEndImageContext();
    }
  }
  return image;
}

static NSString *NSStringFromFBSDKSharingToStoriesTargetApp(FBSDKSharingToStoriesTargetApp targetApp)
{
  switch (targetApp) {
    case FBSDKSharingToStoriesTargetAppFacebook: {
      return @"Facebook";
    }
    case FBSDKSharingToStoriesTargetAppInstagram: {
      return @"Instagram";
    }
  }
}

static NSString *URLSchemeForTargetApp(FBSDKSharingToStoriesTargetApp targetApp)
{
  switch (targetApp) {
    case FBSDKSharingToStoriesTargetAppFacebook: {
      return @"facebook-stories://share";
    }
    case FBSDKSharingToStoriesTargetAppInstagram: {
      return IGSDKPlatformSharingToStoriesScheme;
    }
  }
}

static void ShareToStory(NSData *stickerImage,
                         NSData *backgroundImage,
                         NSData *backgroundVideo,
                         NSString *backgroundTopColor,
                         NSString *backgroundBottomColor,
                         NSString *contentURL,
                         NSString *appID,
                         NSArray<NSDictionary<NSString *, id> *> *mediaList,
                         FBSDKSharingToStoriesMethod method,
                         FBSDKSharingToStoriesTargetApp targetApp)
{
  BOOL result = NO; // initializing mutable variable to satisfy Infer (since a default case is verboten)
  switch (targetApp) {
    case FBSDKSharingToStoriesTargetAppFacebook: {
      switch (method) {
        case FBSDKSharingToStoriesMethodShare:
          result = FBSDKPlatformSharingToStoriesComposer(
            appID,
            nil,
            backgroundImage,
            backgroundVideo,
            nil
          );
          break;
        case FBSDKSharingToStoriesMethodCamera:
          result = FBSDKPlatformSharingToStoriesCamera(
            appID,
            nil,
            backgroundImage,
            backgroundVideo,
            stickerImage,
            backgroundTopColor,
            backgroundBottomColor,
            contentURL
          );
          break;
        case FBSDKSharingToStoriesMethodWhatsAppShare:
          result = FBSDKPlatformSharingToStoriesWhatsAppShare(
            appID,
            mediaList
          );
          break;
      }
      break;
    }
    case FBSDKSharingToStoriesTargetAppInstagram: {
      result = IGSDKPlatformSharingToStories(
        backgroundImage,
        backgroundVideo,
        stickerImage,
        backgroundTopColor,
        backgroundBottomColor,
        contentURL
      );
      break;
    }
  }
  if (result) {
    ConsoleSucceed(@"openURL:%@", URLSchemeForTargetApp(targetApp));
  } else {
    ConsoleReportBug(@"canOpenURL:%@ returned NO", URLSchemeForTargetApp(targetApp));
  }
}

@interface StoryApiTableViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation StoryApiTableViewController
{
  FBSDKSharingToStoriesMediaType _mediaType;
  FBSDKSharingToStoriesMethod _method;
  FBSDKSharingToStoriesTargetApp _targetApp;
}

- (FBSDKSharingToStoriesTargetApp)targetApp
{
  return _targetApp;
}

- (void)setTargetApp:(FBSDKSharingToStoriesTargetApp)targetApp
{
  _targetApp = targetApp;
}

- (void)_storyFromImagePicker:(id)sender
{
  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    switch (status) {
      case PHAuthorizationStatusAuthorized: {
        dispatch_async(dispatch_get_main_queue(), ^{
          UIImagePickerController *const imagePickerController = [UIImagePickerController new];
          if (self->_mediaType & FBSDKSharingToStoriesMediaTypeBackgroundVideo) {
            imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeAVIMovie, (NSString *) kUTTypeVideo, (NSString *) kUTTypeMPEG4];
          }
          imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
          imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
          imagePickerController.allowsEditing = NO;
          imagePickerController.delegate = self;
          imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
          [self presentViewController:imagePickerController animated:YES completion:NULL];
          if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && [sender isKindOfClass:[UIView class]]) {
            UIPopoverPresentationController *popoverPresentationController = [imagePickerController popoverPresentationController];
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
            popoverPresentationController.sourceView = (UIView *)sender;
            popoverPresentationController.sourceRect = [(UIView *)sender bounds];
          }
        });
        break;
      }
      case PHAuthorizationStatusDenied:
        break;
      case PHAuthorizationStatusNotDetermined:
        break;
      case PHAuthorizationStatusRestricted:
        break;
      #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
      case PHAuthorizationStatusLimited:
        break;
      #endif
    }
  }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
  if (_mediaType & FBSDKSharingToStoriesMediaTypeBackgroundImage) {
    UIImage *const backgroundImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];

    UIImage *const stickerImage = (_mediaType & FBSDKSharingToStoriesMediaTypeStickerImage) ? [UIImage imageNamed:@"f8_logo.jpg"] : nil;
    NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;
    NSData *const backgroundImageData = backgroundImage ? UIImagePNGRepresentation(backgroundImage) : nil;
    ShareToStory(
      stickerImageData,
      backgroundImageData,
      nil,
      nil,
      nil,
      nil,
      [[FBSDKSettings sharedSettings] appID],
      nil,
      _method,
      _targetApp
    );
  } else if (_mediaType & FBSDKSharingToStoriesMediaTypeBackgroundVideo) {
    NSURL *const backgroundVideoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    [picker dismissViewControllerAnimated:YES completion:NULL];

    UIImage *const stickerImage = (_mediaType & FBSDKSharingToStoriesMediaTypeStickerImage) ? [UIImage imageNamed:@"f8_logo.jpg"] : nil;
    NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

    NSData *const backgroundVideoData = [NSData dataWithContentsOfURL:backgroundVideoURL];
    ShareToStory(
      stickerImageData,
      nil,
      backgroundVideoData,
      nil,
      nil,
      nil,
      [[FBSDKSettings sharedSettings] appID],
      nil,
      _method,
      _targetApp
    );
  } else if (_mediaType & FBSDKSharingToStoriesMediaTypeStickerImage) {
    UIImage *const stickerImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:NULL];
    NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;
    const CGRect pixelRect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(pixelRect.size, NO, 0.0);
    [stickerImage drawInRect:pixelRect];
    UIImage *const pixelImage = UIGraphicsGetImageFromCurrentImageContext();
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(pixelImage.CGImage));
    const UInt8 *data = CFDataGetBytePtr(pixelData);
    UInt8 red = data[0];
    UInt8 green = data[1];
    UInt8 blue = data[2];
    NSString *const pixelColor = [NSString stringWithFormat:@"#%2.2X%2.2X%2.2X", red, green, blue];
    CFRelease(pixelData);
    UIGraphicsEndImageContext();
    ShareToStory(
      stickerImageData,
      nil,
      nil,
      pixelColor,
      pixelColor,
      nil,
      [[FBSDKSettings sharedSettings] appID],
      nil,
      _method,
      _targetApp
    );
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - StoryApiTableViewController

- (IBAction)composerWithBackgroundImage:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeBackgroundImage;
  _method = FBSDKSharingToStoriesMethodShare;
  [self _storyFromImagePicker:sender];
}

- (IBAction)composerWithBackgroundVideo:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeBackgroundVideo;
  _method = FBSDKSharingToStoriesMethodShare;
  [self _storyFromImagePicker:sender];
}

- (IBAction)storyFromAppleMusic:(id)sender
{
  // Playlist Name: Today's Country

  // Movable Sticker
  UIImage *const stickerImage = [UIImage imageNamed:@"apple_music_sticker.png"];
  NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

  NSURL *const backgroundVideoURL = [[NSBundle bundleForClass:[SharingDialogViewController class]] URLForResource:@"apple_music_background" withExtension:@"mov"];
  NSData *const backgroundVideoData = [NSData dataWithContentsOfURL:backgroundVideoURL];

  ShareToStory(
    stickerImageData,
    nil,
    backgroundVideoData,
    @"#DA3732",
    @"#902934",
    @"https://music.apple.com/us/playlist/todays-country/pl.87bb5b36a9bd49db8c975607452bfa2b?app=music&itscg=50400&itsct=sharing_fb", // note: the short URL didn't work! @"https://apple.co/2lXj57n"
    @"602231459918900", // Apple Music
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromPinterest:(id)sender
{
  UIImage *const stickerImage = ImageFromURL(@"https://i.pinimg.com/564x/f8/72/a0/f872a010ff9691bad6b13fdc273be518.jpg");
  NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;
  ShareToStory(
    stickerImageData,
    nil,
    nil,
    @"#BDC5D4",
    @"#7D88A9",
    @"https://www.pinterest.com/pin/485474034827974378/feedback/?invite_code=1f93c7de9e4c4cbb91fce2e4c4e63fd2&sender_id=128845376747739125",
    @"274266067164",
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSoundCloud:(id)sender
{
  // <link rel="canonical" href="https://soundcloud.com/mrsuicidesheep/novo-amor-anchor">
  // <meta property="og:image" content="https://i1.sndcdn.com/artworks-000141741938-4om4by-t500x500.jpg">

  // testing non-square sticker
  UIImage *const stickerImage = ImageFromURL(@"https://pre00.deviantart.net/3958/th/pre/i/2014/260/d/2/mr_suicide_sheep_poster__final_version__by_beastofficial-d7zhj2q.png");
  NSData *stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

  UIImage *const backgroundImage = ImageFromURL(@"https://i1.sndcdn.com/artworks-000141741938-4om4by-t500x500.jpg");
  NSData *const backgroundImageData = backgroundImage ? UIImagePNGRepresentation(backgroundImage) : nil;

  ShareToStory(
    stickerImageData,
    backgroundImageData,
    nil,
    @"#927f48",
    @"#312724",
    @"https://soundcloud.com/mrsuicidesheep/novo-amor-anchor",
    @"19507961798",
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyTrack:(id)sender
{
  // Track: Let It Be
  // Artist: The Beatles

  NSString *const stickerImageURL = @"https://i.scdn.co/image/920142fb308970e28aade4a288041a4d1b8f9519";

  NSString *const backgroundTopColor = @"#5297C0";
  NSString *const backgroundBottomColor = @"#070D11";

  NSString *const contentURL = @"https://open.spotify.com/track/7iN1s7xHE4ifF5povM6A48?si=FbT3st_AbEoITqaTBG6Js-&utm_source=facebook";

  UIImage *const stickerImage = ImageFromURL(stickerImageURL);
  NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

  ShareToStory(
    stickerImageData,
    nil,
    nil,
    backgroundTopColor,
    backgroundBottomColor,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyPlaylist:(id)sender
{
  // Playlist: This Is The Beatles

  NSString *const stickerImageURL = @"https://pl.scdn.co/images/pl/default/dc9bfd0d9cf0aabd7298f2fa244a8e5df4eef47e";

  NSString *const contentURL = @"https://open.spotify.com/user/spotify/playlist/37i9dQZF1DXdLtD0qszB1w?si=FbT3st_9VeVGfimQZ-cgVE&utm_source=facebook";

  UIImage *const stickerImage = ImageFromURL(stickerImageURL);
  NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

  ShareToStory(
    stickerImageData,
    nil,
    nil,
    nil,
    nil,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyAlbum:(id)sender
{
  // Album: Abbey Road
  // Artist: The Beatles

  NSString *const stickerImageURL = @"https://i.scdn.co/image/a70b5fec5600e974f58259c5639f6b20f517dd5f";

  NSString *const backgroundTopColor = @"#8EACC0";
  NSString *const backgroundBottomColor = @"#8E9086";

  NSString *const contentURL = @"https://open.spotify.com/album/0ETFjACtuP2ADo6LFhL6HN?si=FbT3st_Zgynq3deSZuVUDE&utm_source=facebook";

  UIImage *const stickerImage = ImageFromURL(stickerImageURL);
  NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

  ShareToStory(
    stickerImageData,
    nil,
    nil,
    backgroundTopColor,
    backgroundBottomColor,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyArtist:(id)sender
{
  // Artist: The Beatles

  NSString *const stickerImageURL = @"https://i.scdn.co/image/6fc6ac9af76d292a9cc55c7415ca0a7fb5b1d4ea";

  NSString *const contentURL = @"https://open.spotify.com/artist/3WrFJ7ztbogyGnTHbHJFl2?si=FbT3st_vVwIo5mS0CldJFH&utm_source=facebook";

  UIImage *const stickerImage = ImageFromURL(stickerImageURL);
  NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

  ShareToStory(
    stickerImageData,
    nil,
    nil,
    nil,
    nil,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyPodcast:(id)sender
{
  // Podcast: The White Album - Side 4

  NSString *const stickerImageURL = @"https://i.scdn.co/image/2d790047e136ba6c5897936129d80742e426ba44";

  NSString *const contentURL = @"https://open.spotify.com/episode/62cpwAJQMhodj97aeiHZU3?si=9nroz-AZQleHObQ-EgS2lw&utm_source=facebook";

  UIImage *const stickerImage = ImageFromURL(stickerImageURL);
  NSData *const stickerImageData = stickerImage ? UIImagePNGRepresentation(stickerImage) : nil;

  ShareToStory(
    stickerImageData,
    nil,
    nil,
    nil,
    nil,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyBackgroundImageActualSize:(id)sender
{
  // Track = Numb - Live At Milton Keys
  // Album = Road To Revolution: Live At Milton Keys
  // Artist = Linkin Park

  UIImage *const backgroundImage = [UIImage imageNamed:@"music_story_test_image.jpg"];
  NSData *const backgroundImageData = backgroundImage ? UIImagePNGRepresentation(backgroundImage) : nil;

  NSString *const contentURL = @"https://open.spotify.com/track/0ZcnedxtJyygYUGMw2dYl4";

  ShareToStory(
    nil,
    backgroundImageData,
    nil,
    nil,
    nil,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyBackgroundImageFullScreen:(id)sender
{
  // Track = Numb - Live At Milton Keys
  // Album = Road To Revolution: Live At Milton Keys
  // Artist = Linkin Park

  UIImage *const backgroundImage = [UIImage imageNamed:@"music_story_test_image.jpg"];
  UIScreen *const mainScreen = [UIScreen mainScreen];
  const CGSize screenSize = mainScreen.fixedCoordinateSpace.bounds.size;
  const CGFloat screenScale = [mainScreen scale];
  UIImage *const adjustedImage = ImageThatFits(
    backgroundImage,
    CGSizeMake(
      screenSize.width * screenScale,
      screenSize.height * screenScale
    )
  );
  NSData *const backgroundImageData = adjustedImage ? UIImagePNGRepresentation(adjustedImage) : nil;

  NSString *const contentURL = @"https://open.spotify.com/track/0ZcnedxtJyygYUGMw2dYl4";

  ShareToStory(
    nil,
    backgroundImageData,
    nil,
    nil,
    nil,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromSpotifyBackgroundImage9by16:(id)sender
{
  // Track = Numb - Live At Milton Keys
  // Album = Road To Revolution: Live At Milton Keys
  // Artist = Linkin Park

  UIImage *const backgroundImage = [UIImage imageNamed:@"music_story_test_image.jpg"];
  UIScreen *const mainScreen = [UIScreen mainScreen];
  const CGSize screenSize = mainScreen.fixedCoordinateSpace.bounds.size;
  const CGFloat aspectWidth = screenSize.height * (9.0 / 16.0); // force 9:16 aspect
  const CGFloat aspectHeight = screenSize.width * (16.0 / 9.0); // force 9:16 aspect
  const CGSize aspectSize = (CGSize) {
    .width = screenSize.height >= aspectHeight ? screenSize.width : aspectWidth,
    .height = screenSize.height >= aspectHeight ? aspectHeight : screenSize.height,
  };
  const CGFloat screenScale = [mainScreen scale];
  UIImage *const adjustedImage = ImageThatFits(
    backgroundImage,
    CGSizeMake(
      aspectSize.width * screenScale,
      aspectSize.height * screenScale
    )
  );
  NSData *const backgroundImageData = adjustedImage ? UIImagePNGRepresentation(adjustedImage) : nil;

  NSString *const contentURL = @"https://open.spotify.com/track/0ZcnedxtJyygYUGMw2dYl4";

  ShareToStory(
    nil,
    backgroundImageData,
    nil,
    nil,
    nil,
    contentURL,
    FBMusicApplicationSupportedIdSpotify,
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromTiKToK:(id)sender
{
  NSURL *const backgroundVideoURL = [[NSBundle bundleForClass:[SharingDialogViewController class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  NSData *const backgroundVideoData = [NSData dataWithContentsOfURL:backgroundVideoURL];

  ShareToStory(
    nil,
    nil,
    backgroundVideoData,
    nil,
    nil,
    nil,
    @"597615686992125",
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyFromWhatsAppSinglePhoto:(id)sender
{
  UIImage *const photo = [UIImage imageNamed:@"music_story_test_image.jpg"];
  NSData *const photoData = photo ? UIImagePNGRepresentation(photo) : nil;

  NSMutableArray<NSDictionary<NSString *, id> *> *const mediaList = [NSMutableArray new];
  if (photoData) {
    [mediaList addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppStoryImage : photoData,
                           FBSDKPlatformSharingToStoriesParamWhatsAppStoryCaption : @"photo caption"}];
  }

  ShareToStory(
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    @"306069495113",
    mediaList,
    FBSDKSharingToStoriesMethodWhatsAppShare,
    _targetApp
  );
}

- (IBAction)storyFromWhatsAppSingleVideo:(id)sender
{
  NSURL *const videoURL = [[NSBundle bundleForClass:[SharingDialogViewController class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  NSData *const videoData = [NSData dataWithContentsOfURL:videoURL];

  NSMutableArray<NSDictionary<NSString *, id> *> *const mediaList = [NSMutableArray new];
  if (videoData) {
    [mediaList addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppStoryVideo : videoData,
                           FBSDKPlatformSharingToStoriesParamWhatsAppStoryCaption : @"singe video caption"}];
  }

  ShareToStory(
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    @"306069495113",
    mediaList,
    FBSDKSharingToStoriesMethodWhatsAppShare,
    _targetApp
  );
}

- (IBAction)storyFromWhatsAppMultipleMedia:(id)sender
{
  UIImage *const photo = [UIImage imageNamed:@"music_story_test_image.jpg"];
  NSData *const photoData = photo ? UIImagePNGRepresentation(photo) : nil;
  NSURL *const videoURL = [[NSBundle bundleForClass:[SharingDialogViewController class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  NSData *const videoData = [NSData dataWithContentsOfURL:videoURL];

  NSMutableArray<NSDictionary<NSString *, id> *> *const mediaList = [NSMutableArray new];
  if (photoData) {
    [mediaList addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppStoryImage : photoData,
                           FBSDKPlatformSharingToStoriesParamWhatsAppStoryCaption : @"photo caption"}];
  }
  if (videoData) {
    [mediaList addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppStoryVideo : videoData,
                           FBSDKPlatformSharingToStoriesParamWhatsAppStoryCaption : @"video caption"}];
  }

  ShareToStory(
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    @"306069495113",
    mediaList,
    FBSDKSharingToStoriesMethodWhatsAppShare,
    _targetApp
  );
}

- (IBAction)storyFromWhatsAppVideoAndLink:(id)sender
{
  UIImage *const burnedPhoto = [UIImage imageNamed:@"wa_link_story_test_image.jpg"];
  NSData *const burnedPhotoData = burnedPhoto ? UIImagePNGRepresentation(burnedPhoto) : nil;
  NSURL *const videoURL = [[NSBundle bundleForClass:[SharingDialogViewController class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  NSData *const videoData = [NSData dataWithContentsOfURL:videoURL];

  NSMutableArray<NSDictionary<NSString *, id> *> *const mediaList = [NSMutableArray new];
  if (videoData) {
    [mediaList addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppStoryVideo : videoData,
                           FBSDKPlatformSharingToStoriesParamWhatsAppStoryCaption : @"video caption"}];
  }
  if (burnedPhotoData) {
    [mediaList addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppStoryImage : burnedPhotoData,
                           @"linkURL" : @"http://www.google.com"}];
  }

  ShareToStory(
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    @"306069495113",
    mediaList,
    FBSDKSharingToStoriesMethodWhatsAppShare,
    _targetApp
  );
}

- (IBAction)storyFromWhatsAppLink:(id)sender
{
  UIImage *const burnedPhoto = [UIImage imageNamed:@"wa_link_story_test_image.jpg"];
  NSData *const burnedPhotoData = burnedPhoto ? UIImagePNGRepresentation(burnedPhoto) : nil;

  NSMutableArray<NSDictionary<NSString *, id> *> *const mediaList = [NSMutableArray new];
  if (burnedPhotoData) {
    [mediaList addObject:@{FBSDKPlatformSharingToStoriesParamWhatsAppStoryImage : burnedPhotoData,
                           @"linkURL" : @"http://www.google.com"}];
  }

  ShareToStory(
    nil,
    nil,
    nil,
    nil,
    nil,
    nil,
    @"306069495113",
    mediaList,
    FBSDKSharingToStoriesMethodWhatsAppShare,
    _targetApp
  );
}

- (IBAction)storyWithBackgroundImage:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeBackgroundImage;
  _method = FBSDKSharingToStoriesMethodCamera;
  [self _storyFromImagePicker:sender];
}

- (IBAction)storyWithBackgroundImagePlusStickerImage:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeBackgroundImage | FBSDKSharingToStoriesMediaTypeStickerImage;
  _method = FBSDKSharingToStoriesMethodCamera;
  [self _storyFromImagePicker:sender];
}

- (IBAction)storyWithBackgroundVideo:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeBackgroundVideo;
  _method = FBSDKSharingToStoriesMethodCamera;
  [self _storyFromImagePicker:sender];
}

- (IBAction)storyWithBackgroundVideoPlusStickerImage:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeBackgroundVideo | FBSDKSharingToStoriesMediaTypeStickerImage;
  _method = FBSDKSharingToStoriesMethodCamera;
  [self _storyFromImagePicker:sender];
}

- (IBAction)storyWithContentURL:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeNone;
  _method = FBSDKSharingToStoriesMethodCamera;
  ShareToStory(
    nil,
    nil,
    nil,
    nil,
    nil,
    @"https://www.goodreads.com/book/show/13496.A_Game_of_Thrones",
    @"597615686992125",
    nil,
    FBSDKSharingToStoriesMethodCamera,
    _targetApp
  );
}

- (IBAction)storyWithStickerImage:(id)sender
{
  _mediaType = FBSDKSharingToStoriesMediaTypeStickerImage;
  _method = FBSDKSharingToStoriesMethodCamera;
  [self _storyFromImagePicker:sender];
}

- (IBAction)selectTargetApp:(id)sender;
{
  UIAlertController *const alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];

  __weak typeof(self) weakSelf = self;

  for (size_t i = 0; i < kTargetAppCount; i++) {
    const FBSDKSharingToStoriesTargetApp targetApp = kTargetAppItems[i];
    NSString *const title = NSStringFromFBSDKSharingToStoriesTargetApp(targetApp);
    UIAlertAction *const targetAppAction =
    [UIAlertAction actionWithTitle:title
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction *alertAction) {
                             __strong typeof(self) strongSelf = weakSelf;
                             if (strongSelf
                                 && [strongSelf targetApp] != targetApp) {
                               [strongSelf setTargetApp:targetApp];
                               [[strongSelf targetAppButton] setTitle:title]; // update title of button

                               // update enabled/disabled state of options
                               [self.tableView beginUpdates];
                               [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
                               [self.tableView endUpdates];

                               [[NSUserDefaults standardUserDefaults] setInteger:targetApp forKey:kFBSDKSharingToStoriesTargetApp]; // track the selection
                             }
                           }];
    [alertController addAction:targetAppAction];
  }

  UIAlertAction *const cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
  [alertController addAction:cancelAction];

  UIPopoverPresentationController *const popoverPresentationController = [alertController popoverPresentationController];
  popoverPresentationController.barButtonItem = (UIBarButtonItem *)sender;
  popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionDown;

  [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
  UIView *const subview = cell.contentView.subviews.firstObject;
  if ([subview isKindOfClass:[UIButton class]]) {
    NSString *const urlScheme = URLSchemeForTargetApp(_targetApp);
    const BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlScheme]];
    UIColor *const titleColor = canOpenURL ? tableView.tintColor : [UIColor lightGrayColor];
    [(UIButton *)subview setTitleColor:titleColor forState:UIControlStateNormal];
  }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  _targetApp = DefaultTargetApp();
  [[self targetAppButton] setTitle:NSStringFromFBSDKSharingToStoriesTargetApp(_targetApp)];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [self.navigationController setToolbarHidden:YES animated:YES];
}

@end
