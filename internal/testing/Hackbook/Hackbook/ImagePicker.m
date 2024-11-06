// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ImagePicker.h"

#import <UIKit/UIKit.h>

@interface ImagePicker () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIViewController *viewController;
@end

@implementation ImagePicker

#pragma mark - Object Lifecycle

- (void)dealloc
{
  _imagePickerController.delegate = nil;
}

#pragma mark - Properties

- (void)setImagePickerController:(UIImagePickerController *)imagePickerController
{
  if (_imagePickerController != imagePickerController) {
    _imagePickerController.delegate = nil;
    _imagePickerController = imagePickerController;
  }
}

#pragma mark - Public API

- (void)presentWithViewController:(UIViewController *)viewController sourceView:(UIView *)view sourceRect:(CGRect)rect
{
  self.viewController = viewController;
  self.rect = rect;
  self.view = view;
  [self _presentActionSheet];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)  imagePickerController:(UIImagePickerController *)picker
  didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info
{
  NSAssert1(picker == self.imagePickerController, @"Unexpected imagePickerController: %@", picker);
  [self.viewController dismissViewControllerAnimated:YES completion:NULL];
  self.viewController = nil;
  self.imagePickerController = nil;

  UIImage *image = info[UIImagePickerControllerOriginalImage];
  [self.delegate imagePicker:self didSelectImage:image];
}

#pragma mark - Helper Methods

- (void)_openImagePickerWithSource:(UIImagePickerControllerSourceType)sourceType
{
  UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
  self.imagePickerController = imagePickerController;
  imagePickerController.delegate = self;
  #if TARGET_OS_SIMULATOR
  if (sourceType == UIImagePickerControllerSourceTypeCamera) {
    // If its the simulator, camera is no good
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Camera not supported in simulator."
                                                                         message:@"(>'_')>"
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [actionSheet addAction:cancelAction];
    actionSheet.popoverPresentationController.sourceView = self.view;
    [self.viewController presentViewController:actionSheet animated:YES completion:nil];
    self.imagePickerController = nil;
    [self.delegate imagePickerDidCancel:self];
    return;
  }
  #endif
  
  imagePickerController.sourceType = sourceType;
  if (imagePickerController) {
    UIView *view = self.view;
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
      // This is a hack. Let the action sheet dismiss before presenting the popover controller.
      dispatch_async(dispatch_get_main_queue(), ^{
        imagePickerController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverController = imagePickerController.popoverPresentationController;
        popoverController.sourceView = view;
        popoverController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        [self.viewController presentViewController:imagePickerController animated:YES completion:nil];
      });
    } else {
      imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
      [self.viewController presentViewController:imagePickerController animated:YES completion:NULL];
    }
  }
}

- (void)_cancelSelection
{
  [self.delegate imagePickerDidCancel:self];
}

- (void)_presentActionSheet
{
  __weak __typeof(self) weakSelf = self;
  UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
  actionSheet.popoverPresentationController.sourceView = self.view;
  UIAlertAction *takePhotoAction = [UIAlertAction actionWithTitle:@"Take Photo"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
    [weakSelf _openImagePickerWithSource:UIImagePickerControllerSourceTypeCamera];
  }];
  UIAlertAction *chooseExistingAction = [UIAlertAction actionWithTitle:@"Choose Existing"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
    [weakSelf _openImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction *action) {
    [weakSelf _cancelSelection];
  }];
  [actionSheet addAction:takePhotoAction];
  [actionSheet addAction:chooseExistingAction];
  [actionSheet addAction:cancelAction];
  [self.viewController presentViewController:actionSheet animated:YES completion:nil];
}

@end
