// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ActivityViewTableViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <Social/Social.h>

@import FBSDKShareKit;

#import "Console.h"
#import "FBSDKPlatformShareExtension.h"

static NSString *const kUIActivityViewControllerActionReuseIdentifier = @"UIActivityViewControllerAction";

typedef NS_ENUM(NSUInteger, ActivityViewControllerSection) {
  ActivityViewControllerSectionLinks,
  ActivityViewControllerSectionTextWithLinks,
  ActivityViewControllerSectionPhoto,
  ActivityViewControllerSectionVideo,
  ActivityViewControllerSectionMixedCases,
  ActivityViewControllerSectionSLComposeViewController,
  ActivityViewControllerSectionSDK,
  ActivityViewControllerSectionNumItems,
};

@interface _TestAction : NSObject

@property (nonatomic, readonly, weak) id target;
@property (nonatomic, readonly, assign) SEL action;
@property (nonatomic, readonly, copy) NSString *text;
@property (nonatomic, readonly, assign) BOOL expectedToFail;

- (instancetype)initWithTarget:(id)target action:(SEL)action text:(NSString *)text expectedToFail:(BOOL)expectedToFail NS_DESIGNATED_INITIALIZER;
+ (instancetype)testActionWithTarget:(id)target action:(SEL)action text:(NSString *)text;
+ (instancetype)testActionWithTarget:(id)target action:(SEL)action text:(NSString *)text expectedToFail:(BOOL)expectedToFail;

@end

@implementation _TestAction

- (instancetype)init NS_UNAVAILABLE
{
  assert(0);
  return nil;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action text:(NSString *)text expectedToFail:(BOOL)expectedToFail
{
  self = [super init];
  if (self != nil) {
    _target = target;
    _action = action;
    _text = [text copy];
    _expectedToFail = expectedToFail;
  }
  return self;
}

+ (instancetype)testActionWithTarget:(id)target action:(SEL)action text:(NSString *)text
{
  return [[[self class] alloc] initWithTarget:target action:action text:text expectedToFail:NO];
}

+ (instancetype)testActionWithTarget:(id)target action:(SEL)action text:(NSString *)text expectedToFail:(BOOL)expectedToFail
{
  return [[[self class] alloc] initWithTarget:target action:action text:text expectedToFail:expectedToFail];
}

@end

@interface ActivityViewTableViewController () <
  UIActivityItemSource,
  FBSDKSharingDelegate
>

@end

@implementation ActivityViewTableViewController
{
  NSString *_testString;
  NSURL *_testURL;

  // An array of arrays. First index is the section, second index is specific test action in the section.
  NSArray *_testActions;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Share Extension";
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kUIActivityViewControllerActionReuseIdentifier];
  self.tableView.rowHeight = 44;
  _testString = @"2,000 guardsman, 1,000 cops deployed to Baltimore";
  _testURL = [NSURL URLWithString:@"http://www.cnn.com/2015/04/28/us/baltimore-riots/index.html"];
  _testActions = [self _buildTestActions];
}

- (NSArray *)_buildTestActions
{
  NSMutableArray *sections = [[NSMutableArray alloc] init];
  for (ActivityViewControllerSection section = 0; section < ActivityViewControllerSectionNumItems; section++) {
    switch (section) {
      case ActivityViewControllerSectionLinks:
        [sections addObject:[self _testActionsForLinks]];
        break;

      case ActivityViewControllerSectionTextWithLinks:
        [sections addObject:[self _testActionsForTextWithLinks]];
        break;

      case ActivityViewControllerSectionPhoto:
        [sections addObject:[self _testActionsForPhoto]];
        break;

      case ActivityViewControllerSectionVideo:
        [sections addObject:[self _testActionsForVideo]];
        break;

      case ActivityViewControllerSectionMixedCases:
        [sections addObject:[self _testActionsForMixedCases]];
        break;

      case ActivityViewControllerSectionSLComposeViewController:
        [sections addObject:[self _testActionForSLComposeViewController]];
        break;

      case ActivityViewControllerSectionSDK:
        [sections addObject:[self _testActionsForSDK]];

      case ActivityViewControllerSectionNumItems:
        // NOTHING
        break;
    }
  }
  return sections;
}

- (_TestAction *)_testActionForIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section < _testActions.count) {
    NSArray *actionsWithinSection = _testActions[indexPath.section];
    if (indexPath.row < actionsWithinSection.count) {
      return actionsWithinSection[indexPath.row];
    }
  }
  return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return ActivityViewControllerSectionNumItems;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSArray *actionsWithinSection = _testActions[section];
  return actionsWithinSection.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  switch ((ActivityViewControllerSection)section) {
    case ActivityViewControllerSectionLinks:
      return @"Links";

    case ActivityViewControllerSectionTextWithLinks:
      return @"Links embedded in text";

    case ActivityViewControllerSectionPhoto:
      return @"Photo";

    case ActivityViewControllerSectionVideo:
      return @"Video";

    case ActivityViewControllerSectionMixedCases:
      return @"Mixed Cases";

    case ActivityViewControllerSectionSLComposeViewController:
      return @"SLCompose View Controller";

    case ActivityViewControllerSectionSDK:
      return @"SDK";

    case ActivityViewControllerSectionNumItems:
      return @"WTF?";
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kUIActivityViewControllerActionReuseIdentifier forIndexPath:indexPath];
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  _TestAction *testAction = [self _testActionForIndexPath:indexPath];
  cell.textLabel.text = testAction.text;
  cell.detailTextLabel.text = testAction.expectedToFail ? @"Failure expected" : @"";
  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  _TestAction *testAction = [self _testActionForIndexPath:indexPath];
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  #pragma clang diagnostic push
  #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  [testAction.target performSelector:testAction.action withObject:cell];
  #pragma clang diagnostic pop
}

#pragma mark - Link tests

- (NSArray *)_testActionsForLinks
{
  return @[
    [_TestAction testActionWithTarget:self action:@selector(_shareURLOnly:) text:@"NSURL only"],
    [_TestAction testActionWithTarget:self action:@selector(_shareURLPlusString:) text:@"NSURL + NSString"],
    [_TestAction testActionWithTarget:self action:@selector(_shareURLPlusQuote:) text:@"NSURL + Quote"],
    [_TestAction testActionWithTarget:self action:@selector(_shareImageAndURL:) text:@"NSURL + UIImage"],
    [_TestAction testActionWithTarget:self action:@selector(_shareActivityItemSource:) text:@"UIActivityItemSource"],
    [_TestAction testActionWithTarget:self action:@selector(_shareURLToAnimatedGIF:) text:@"URL to animated GIF"],
  ];
}

- (IBAction)_shareStringPlusString:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[_testString, _testURL.absoluteString]];
}

- (void)_shareURLPlusQuote:(id)sender
{
  if (FBSDKPlatformShareExtensionCanOpen()) {
    NSString *const appID = @"237759909591655"; // Facebook Messenger for iPhone
    NSString *const quote = @"I'd like to stay in touch with you on Messenger. You don't even need a Facebook account to join.";
    NSURL *const URL = [NSURL URLWithString:@"https://m.me/gi/AbYM3HUh6DXyab7Z/"];

    NSString *const initialText = FBSDKPlatformShareExtensionInitialText(appID, nil, quote);

    SLComposeViewController *const composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [composeViewController addURL:URL];
    [composeViewController setInitialText:initialText];
    [self presentViewController:composeViewController animated:YES completion:nil];
  }
}

- (IBAction)_shareURLPlusString:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[_testURL, _testString]];
}

- (IBAction)_shareURLOnly:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[_testURL]];
}

- (IBAction)_shareActivityItemSource:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[_testString, self]];
}

- (IBAction)_shareURLToAnimatedGIF:(id)sender
{
  NSURL *url = [NSURL URLWithString:@"https://media.giphy.com/media/XL8VIKV7hhROE/200.gif"];
  [self _presentActivityViewControllerForActivityItems:@[url]];
}

- (IBAction)_shareImageAndURL:(id)sender
{
  UIImage *image = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSURL *url = [NSURL URLWithString:@"http://www.apple.com"];
  [self _presentActivityViewControllerForActivityItems:@[image, url]];
}

#pragma mark - Plain text with links

- (NSArray *)_testActionsForTextWithLinks
{
  return @[
    [_TestAction testActionWithTarget:self action:@selector(_shareSingleURLAsText:) text:@"Single URL"],
    [_TestAction testActionWithTarget:self action:@selector(_shareURLWithSpammyText:) text:@"Single URL in spammy text"],
    [_TestAction testActionWithTarget:self action:@selector(_shareTextWithNoURL:) text:@"Text with no URL -- should be blank"],
    [_TestAction testActionWithTarget:self action:@selector(_shareMoreThanOneURL:) text:@"More than one URL -- share theonion.com"],
    [_TestAction testActionWithTarget:self action:@selector(_shareURLWithNoProtocol:) text:@"URL with no protocol"],
  ];
}

- (void)_shareSingleURLAsText:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[@"http://www.theonion.com"]];
}

- (void)_shareURLWithSpammyText:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[@"America's Finest News Source! #TheOnionKnows http://www.theonion.com"]];
}

- (void)_shareTextWithNoURL:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[@"Four score and seven years ago"]];
}

- (void)_shareMoreThanOneURL:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[@"I get my news from http://www.theonion.com and http://boingboing.net"]];
}

- (void)_shareURLWithNoProtocol:(id)sender
{
  [self _presentActivityViewControllerForActivityItems:@[@"apple.com"]];
}

#pragma mark - Photos

- (NSArray *)_testActionsForPhoto
{
  return @[
    [_TestAction testActionWithTarget:self action:@selector(_shareUIImage:) text:@"UI Image"],
    [_TestAction testActionWithTarget:self action:@selector(_shareUIImageFromCameraRoll:) text:@"UIImage from camera"],
    [_TestAction testActionWithTarget:self action:@selector(_shareNSDataWithJPEG:) text:@"NSData with JPEG"],
    [_TestAction testActionWithTarget:self action:@selector(_shareNSDataWithPNG:) text:@"NSData with PNG"],
    [_TestAction testActionWithTarget:self action:@selector(_shareBundleURL:) text:@"URL to bundle resource"],
  ];
}

- (void)_shareUIImage:(id)sender
{
  NSString *path = [NSBundle.mainBundle pathForResource:@"bugs_bunny-500x500" ofType:@"jpg"];
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  [self _presentActivityViewControllerForActivityItems:@[image]];
}

- (void)_shareUIImageFromCameraRoll:(id)sender
{
  NSString *path = [NSBundle.mainBundle pathForResource:@"IMG_2072" ofType:@"JPG"];
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  [self _presentActivityViewControllerForActivityItems:@[image]];
}

- (void)_shareNSDataWithJPEG:(id)sender
{
  UIImage *image = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSData *jpegData = UIImageJPEGRepresentation(image, 0.75f);
  [self _presentActivityViewControllerForActivityItems:@[jpegData]];
}

- (void)_shareNSDataWithPNG:(id)sender
{
  UIImage *image = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSData *pngData = UIImagePNGRepresentation(image);
  [self _presentActivityViewControllerForActivityItems:@[pngData]];
}

- (void)_shareBundleURL:(id)sender
{
  NSURL *imageURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"bugs_bunny-500x500" ofType:@"jpg"]];
  [self _presentActivityViewControllerForActivityItems:@[imageURL]];
}

#pragma mark - Videos

- (NSArray *)_testActionsForVideo
{
  return @[
    [_TestAction testActionWithTarget:self action:@selector(_shareVideoWithMP4:) text:@"Single mp4 Video"],
    [_TestAction testActionWithTarget:self action:@selector(_shareVideoWithMOV:) text:@"Single mov Video"],
    [_TestAction testActionWithTarget:self action:@selector(_shareVideoFromAssetsLibrary:) text:@"Video from assets library"],
  ];
}

- (void)_shareVideoWithMP4:(id)sender
{
  NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  [self _presentActivityViewControllerForActivityItems:@[videoURL]];
}

- (void)_shareVideoWithMOV:(id)sender
{
  NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"sample_sorenson" withExtension:@"mov"];
  [self _presentActivityViewControllerForActivityItems:@[videoURL]];
}

- (void)_shareVideoFromAssetsLibrary:(id)sender
{
  NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
  [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
    if (assetURL != nil) {
      [self _presentActivityViewControllerForActivityItems:@[assetURL]];
    } else {
      [self _showErrorMessage:[NSString stringWithFormat:@"Error copying video to assets library: %@", error]];
    }
  }];
}

#pragma mark - Mixed Cases

- (NSArray *)_testActionsForMixedCases
{
  return @[
    [_TestAction testActionWithTarget:self action:@selector(_sharePhotosAndVideos:) text:@"Photos and Videos"],
    [_TestAction testActionWithTarget:self action:@selector(_shareLinkImageText:) text:@"Link, Image and Plain Text"],
    [_TestAction testActionWithTarget:self action:@selector(_shareMultiPhotos:) text:@"Mixed type of images and urls -- 30 total"],
    [_TestAction testActionWithTarget:self action:@selector(_shareNegativeCase:) text:@"Share more than 30 images"],
    [_TestAction testActionWithTarget:self action:@selector(_shareTextWithHashTags:) text:@"Text with a hashtag"],
    [_TestAction testActionWithTarget:self action:@selector(_shareImageWithHashTags:) text:@"Image with a hashtag"],
  ];
}

- (void)_sharePhotosAndVideos:(id)sender
{
  UIImage *image = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
  [self _presentActivityViewControllerForActivityItems:@[videoURL, image]];
}

- (void)_shareLinkImageText:(id)sender
{
  UIImage *image = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSURL *url = [NSURL URLWithString:@"http://en.wikipedia.org/wiki/Bugs_Bunny"];
  [self _presentActivityViewControllerForActivityItems:@[url, image, @"Plain Text: Bugs Bunny is an animated cartoon character"]];
}

- (void)_shareMultiPhotos:(id)sender
{
  UIImage *image1 = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSData *image2 = UIImageJPEGRepresentation(image1, 0.9f);
  NSData *image3 = UIImagePNGRepresentation(image1);
  NSURL *url1 = [NSURL URLWithString:@"http://en.wikipedia.org/wiki/Bugs_Bunny"];
  NSURL *url2 = [NSURL URLWithString:@"http://www.spotify.com"];

  [self _presentActivityViewControllerForActivityItems:@[image1, image2, image3, url1, image1, image2, image3, url2, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3]];
}

- (void)_shareNegativeCase:(id)sender
{
  UIImage *image1 = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSData *image2 = UIImageJPEGRepresentation(image1, 0.9f);
  NSData *image3 = UIImagePNGRepresentation(image1);

  [self _presentActivityViewControllerForActivityItems:@[image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1, image2, image3, image1]];
}

- (void)_shareTextWithHashTags:(id)sender
{
  NSString *text = @"This is a string with an #AppProvidedHashtag";
  [self _presentActivityViewControllerForActivityItems:@[text]];
}

- (void)_shareImageWithHashTags:(id)sender
{
  NSData *image = UIImageJPEGRepresentation([UIImage imageNamed:@"bugs_bunny-500x500.jpg"], 0.9f);
  [self _presentActivityViewControllerForActivityItems:@[image, @"#TeamBugsBunny"]];
}

#pragma mark - SLComposeViewController

- (NSArray *)_testActionForSLComposeViewController
{
  return @[
    [_TestAction testActionWithTarget:self action:@selector(_shareSingleURLWithSLComposer:) text:@"Single URL"],
    [_TestAction testActionWithTarget:self action:@selector(_shareMultiURLWithSLComposer:) text:@"Multiple URL"],
    [_TestAction testActionWithTarget:self action:@selector(_shareTextAndURLWithSLComposer:) text:@"Text + URL"],
    [_TestAction testActionWithTarget:self action:@selector(_shareURLInTextWithSLComposer:) text:@"URL in Text"],
    [_TestAction testActionWithTarget:self action:@selector(_shareMultiPhotosWithSLComposer:) text:@"Multiple Photos"],
    [_TestAction testActionWithTarget:self action:@selector(_shareImageAndURLWithSLComposer:) text:@"NSURL + UIImage"],
    [_TestAction testActionWithTarget:self action:@selector(_shareMixedURLAndImageWithSLComposer:) text:@"Mix of URLs and Images"],
  ];
}

- (IBAction)_shareSingleURLWithSLComposer:(id)sender
{
  NSURL *url = [NSURL URLWithString:@"http://www.bing.com/images/search?q=bugs+bunny&qs=OS&sk=IM1&FORM=QBIR&pq=bugbunny&sc=8-8&sp=2&qs=OS&sk=IM1"];
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer addURL:url];
  [self presentViewController:composer animated:YES completion:NULL];
}

- (IBAction)_shareMultiURLWithSLComposer:(id)sender
{
  NSURL *url1 = [NSURL URLWithString:@"http://www.apple.com"];
  NSURL *url2 = [NSURL URLWithString:@"http://www.spotify.com"];
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer addURL:url1];
  [composer addURL:url2];
  [self presentViewController:composer animated:YES completion:NULL];
}

- (IBAction)_shareTextAndURLWithSLComposer:(id)sender
{
  NSURL *url = [NSURL URLWithString:@"https://www.youtube.com/watch?v=2vjPBrBU-TM"];
  NSString *string = @"This text should't show up";
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer setInitialText:string];
  [composer addURL:url];
  [self presentViewController:composer animated:YES completion:NULL];
}

- (IBAction)_shareURLInTextWithSLComposer:(id)sender
{
  NSString *string = @"Bugs Bunny is an animated cartoon character. http://en.wikipedia.org/wiki/Bugs_Bunny";
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer setInitialText:string];
  [self presentViewController:composer animated:YES completion:NULL];
}

- (IBAction)_shareMultiPhotosWithSLComposer:(id)sender
{
  UIImage *image1 = [UIImage imageNamed:@"f8_logo.jpg"];
  UIImage *image2 = [UIImage imageNamed:@"thumbs_up.jpg"];
  UIImage *image3 = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  UIImage *image4 = [UIImage imageNamed:@"f82011_logo.jpg"];
  UIImage *image5 = [UIImage imageNamed:@"hackbook-170.jpg"];
  UIImage *image6 = [UIImage imageNamed:@"hb_logo.jpg"];
  UIImage *image7 = [UIImage imageNamed:@"starwars_like.jpg"];
  UIImage *image8 = [UIImage imageNamed:@"iphone_connect_btn.jpg"];
  UIImage *image9 = [UIImage imageNamed:@"spacebook.jpg"];
  UIImage *image10 = [UIImage imageNamed:@"hbiOS.jpg"];
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer addImage:image1];
  [composer addImage:image2];
  [composer addImage:image3];
  [composer addImage:image4];
  [composer addImage:image5];
  [composer addImage:image6];
  [composer addImage:image7];
  [composer addImage:image8];
  [composer addImage:image9];
  [composer addImage:image10];
  [self presentViewController:composer animated:YES completion:NULL];
}

- (IBAction)_shareImageAndURLWithSLComposer:(id)sender
{
  UIImage *image = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  NSURL *url = [NSURL URLWithString:@"http://en.wikipedia.org/wiki/Bugs_Bunny"];
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer addImage:image];
  [composer addURL:url];
  [self presentViewController:composer animated:YES completion:NULL];
}

- (IBAction)_shareMixedURLAndImageWithSLComposer:(id)sender
{
  UIImage *image1 = [UIImage imageNamed:@"starwars_like.jpg"];
  UIImage *image2 = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  UIImage *image3 = [UIImage imageNamed:@"hack.png"];
  UIImage *image4 = [UIImage imageNamed:@"thumbs_up.jpg"];
  UIImage *image5 = [UIImage imageNamed:@"f82011_logo.jpg"];
  UIImage *image6 = [UIImage imageNamed:@"f8_logo.jpg"];
  NSURL *url1 = [NSURL URLWithString:@"http://www.starwars.com"];
  NSURL *url2 = [NSURL URLWithString:@"http://en.wikipedia.org/wiki/Bugs_Bunny"];
  SLComposeViewController *composer = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
  [composer addImage:image1];
  [composer addImage:image2];
  [composer addImage:image3];
  [composer addURL:url1];
  [composer addImage:image4];
  [composer addImage:image5];
  [composer addImage:image6];
  [composer addURL:url2];
  [self presentViewController:composer animated:YES completion:NULL];
}

#pragma mark - SDK

- (NSArray *)_testActionsForSDK
{
  return @[
    [_TestAction testActionWithTarget:self action:@selector(_shareSingleURLWithQuote:) text:@"URL with Quote"],
    [_TestAction testActionWithTarget:self action:@selector(_shareMultimediaSDK:) text:@"Multimedia (photos + Videos)"],
  ];
}

- (IBAction)_shareSingleURLWithQuote:(id)sender
{
  FBSDKShareLinkContent *linkContent = [FBSDKShareLinkContent new];
  linkContent.contentURL = [NSURL URLWithString:@"http://www.starwars.com"];
  linkContent.quote = @"May the force be with you";
  FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController:self
                                                                      content:linkContent
                                                                     delegate:nil];
  [dialog show];
}

- (IBAction)_shareMultimediaSDK:(id)sender
{
  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
    if (status != PHAuthorizationStatusAuthorized) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self _showErrorMessage:@"Photo Access is needed to share multimedia. Enable photo Access for Hackbook in Privacy/Photos"];
      });
      return;
    }
    NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"videoviewdemo" withExtension:@"mp4"];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:videoURL completionBlock:^(NSURL *assetURL, NSError *error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (assetURL != nil) {
          FBSDKShareMediaContent *content = [FBSDKShareMediaContent new];
          content.media = @[
            [[FBSDKSharePhoto alloc] initWithImage:[UIImage imageNamed:@"bugs_bunny-500x500.jpg"]
                                   isUserGenerated:YES],
            [[FBSDKShareVideo alloc] initWithVideoURL:assetURL previewPhoto:nil],
          ];
          FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] initWithViewController:self
                                                                              content:content
                                                                             delegate:self];
          [dialog show];
        } else {
          [self _showErrorMessage:[NSString stringWithFormat:@"Error copying video to assets library: %@", error]];
        }
      });
    }];
  }];
}

#pragma mark - UIActivityViewController Presentation

- (void)_presentActivityViewControllerForActivityItems:(NSArray *)activityItems
{
  UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
  activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
    if (activityError != nil) {
      ConsoleError(activityError, @"Did not complete the share");
    } else if (!completed) {
      ConsoleLog(@"The person cancelled the share.");
    } else {
      ConsoleSucceed(@"UIActivityViewController share succeeded");
    }
  };
  ConsoleLog(@"Presenting UIActivityViewController");
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    [self presentViewController:activityViewController animated:YES completion:NULL];
  } else {
    const int contentOffsetY = ((UITableView *)self.view).contentOffset.y + ((UITableView *)self.view).contentInset.top;
    UIPopoverController *popup = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
    [popup presentPopoverFromRect:CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 4 + contentOffsetY, 0, 0) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
  }
}

- (void)_showErrorMessage:(NSString *)error
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [self dismissViewControllerAnimated:NO completion:NULL];
  }];
  [alertController addAction:dismissAction];
  [self presentViewController:alertController animated:YES completion:NULL];
}

#pragma mark - UIActivityItemSource

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
  // This is a bug. [[NSURL alloc] init] returns nil, so we're not accurately reporting our type.
  // This is the only thing called prior to actually picking a share extension.
  // If I return a valid URL as a placeholder, everything works.
  return [[NSURL alloc] init];
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
  return _testURL;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(NSString *)activityType
{
  ConsoleLog(@"Reporting data type identifier for activity type %@", activityType);
  return (__bridge NSString *)kUTTypeURL;
}

#pragma mark - SDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
  ConsoleSucceed(@"Share succeeded");
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
  ConsoleError(error, @"Error Sharing");
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
  ConsoleLog(@"Share canceled");
}

@end
