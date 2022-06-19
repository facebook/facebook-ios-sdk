// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

#import "SharingDialogViewController.h"

@interface NativeShareDialogTestViewController : SharingDialogViewController

@property (nonatomic, weak) IBOutlet UIBarButtonItem *modeButton;

- (IBAction)selectMode:(id)sender;

@end
