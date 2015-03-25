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

#import "SCImagePicker.h"

@interface SCImagePicker () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIViewController *viewController;
@end

@implementation SCImagePicker

#pragma mark - Object Lifecycle

- (void)dealloc
{
    _actionSheet.delegate = nil;
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

- (void)setActionSheet:(UIActionSheet *)actionSheet
{
    if (_actionSheet != actionSheet) {
        _actionSheet.delegate = nil;
        _actionSheet = actionSheet;
    }
}

#pragma mark - Public API

- (void)presentFromRect:(CGRect)rect inView:(UIView *)view
{
    self.rect = rect;
    self.view = view;
    [self _presentActionSheet];
}

- (void)presentWithViewController:(UIViewController *)viewController
{
    self.viewController = viewController;
    [self _presentActionSheet];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSAssert1(actionSheet == self.actionSheet, @"Unexpected actionSheet: %@", actionSheet);
    self.actionSheet = nil;
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self.delegate imagePickerDidCancel:self];
    } else {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController = imagePickerController;
        imagePickerController.delegate = self;
        switch (buttonIndex) {
            case 0:{
#if TARGET_IPHONE_SIMULATOR
                // If its the simulator, camera is no good
                [[[UIAlertView alloc] initWithTitle:@"Camera not supported in simulator."
                                            message:@"(>'_')>"
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                self.imagePickerController = nil;
                [self.delegate imagePickerDidCancel:self];
                return;
#else
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
#endif
                break;
            }
            case 1:{
                imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                break;
            }
            default:{
                NSAssert1(NO, @"Unexpected button index: %li", (long)buttonIndex);
                break;
            }
        }
        if (imagePickerController) {
            UIView *view = self.view;
            if (view) {
                UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
                self.popoverController = popoverController;
                [popoverController presentPopoverFromRect:self.rect
                                                   inView:view
                                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                                 animated:YES];
            } else {
                imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
                [self.viewController presentViewController:imagePickerController animated:YES completion:NULL];
            }
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)imagePickerController
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    NSAssert1(imagePickerController == self.imagePickerController, @"Unexpected imagePickerController: %@", imagePickerController);
    [self.popoverController dismissPopoverAnimated:YES];
    self.popoverController = nil;
    [self.viewController dismissViewControllerAnimated:YES completion:NULL];
    self.viewController = nil;
    self.imagePickerController = nil;
    [self.delegate imagePicker:self didSelectImage:image];
}

#pragma mark - Helper Methods

- (void)_presentActionSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"Take Photo",
                                  @"Choose Existing",
                                  nil];
    self.actionSheet = actionSheet;
    [actionSheet showInView:self.view ?: self.viewController.view];
}

@end
