// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@protocol ImagePickerDelegate;

@interface ImagePicker : NSObject

@property (nonatomic, weak) id<ImagePickerDelegate> delegate;

- (void)presentFromRect:(CGRect)rect inView:(UIView *)view;
- (void)presentWithViewController:(UIViewController *)viewController;

@end

@protocol ImagePickerDelegate

- (void)imagePicker:(ImagePicker *)imagePicker didSelectImage:(UIImage *)image;
- (void)imagePickerDidCancel:(ImagePicker *)imagePicker;

@end
