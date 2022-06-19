// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@import FBSDKShareKit;

#import "TestListViewController.h"

void SetLinkContentURL(FBSDKShareLinkContent *linkContent);

@interface SharingDialogViewController : TestListViewController <FBSDKSharingDelegate>

- (NSString *)appEventsPrefix;
- (id<FBSDKSharingDialog>)buildDialog;
- (void)shareUsingContentBlock:(id<FBSDKSharingContent>(^)(void))contentBlock;
- (BOOL)validateShareContent:(id<FBSDKSharingContent>)shareContent;
- (NSUInteger)photosToShare;

- (IBAction)shareAllContent:(id)sender;
- (IBAction)shareText:(id)sender;
- (IBAction)shareLink:(id)sender;
- (IBAction)shareLinkPlusHashtag:(id)sender;
- (IBAction)shareLinkPlusAppFriend:(id)sender;
- (IBAction)shareLinkPlusPlaceTag:(id)sender;
- (IBAction)shareLinkPlusQuote:(id)sender;
- (IBAction)shareURL:(id)sender;

- (IBAction)sharePhotos:(UIButton *)sender;
- (IBAction)sharePhotoFromLibrary:(UIButton *)sender;
- (IBAction)sharePhotoPlusHashtag:(id)sender;
- (IBAction)sharePhotoPlusAppFriend:(id)sender;
- (IBAction)sharePhotoPlusPlaceTag:(id)sender;

- (IBAction)shareVideo:(id)sender;
- (IBAction)shareVideoFromLibrary:(id)sender;
- (IBAction)shareVideoPlusHashtag:(id)sender;
- (IBAction)shareVideoPlusAppFriend:(id)sender;
- (IBAction)shareVideoPlusPlaceTag:(id)sender;

- (IBAction)shareMultimedia:(id)sender;

@end
