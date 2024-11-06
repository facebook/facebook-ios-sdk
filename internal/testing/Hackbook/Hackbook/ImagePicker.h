// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@protocol ImagePickerDelegate;

@interface ImagePicker : NSObject

@property (nonatomic, weak) id<ImagePickerDelegate> delegate;

- (void)presentWithViewController:(UIViewController *)viewController sourceView:(UIView *)view sourceRect:(CGRect)rect;

@end

@protocol ImagePickerDelegate

- (void)imagePicker:(ImagePicker *)imagePicker didSelectImage:(UIImage *)image;
- (void)imagePickerDidCancel:(ImagePicker *)imagePicker;

@end
