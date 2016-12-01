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

@interface SCImagePicker () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, assign) CGRect rect;
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

- (void)presentFromRect:(CGRect)rect withViewController:(UIViewController *)viewController
{
    self.rect = rect;
    self.viewController = viewController;
    [self _presentActionSheet];
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertAction *takePhotoAction = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self _presentImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypeCamera];
        }];
        [alertController addAction:takePhotoAction];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIAlertAction *chooseExistingAction = [UIAlertAction actionWithTitle:@"Choose Existing" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self _presentImagePickerControllerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }];
        [alertController addAction:chooseExistingAction];
    }
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL];
        [alertController addAction:cancelAction];
    }
    [self _presentViewController:alertController];
}

- (void)_presentImagePickerControllerWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController = imagePickerController;
    imagePickerController.delegate = self;
    imagePickerController.sourceType = sourceType;
    [self _presentViewController:imagePickerController];
}

- (void)_presentViewController:(UIViewController *)viewController
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        viewController.modalPresentationStyle = UIModalPresentationPopover;
    }
    [self.viewController presentViewController:viewController animated:YES completion:NULL];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *presentationController =
        [viewController popoverPresentationController];
        presentationController.sourceView = self.viewController.view;
        presentationController.sourceRect = self.rect;
    }
}

@end
