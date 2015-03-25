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

#import "SIMainViewController.h"

#import <MessageUI/MessageUI.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

#import "SIMainView.h"
#import "SIPhoto.h"

@interface SIMainViewController () <
  MFMailComposeViewControllerDelegate,
  MFMessageComposeViewControllerDelegate,
  UIActionSheetDelegate,
  FBSDKSharingDelegate>
@property (nonatomic, strong) UIActionSheet *shareActionSheet;
@end

@implementation SIMainViewController
{
  FBSDKLikeButton *_photoLikeButton;
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
  self.loginButton.publishPermissions = @[@"publish_actions"];

  _photoLikeButton = [[FBSDKLikeButton alloc] init];
  _photoLikeButton.objectType = FBSDKLikeObjectTypeOpenGraph;
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_photoLikeButton];

  self.pageLikeControl.likeControlAuxiliaryPosition = FBSDKLikeControlAuxiliaryPositionBottom;
  self.pageLikeControl.likeControlHorizontalAlignment = FBSDKLikeControlHorizontalAlignmentCenter;
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

  FBSDKShareDialog *facebookShareDialog = [self getShareDialogWithContentURL:[self _currentPhoto].objectURL];
  if ([facebookShareDialog canShow]) {
    [shareActionSheet addButtonWithTitle:@"Share on Facebook"];
  }
  FBSDKMessageDialog *messengerShareDialog = [self getMessageDialogWithContentURL:[self _currentPhoto].objectURL];
  if ( [messengerShareDialog canShow]) {
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
    FBSDKShareDialog *shareDialog = [self getShareDialogWithContentURL:photo.objectURL];
    shareDialog.delegate = self;
    [shareDialog show];
  } else if ([buttonTitle isEqualToString:@"Send with Messenger"]) {
    FBSDKMessageDialog *shareDialog = [self getMessageDialogWithContentURL:photo.objectURL];
    shareDialog.delegate = self;
    [shareDialog show];
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

- (FBSDKShareLinkContent *)getShareLinkContentWithContentURL:(NSURL *)objectURL
{
  FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
  content.contentURL = objectURL;
  return content;
}

- (FBSDKShareDialog *)getShareDialogWithContentURL:(NSURL *)objectURL
{
  FBSDKShareDialog *shareDialog = [[FBSDKShareDialog alloc] init];
  shareDialog.shareContent = [self getShareLinkContentWithContentURL:objectURL];
  return shareDialog;
}

- (FBSDKMessageDialog *)getMessageDialogWithContentURL:(NSURL *)objectURL
{
  FBSDKMessageDialog *shareDialog = [[FBSDKMessageDialog alloc] init];
  shareDialog.shareContent = [self getShareLinkContentWithContentURL:objectURL];
  return shareDialog;
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
  _photoLikeButton.objectID = photo.objectURL.absoluteString;
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
  NSLog(@"completed share:%@", results);
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
  NSLog(@"sharing error:%@", error);
  NSString *message = error.userInfo[FBSDKErrorLocalizedDescriptionKey] ?:
  @"There was a problem sharing, please try again later.";
  NSString *title = error.userInfo[FBSDKErrorLocalizedTitleKey] ?: @"Oops!";

  [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
  NSLog(@"share cancelled");
}
@end
