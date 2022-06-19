// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#ifndef RELEASED_SDK_ONLY

@import FBSDKGamingServicesKit;

#import "GamingServicesCellController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

@import FBSDKCoreKit;
@import FBSDKShareKit;

#import "Console.h"

static NSString *const kCellIdentifer = @"gaming-services-cell";

@interface MediaPickerDelegate : NSObject <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, copy) void (^callback)(id media);
@end

@interface ContextDialogDelegate : NSObject <FBSDKContextDialogDelegate>
@end

@implementation MediaPickerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
  __weak typeof(self) weakSelf = self;
  [picker dismissViewControllerAnimated:true completion:^{
    weakSelf.callback(
      info[UIImagePickerControllerOriginalImage]
      ?: [info objectForKey:UIImagePickerControllerMediaURL]
    );
  }];
}

@end

#pragma mark - FBSDKContextDialogDelegate
@implementation ContextDialogDelegate

- (void)contextDialogDidComplete:(id<FBSDKContextDialogDelegate>)contextDialog;
{
  ConsoleSucceed(@"Current context updated with context id: %@ and contextSize: %ld", FBSDKGamingContext.currentContext.identifier, (long)FBSDKGamingContext.currentContext.size);
}

- (void)contextDialog:(id<FBSDKContextDialogDelegate>)contextDialog didFailWithError:(NSError *)error
{
  ConsoleError(error, @"Error");
}

- (void)contextDialogDidCancel:(id<FBSDKContextDialogDelegate>)contextDialog
{
  ConsoleLog(@"Dialog cancelled");
}

@end

static void UploadImage(UIImage *image)
{
  if (![image isKindOfClass:[UIImage class]]) {
    ConsoleError([NSError new], @"Bad Image passed to Image Upload");
    return;
  }

  FBSDKGamingImageUploaderConfiguration *config =
  [[FBSDKGamingImageUploaderConfiguration alloc]
   initWithImage:image
   caption:@"Cool Photo"
   shouldLaunchMediaDialog:YES];

  [FBSDKGamingImageUploader
   uploadImageWithConfiguration:config
   completion:^(BOOL success, id result, NSError *_Nullable error) {
     dispatch_async(dispatch_get_main_queue(), ^{
       if (!success || error) {
         ConsoleError(error, @"Failed to upload Image");
       } else {
         ConsoleSucceed(@"Image Upload Complete %@", result);
       }
     });
   }
   andProgressHandler:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
     dispatch_async(dispatch_get_main_queue(), ^{
       const float progress = (float) totalBytesSent / totalBytesExpectedToSend;
       ConsoleLog(@"Upload Progress %.02f %lldb/%lldb", progress, totalBytesSent, totalBytesExpectedToSend);
     });
   }];
}

static void UploadVideo(NSURL *videoURL)
{
  if (![videoURL isKindOfClass:[NSURL class]]) {
    ConsoleError([NSError new], @"Bad URL passed to Video Upload");
    return;
  }

  FBSDKGamingVideoUploaderConfiguration *config =
  [[FBSDKGamingVideoUploaderConfiguration alloc]
   initWithVideoURL:videoURL
   caption:@"Cool Video"];

  [FBSDKGamingVideoUploader
   uploadVideoWithConfiguration:config
   completion:^(BOOL success, id result, NSError *_Nullable error) {
     dispatch_async(dispatch_get_main_queue(), ^{
       if (!success || error) {
         ConsoleError(error, @"Failed to upload Video");
       } else {
         ConsoleSucceed(@"Video Upload Complete %@", result);
       }
     });
   }
   andProgressHandler:^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
     dispatch_async(dispatch_get_main_queue(), ^{
       const float progress = (float) totalBytesSent / totalBytesExpectedToSend;
       ConsoleLog(@"Upload Progress %.02f %lldb/%lldb", progress, totalBytesSent, totalBytesExpectedToSend);
     });
   }];
}

static void LaunchMediaPicker(NSString *type)
{
  static MediaPickerDelegate *mediaDelegate;
  if (mediaDelegate == nil) {
    mediaDelegate = [MediaPickerDelegate new];
  }

  UIImagePickerController *const picker = [UIImagePickerController new];
  picker.delegate = mediaDelegate;
  picker.modalPresentationStyle = UIModalPresentationCurrentContext;

  if ([type isEqualToString:@"VIDEO"]) {
    picker.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeAVIMovie, (NSString *)kUTTypeVideo, (NSString *)kUTTypeMPEG4];
    picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    mediaDelegate.callback = ^(id media) {
      UploadVideo(media);
    };
  } else {
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaDelegate.callback = ^(id media) {
      UploadImage(media);
    };
  }

  [[UIApplication sharedApplication].delegate.window.rootViewController
   presentViewController:picker
   animated:true
   completion:nil];
}

void GamingServicesRegisterCells(UITableView *tableView)
{
  [tableView
   registerClass:UITableViewCell.class
   forCellReuseIdentifier:kCellIdentifer];
}

UITableViewCell *GamingServicesConfiguredCell(NSIndexPath *indexPath, UITableView *tableView)
{
  UITableViewCell *const cell =
  [tableView
   dequeueReusableCellWithIdentifier:kCellIdentifer
   forIndexPath:indexPath];

  switch ((GamingServicesCellRow) indexPath.row) {
    case GamingServicesCellRowFriendFinder:
      cell.textLabel.text = @"Launch Friend Finder";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;

    case GamingServicesCellRowUploadPhoto:
      cell.textLabel.text = @"Upload Photo";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;

    case GamingServicesCellRowUploadVideo:
      cell.textLabel.text = @"Upload Video";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;

    case GamingServicesCellRowOpenGamingGroup:
      cell.textLabel.text = @"Open Gaming Group";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    case GamingServicesCellRowCustomUpdate:
      cell.textLabel.text = @"Custom Update/Context APIs";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    case GamingServicesCellRowTournaments:
      cell.textLabel.text = @"Tournaments";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
  }

  return cell;
}

void GamingServicesDidSelectCell(GamingServicesCellRow row)
{
  switch (row) {
    case GamingServicesCellRowFriendFinder:
      [FBSDKFriendFinderDialog
       launchFriendFinderDialogWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
         if (!success || error) {
           ConsoleError(error, @"Failed to launch Friend Finder");
         } else {
           ConsoleSucceed(@"Friend Finding Complete");
         }
       }];
      break;

    case GamingServicesCellRowUploadPhoto:
      LaunchMediaPicker(@"IMAGE");
      break;

    case GamingServicesCellRowUploadVideo:
      UploadVideo(
        [NSURL
         fileURLWithPath:
         [[NSBundle mainBundle]
          pathForResource:@"hk-video"
          ofType:@"mp4"]]
      );
      break;

    case GamingServicesCellRowOpenGamingGroup:
      [FBSDKGamingGroupIntegration openGroupPageWithCompletionHandler:^(BOOL success, NSError *_Nullable error) {
        if (!success || error) {
          ConsoleError(error, @"Failed to open Gaming Group");
        } else {
          ConsoleSucceed(@"Gaming Group Open Complete");
        }
      }];
      break;
    case GamingServicesCellRowCustomUpdate:
      break;
    case GamingServicesCellRowTournaments:
      break;
  }
}

#endif
