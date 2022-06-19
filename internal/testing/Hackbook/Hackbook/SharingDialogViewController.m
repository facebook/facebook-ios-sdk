// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "SharingDialogViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/PHPhotoLibrary.h>

@import FBSDKCoreKit;

#import "Console.h"
#import "ImagePicker.h"
#import "Utilities.h"

static NSArray<id> *GetMediaArray(FBSDKSharePhoto *photo, FBSDKShareVideo *video)
{
  NSMutableArray<id> *const media = [NSMutableArray new];
  if (photo) {
    [media addObject:photo];
  }
  if (video) {
    [media addObject:video];
  }
  return media;
}

static FBSDKSharePhoto *GetPhotoResourceHack(void)
{
  return [[FBSDKSharePhoto alloc] initWithImage:[UIImage imageNamed:@"hack.png"]
                                isUserGenerated:YES];
}

static FBSDKSharePhoto *GetPhotoResourceThumbsUp(void)
{
  return [[FBSDKSharePhoto alloc] initWithImage:[UIImage imageNamed:@"thumbs_up.jpg"]
                                isUserGenerated:YES];
}

static FBSDKSharePhoto *GetPhotoResourceSpacebook(void)
{
  return [[FBSDKSharePhoto alloc] initWithImage:[UIImage imageNamed:@"spacebook.jpg"]
                                isUserGenerated:YES];
}

static FBSDKSharePhoto *GetPhotoResourceF8(void)
{
  return [[FBSDKSharePhoto alloc] initWithImage:[UIImage imageNamed:@"f82011_logo.jpg"]
                                isUserGenerated:YES];
}

static FBSDKSharePhoto *GetPhotoResourceStarWarsLike(void)
{
  return [[FBSDKSharePhoto alloc] initWithImage:[UIImage imageNamed:@"starwars_like.jpg"]
                                isUserGenerated:YES];
}

static FBSDKSharePhoto *GetPhotoResourceBugsBunny(void)
{
  return [[FBSDKSharePhoto alloc] initWithImage:[UIImage imageNamed:@"bugs_bunny-500x500.jpg"]
                                isUserGenerated:YES];
}

static NSArray<FBSDKSharePhoto *> *GetPhotoContentPhotos(NSUInteger numberOfPhotos)
{
  NSMutableArray<FBSDKSharePhoto *> *const photos = [NSMutableArray new];
  if (numberOfPhotos > 0) {
    FBSDKSharePhoto *const photo = GetPhotoResourceThumbsUp();
    if (photo) {
      [photos addObject:photo];
    }
  }
  if (numberOfPhotos > 1) {
    FBSDKSharePhoto *const photo = GetPhotoResourceHack();
    if (photo) {
      [photos addObject:photo];
    }
  }
  if (numberOfPhotos > 2) {
    FBSDKSharePhoto *const photo = GetPhotoResourceSpacebook();
    if (photo) {
      [photos addObject:photo];
    }
  }
  if (numberOfPhotos > 3) {
    FBSDKSharePhoto *const photo = GetPhotoResourceF8();
    if (photo) {
      [photos addObject:photo];
    }
  }
  if (numberOfPhotos > 4) {
    FBSDKSharePhoto *const photo = GetPhotoResourceStarWarsLike();
    if (photo) {
      [photos addObject:photo];
    }
  }
  if (numberOfPhotos > 5) {
    FBSDKSharePhoto *const photo = GetPhotoResourceBugsBunny();
    if (photo) {
      [photos addObject:photo];
    }
  }
  return photos;
}

static FBSDKShareVideo *GetVideoResourceFile(void)
{
  return [[FBSDKShareVideo alloc] initWithVideoURL:[NSURL URLWithString:@"assets-library://asset/asset.mp4"]
                                      previewPhoto:nil]; // not really used
}

static void SetLinkContentQuote(FBSDKShareLinkContent *linkContent)
{
  linkContent.quote = @"Move fast and break things";
}

void SetLinkContentURL(FBSDKShareLinkContent *linkContent)
{
  linkContent.contentURL = [NSURL URLWithString:@"https://newsroom.fb.com/"];
}

static void SetSharingContentHashtag(id<FBSDKSharingContent> sharingContent)
{
  sharingContent.hashtag = [[FBSDKHashtag alloc] initWithString:@"#MadeWithHackbook"];
}

static void SetSharingContentPeopleIDs(id<FBSDKSharingContent> sharingContent, NSArray<id> *friends)
{
  NSUInteger friendCount = [friends count];
  if (friendCount > 0) {
    sharingContent.peopleIDs = @[friends[arc4random() % friendCount][@"id"]];
  }
}

static void SetSharingContentPlaceID(id<FBSDKSharingContent> sharingContent)
{
  sharingContent.placeID = @"166793820034304"; // Facebook HQ
}

@interface SharingDialogViewController () <ImagePickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIView *activityOverlayView;
@property (nonatomic, strong) ImagePicker *imagePicker;
@property (nonatomic, strong) UIImage *selectedPhoto;
@property (nonatomic, strong) UIImagePickerController *videoPickerController;
@property (nonatomic, strong) IBOutlet UITextField *urlInputField;
@end

@implementation SharingDialogViewController

#pragma mark - Object Lifecycle

- (void)dealloc
{
  _imagePicker.delegate = nil;
  _videoPickerController.delegate = nil;
}

#pragma mark - Subclass Methods

- (NSString *)appEventsPrefix
{
  NSAssert(NO, @"This method must be overridden by subclasses.");
  return nil;
}

- (id<FBSDKSharingDialog>)buildDialog
{
  NSAssert(NO, @"This method must be overridden by subclasses.");
  return nil;
}

- (void)shareUsingContentBlock:(id<FBSDKSharingContent>(^)(void))contentBlock
{
  // check if the native dialog is available
  id<FBSDKSharingDialog> dialog = [self buildDialog];
  dialog.delegate = self;
  if (![dialog canShow]) {
    ConsoleSucceed(@"Facebook/Messenger App is not installed.");
    return;
  }

  // build the content
  id<FBSDKSharingContent> shareContent = contentBlock ? contentBlock() : nil;
  if (!shareContent) {
    return;
  }
  dialog.shareContent = shareContent;

  // share
  dialog.shouldFailOnDataError = YES;
  NSError *error;
  if (![dialog validateWithError:&error]) {
    ConsoleError(error, @"Error validating share content");
    return;
  }
  if (![dialog show]) {
    ConsoleReportBug(@"Error opening dialog");
  }
}

- (BOOL)validateShareContent:(id<FBSDKSharingContent>)shareContent
{
  if (!shareContent) {
    return NO;
  }
  id<FBSDKSharingDialog> dialog = [self buildDialog];
  if (![dialog canShow]) {
    return NO;
  }
  dialog.shareContent = shareContent;
  dialog.shouldFailOnDataError = YES;
  if (![dialog validateWithError:NULL]) {
    return NO;
  }
  return YES;
}

- (NSUInteger)photosToShare
{
  return 2;
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self loadFriendsWithCompletionBlock:NULL force:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  NSString *persistedInputURLString = [NSUserDefaults.standardUserDefaults objectForKey:@"inputShareURLString"];
  if (persistedInputURLString) {
    self.urlInputField.text = persistedInputURLString;
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];

  if (self.urlInputField.text) {
    [NSUserDefaults.standardUserDefaults setObject:self.urlInputField.text forKey:@"inputShareURLString"];
  }
}

#pragma mark - Actions

- (IBAction)shareAllContent:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_AllContent", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
    SetLinkContentURL(linkContent);
    SetSharingContentHashtag(linkContent);
    SetSharingContentPeopleIDs(linkContent, self.friends);
    SetSharingContentPlaceID(linkContent);
    SetLinkContentQuote(linkContent);
    return linkContent;
  }];
}

- (BOOL)canShareAllContent
{
  return [self canShareLink]; // only need basic link to test validation
}

- (IBAction)shareText:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Text", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const textContent = [FBSDKShareLinkContent new]; // will open the platform share composer with no content
    return textContent;
  }];
}

- (BOOL)canShareText
{
  FBSDKShareLinkContent *const textContent = [FBSDKShareLinkContent new];
  return [self validateShareContent:textContent];
}

- (IBAction)shareLink:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Link", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
    SetLinkContentURL(linkContent);
    return linkContent;
  }];
}

- (BOOL)canShareLink
{
  FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
  SetLinkContentURL(linkContent);
  return [self validateShareContent:linkContent];
}

- (IBAction)shareLinkPlusHashtag:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Link_Hashtag", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
    SetLinkContentURL(linkContent);
    SetSharingContentHashtag(linkContent);
    return linkContent;
  }];
}

- (BOOL)canShareLinkPlusHashtag
{
  return [self canShareLink]; // only need basic link to test validation
}

- (IBAction)shareLinkPlusAppFriend:(id)sender; // share link with 1 app friend only
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Link_App_Friend", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
    SetLinkContentURL(linkContent);
    SetSharingContentPeopleIDs(linkContent, self.friends);
    return linkContent;
  }];
}

- (BOOL)canShareLinkPlusAppFriend
{
  return [self canShareLink]; // only need basic link to test validation
}

- (IBAction)shareLinkPlusPlaceTag:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Link_Place_Tag", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
    SetLinkContentURL(linkContent);
    SetSharingContentPlaceID(linkContent);
    return linkContent;
  }];
}

- (BOOL)canShareLinkPlusPlaceTag
{
  return [self canShareLink]; // only need basic link to test validation
}

- (IBAction)shareLinkPlusQuote:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Link_Quote", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
    SetLinkContentURL(linkContent);
    SetLinkContentQuote(linkContent);
    return linkContent;
  }];
}

- (IBAction)shareURL:(id)sender
{
  [self shareInputURL];
}

- (IBAction)didEndEditing:(UITextField *)sender
{
  [self shareInputURL];
}

- (void)shareInputURL
{
  NSURL *inputURL = [NSURL URLWithString:self.urlInputField.text];

  FBSDKShareLinkContent *const linkContent = [FBSDKShareLinkContent new];
  linkContent.contentURL = inputURL;

  if (![self validateShareContent:linkContent]) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid URL"
                                                                   message:@"Please enter a valid url."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"FINE!"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                            [self dismissViewControllerAnimated:true completion:nil];
                                                          }];
    [alert addAction:dismissAction];

    [self presentViewController:alert animated:true completion:nil];
  }

  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    return linkContent;
  }];
}

- (BOOL)canShareLinkPlusQuote
{
  return [self canShareLink]; // only need basic link to test validation
}

- (IBAction)sharePhotos:(UIButton *)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_PhotosParams", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKSharePhotoContent *const photoContent = [FBSDKSharePhotoContent new];
    photoContent.photos = GetPhotoContentPhotos([self photosToShare]);
    return photoContent;
  }];
}

- (BOOL)canSharePhotos
{
  FBSDKSharePhotoContent *const photoContent = [FBSDKSharePhotoContent new];
  photoContent.photos = GetPhotoContentPhotos(1);
  return [self validateShareContent:photoContent];
}

- (IBAction)sharePhotoFromLibrary:(UIButton *)sender
{
  ImagePicker *imagePicker = [[ImagePicker alloc] init];
  self.imagePicker = imagePicker;
  imagePicker.delegate = self;
  if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && [sender isKindOfClass:[UIView class]]) {
    UIView *senderView = (UIView *)sender;
    UIView *view = self.view;
    [imagePicker presentFromRect:[view convertRect:senderView.bounds fromView:senderView] inView:self.view];
  } else {
    [imagePicker presentWithViewController:self];
  }
}

- (BOOL)canSharePhotoFromLibrary
{
  return [self canSharePhotos];
}

- (IBAction)sharePhotoPlusHashtag:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Photo_Hashtag", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKSharePhotoContent *const photoContent = [FBSDKSharePhotoContent new];
    photoContent.photos = GetPhotoContentPhotos(1);
    SetSharingContentHashtag(photoContent);
    return photoContent;
  }];
}

- (BOOL)canSharePhotoPlusHashtag
{
  return [self canSharePhotos];
}

- (IBAction)sharePhotoPlusAppFriend:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Photo_App_Friend", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKSharePhotoContent *const photoContent = [FBSDKSharePhotoContent new];
    photoContent.photos = GetPhotoContentPhotos(1);
    SetSharingContentPeopleIDs(photoContent, self.friends);
    return photoContent;
  }];
}

- (BOOL)canSharePhotoPlusAppFriend
{
  return [self canSharePhotos];
}

- (IBAction)sharePhotoPlusPlaceTag:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Photo_Place_Tag", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKSharePhotoContent *const photoContent = [FBSDKSharePhotoContent new];
    photoContent.photos = GetPhotoContentPhotos(1);
    SetSharingContentPlaceID(photoContent);
    return photoContent;
  }];
}

- (BOOL)canSharePhotoPlusPlaceTag
{
  return [self canSharePhotos];
}

- (IBAction)shareVideo:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Video", [self appEventsPrefix]]];
  NSURL *const videoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  ALAssetsLibrary *const library = [[ALAssetsLibrary alloc] init];
  __weak typeof(self) weakSelf = self;
  [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
    #pragma clang diagnostic pop
    typeof(self) strongSelf = weakSelf;
    if (assetURL) {
      [strongSelf shareUsingContentBlock:^id<FBSDKSharingContent> {
        FBSDKShareVideoContent *const videoContent = [FBSDKShareVideoContent new];
        videoContent.video = [[FBSDKShareVideo alloc] initWithVideoURL:assetURL
                                                          previewPhoto:nil];
        return videoContent;
      }];
    } else {
      ConsoleError(error, @"Error saving video");
    }
  }];
}

- (BOOL)canShareVideo
{
  FBSDKShareVideoContent *const videoContent = [FBSDKShareVideoContent new];
  videoContent.video = GetVideoResourceFile();
  return [self validateShareContent:videoContent];
}

- (IBAction)shareVideoFromLibrary:(id)sender
{
  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    switch (status) {
      case PHAuthorizationStatusAuthorized: {
        [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Video_From_Library", [self appEventsPrefix]]];

        dispatch_async(dispatch_get_main_queue(), ^{
          UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
          imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeAVIMovie, (NSString *) kUTTypeVideo, (NSString *) kUTTypeMPEG4];
          imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
          imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
          imagePickerController.allowsEditing = NO;
          imagePickerController.delegate = self;
          imagePickerController.modalPresentationStyle = UIModalPresentationPopover;

          if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && [sender isKindOfClass:[UIView class]]) {
            UIPopoverPresentationController *popoverPresentationController = [imagePickerController popoverPresentationController];
            popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
            popoverPresentationController.sourceView = (UIView *)sender;
            popoverPresentationController.sourceRect = [(UIView *)sender bounds];
          }

          [self presentViewController:imagePickerController animated:YES completion:NULL];
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

- (BOOL)canShareVideoFromLibrary
{
  return [self canShareVideo];
}

- (IBAction)shareVideoPlusHashtag:(id)sender;
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Video_Hashtag", [self appEventsPrefix]]];
  NSURL *const videoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  ALAssetsLibrary *const library = [[ALAssetsLibrary alloc] init];
  __weak typeof(self) weakSelf = self;
  [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
    #pragma clang diagnostic pop
    typeof(self) strongSelf = weakSelf;
    if (assetURL) {
      [strongSelf shareUsingContentBlock:^id<FBSDKSharingContent> {
        FBSDKShareVideoContent *const videoContent = [FBSDKShareVideoContent new];
        videoContent.video = [[FBSDKShareVideo alloc] initWithVideoURL:assetURL
                                                          previewPhoto:nil];
        SetSharingContentHashtag(videoContent);
        return videoContent;
      }];
    } else {
      ConsoleError(error, @"Error saving video");
    }
  }];
}

- (BOOL)canShareVideoPlusHashtag
{
  return [self canShareVideo];
}

- (IBAction)shareVideoPlusAppFriend:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Video_App_Friend", [self appEventsPrefix]]];
  NSURL *const videoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  ALAssetsLibrary *const library = [[ALAssetsLibrary alloc] init];
  __weak typeof(self) weakSelf = self;
  [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
    #pragma clang diagnostic pop
    typeof(self) strongSelf = weakSelf;
    if (assetURL) {
      [strongSelf shareUsingContentBlock:^id<FBSDKSharingContent> {
        FBSDKShareVideoContent *const videoContent = [FBSDKShareVideoContent new];
        videoContent.video = [[FBSDKShareVideo alloc] initWithVideoURL:assetURL
                                                          previewPhoto:nil];
        SetSharingContentPeopleIDs(videoContent, strongSelf.friends);
        return videoContent;
      }];
    } else {
      ConsoleError(error, @"Error saving video");
    }
  }];
}

- (BOOL)canShareVideoPlusAppFriend
{
  return [self canShareVideo];
}

- (IBAction)shareVideoPlusPlaceTag:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Video_Place_Tag", [self appEventsPrefix]]];
  NSURL *const videoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  ALAssetsLibrary *const library = [[ALAssetsLibrary alloc] init];
  __weak typeof(self) weakSelf = self;
  [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
    #pragma clang diagnostic pop
    typeof(self) strongSelf = weakSelf;
    if (assetURL) {
      [strongSelf shareUsingContentBlock:^id<FBSDKSharingContent> {
        FBSDKShareVideoContent *const videoContent = [FBSDKShareVideoContent new];
        videoContent.video = [[FBSDKShareVideo alloc] initWithVideoURL:assetURL
                                                          previewPhoto:nil];
        SetSharingContentPlaceID(videoContent);
        return videoContent;
      }];
    } else {
      ConsoleError(error, @"Error saving video");
    }
  }];
}

- (BOOL)canShareVideoPlusPlaceTag
{
  return [self canShareVideo];
}

- (IBAction)shareMultimedia:(id)sender
{
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_Multimedia", [self appEventsPrefix]]];
  NSURL *const videoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Wdeprecated-declarations"
  ALAssetsLibrary *const library = [[ALAssetsLibrary alloc] init];
  __weak typeof(self) weakSelf = self;
  [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
    #pragma clang diagnostic pop
    typeof(self) strongSelf = weakSelf;
    if (assetURL) {
      [strongSelf shareUsingContentBlock:^id<FBSDKSharingContent> {
        FBSDKShareMediaContent *const mediaContent = [FBSDKShareMediaContent new];
        FBSDKShareVideo *video = [[FBSDKShareVideo alloc] initWithVideoURL:assetURL previewPhoto:nil];
        mediaContent.media = GetMediaArray(GetPhotoResourceThumbsUp(), video);
        return mediaContent;
      }];
    } else {
      ConsoleError(error, @"Error saving video");
    }
  }];
}

- (BOOL)canShareMultimedia
{
  FBSDKShareMediaContent *const mediaContent = [FBSDKShareMediaContent new];
  mediaContent.media = GetMediaArray(GetPhotoResourceThumbsUp(), GetVideoResourceFile());
  return [self validateShareContent:mediaContent];
}

#pragma mark - ImagePickerDelegate

- (void)imagePicker:(ImagePicker *)imagePicker didSelectImage:(UIImage *)image
{
  self.selectedPhoto = image;
  self.imagePicker = nil;
  [FBSDKAppEvents.shared logEvent:[[NSString alloc] initWithFormat:@"click_%@_PhotoParams", [self appEventsPrefix]]];
  [self shareUsingContentBlock:^id<FBSDKSharingContent> {
    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] initWithImage:image isUserGenerated:YES];
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[photo];
    return content;
  }];
}

- (void)imagePickerDidCancel:(ImagePicker *)imagePicker
{
  self.imagePicker = nil;
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  PHAsset *asset;
  if (@available(iOS 11, *)) {
    asset = [info objectForKey:UIImagePickerControllerPHAsset];
  }
  NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
  [picker dismissViewControllerAnimated:YES completion:NULL];
  if (asset) {
    [self shareUsingContentBlock:^id<FBSDKSharingContent> {
      FBSDKShareVideo *video = [[FBSDKShareVideo alloc] initWithVideoAsset:asset
                                                              previewPhoto:nil];
      FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
      content.video = video;
      return content;
    }];
  } else if (videoURL) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    __weak typeof(self) weakSelf = self;
    [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
      #pragma clang diagnostic pop
      typeof(self) strongSelf = weakSelf;
      if (strongSelf && assetURL) {
        [strongSelf shareUsingContentBlock:^id<FBSDKSharingContent> {
          FBSDKShareVideo *video = [[FBSDKShareVideo alloc] initWithVideoURL:assetURL
                                                                previewPhoto:nil];
          FBSDKShareVideoContent *content = [FBSDKShareVideoContent new];
          content.video = video;
          return content;
        }];
      } else {
        ConsoleError(error, @"Error saving video");
      }
    }];
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
  self.videoPickerController = nil;
  [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Properties

- (void)setImagePicker:(ImagePicker *)imagePicker
{
  if (_imagePicker != imagePicker) {
    _imagePicker.delegate = nil;
    _imagePicker = imagePicker;
  }
}

- (void)setVideoPickerController:(UIImagePickerController *)imagePickerController
{
  if (_videoPickerController != imagePickerController) {
    _videoPickerController.delegate = nil;
    _videoPickerController = imagePickerController;
  }
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
  ConsoleSucceed(@"Content successfully shared: %@", StringForJSONObject(results));
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
  ConsoleError(error, @"Error sharing content");
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
  ConsoleLog(@"Dialog cancelled");
}

@end
