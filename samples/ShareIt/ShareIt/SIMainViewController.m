/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SIMainViewController.h"

#import <MessageUI/MessageUI.h>

#import "SIMainView.h"
#import "SIPhoto.h"

@interface SIMainViewController ()
<MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) UIActionSheet *shareActionSheet;
@end

@implementation SIMainViewController
{
  FBLikeControl *_photoLikeControl;
  NSArray *_photos;
}

#pragma mark - Class Methods

+ (NSArray *)demoPhotos
{
  return @[
           [SIPhoto photoWithObjectURL:[NSURL URLWithString:@"http://shareitexampleapp.parseapp.com/goofy/"]
                                 title:@"Make a Goofy Face"
                                rating:5
                                 image:[UIImage imageNamed:@"Goofy"]],
           [SIPhoto photoWithObjectURL:[NSURL URLWithString:@"http://shareitexampleapp.parseapp.com/viking/"]
                                 title:@"Happy Viking, Happy Liking"
                                rating:3
                                 image:[UIImage imageNamed:@"Viking"]],
           [SIPhoto photoWithObjectURL:[NSURL URLWithString:@"http://shareitexampleapp.parseapp.com/liking/"]
                                 title:@"Happy Liking, Happy Viking"
                                rating:4
                                 image:[UIImage imageNamed:@"Liking"]],
           ];
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
  _shareActionSheet.delegate = nil;
}

#pragma mark - Properties

- (void)setShareActionSheet:(UIActionSheet *)shareActionSheet
{
  if (![_shareActionSheet isEqual:shareActionSheet]) {
    _shareActionSheet.delegate = nil;
    _shareActionSheet = shareActionSheet;
  }
}

#pragma mark - View Management

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.loginView.publishPermissions = @[@"publish_actions"];

  _photoLikeControl = [[FBLikeControl alloc] init];
  _photoLikeControl.likeControlStyle = FBLikeControlStyleButton;
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_photoLikeControl];

  self.pageLikeControl.likeControlAuxiliaryPosition = FBLikeControlAuxiliaryPositionBottom;
  self.pageLikeControl.likeControlHorizontalAlignment = FBLikeControlHorizontalAlignmentCenter;
  self.pageLikeControl.objectID = @"shareitexampleapp";

  [self _configurePhotos];
}

#pragma mark - Sharing

- (void)share:(id)sender
{
  UIActionSheet *shareActionSheet = self.shareActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                                        delegate:self
                                                                               cancelButtonTitle:nil
                                                                          destructiveButtonTitle:nil
                                                                               otherButtonTitles:nil];

  if ([MFMailComposeViewController canSendMail]) {
    [shareActionSheet addButtonWithTitle:@"Mail"];
  }

  if ([MFMessageComposeViewController canSendAttachments]) {
    [shareActionSheet addButtonWithTitle:@"Message"];
  }

  FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:[self _currentPhoto].objectURL
                                                                 name:nil
                                                              caption:nil
                                                          description:nil
                                                              picture:nil];
  if ([FBDialogs canPresentShareDialogWithParams:params]) {
    [shareActionSheet addButtonWithTitle:@"Share on Facebook"];
  }

  if ([FBDialogs canPresentMessageDialogWithParams:params]) {
    [shareActionSheet addButtonWithTitle:@"Send with Messenger"];
  }

  [shareActionSheet addButtonWithTitle:@"Cancel"];
  shareActionSheet.cancelButtonIndex = shareActionSheet.numberOfButtons - 1;
  [shareActionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (_shareActionSheet != actionSheet) {
    return;
  }

  SIPhoto *photo = [self _currentPhoto];

  NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
  if ([buttonTitle isEqualToString:@"Mail"]) {
    [self _sendMailWithPhoto:photo];
  } else if ([buttonTitle isEqualToString:@"Message"]) {
    [self _sendMessageWithPhoto:photo];
  } else if ([buttonTitle isEqualToString:@"Share on Facebook"]) {
    [FBDialogs presentShareDialogWithLink:photo.objectURL handler:NULL];
  } else if ([buttonTitle isEqualToString:@"Send with Messenger"]) {
    [FBDialogs presentMessageDialogWithLink:photo.objectURL handler:NULL];
  }

  _shareActionSheet = nil;
}

- (void)_sendMailWithPhoto:(SIPhoto *)photo
{
  MFMailComposeViewController *viewController = [[MFMailComposeViewController alloc] init];
  viewController.mailComposeDelegate = self;
  [viewController setSubject:@"Share It: Photo"];
  [viewController setMessageBody:photo.title isHTML:NO];
  NSData *data = UIImageJPEGRepresentation(photo.image, 1.0);
  [viewController addAttachmentData:data mimeType:@"image/jpeg" fileName:@"image.jpg"];
  [self presentViewController:viewController animated:YES completion:NULL];
}

- (void)_sendMessageWithPhoto:(SIPhoto *)photo
{
  MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
  viewController.messageComposeDelegate = self;
  NSData *data = UIImageJPEGRepresentation(photo.image, 1.0);
  viewController.body = photo.title;
  [viewController addAttachmentData:data typeIdentifier:@"public.jpeg" filename:@"image.jpg"];
  [self presentViewController:viewController animated:YES completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
  [controller dismissViewControllerAnimated:YES completion:NULL];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
  [controller dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Paging

- (IBAction)changePage:(id)sender
{
  UIScrollView *scrollView = self.scrollView;
  CGFloat x = floorf(self.pageControl.currentPage * scrollView.frame.size.width);
  [scrollView setContentOffset:CGPointMake(x, 0) animated:YES];
  [self _updateViewForCurrentPage];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView.isDragging || scrollView.isDecelerating){
    UIPageControl *pageControl = self.pageControl;
    pageControl.currentPage = floorf(scrollView.contentOffset.x /
                                     (scrollView.contentSize.width / pageControl.numberOfPages));
    [self _updateViewForCurrentPage];
  }
}

#pragma mark - Helper Methods

- (void)_configurePhotos
{
  _photos = [[self class] demoPhotos];
  [self _updateViewForCurrentPage];
  [self _mainView].images = [_photos valueForKeyPath:@"image"];
}

- (SIPhoto *)_currentPhoto
{
  return _photos[self.pageControl.currentPage];
}

- (SIMainView *)_mainView
{
  UIView *view = self.view;
  return ([view isKindOfClass:[SIMainView class]] ? (SIMainView *)view : nil);
}

- (void)_updateViewForCurrentPage
{
  SIPhoto *photo = [self _currentPhoto];
  [self _mainView].photo = photo;
  _photoLikeControl.objectID = photo.objectURL.absoluteString;
}

@end
