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

#import "SCMealPicker.h"

@interface SCMealPicker () <UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIAlertView *alertView;
@end

@implementation SCMealPicker

#pragma mark - Object Lifecycle

- (void)dealloc
{
    _actionSheet.delegate = nil;
    _alertView.delegate = nil;
}

#pragma mark - Properties

- (void)setActionSheet:(UIActionSheet *)actionSheet
{
    if (_actionSheet != actionSheet) {
        _actionSheet.delegate = nil;
        _actionSheet = actionSheet;
    }
}

- (void)setAlertView:(UIAlertView *)alertView
{
    if (_alertView != alertView) {
        _alertView.delegate = nil;
        _alertView = alertView;
    }
}

#pragma mark - Public API

- (void)presentInView:(UIView *)view
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a Meal"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    self.actionSheet = actionSheet;
    for (NSString *mealType in [self _mealTypes]) {
        [actionSheet addButtonWithTitle:mealType];
    }
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet showInView:view];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSAssert1(actionSheet == self.actionSheet, @"Unexpected actionSheet: %@", actionSheet);
    self.actionSheet = nil;
    if (buttonIndex == 0) {
        // They chose manual entry so prompt the user for an entry.
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                            message:@"What are you eating?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"OK", nil];
        self.alertView = alertView;
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeSentences;
        [alertView show];
    } else if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self.delegate mealPickerDidCancel:self];
    } else {
        [self.delegate mealPicker:self didSelectMealType:[self _mealTypes][buttonIndex]];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSAssert1(alertView == self.alertView, @"Unexpected alertView: %@", alertView);
    self.alertView = nil;
    if (alertView.cancelButtonIndex == buttonIndex) {
        [self.delegate mealPickerDidCancel:self];
    } else {
        [self.delegate mealPicker:self didSelectMealType:[alertView textFieldAtIndex:0].text];
    }
}

#pragma mark - Helper Methods

- (NSArray *)_mealTypes
{
    static NSArray *_mealTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _mealTypes = @[
                       @"< Write Your Own >",
                       @"Cheeseburger",
                       @"Pizza",
                       @"Hotdog",
                       @"Italian",
                       @"French",
                       @"Chinese",
                       @"Thai",
                       @"Indian",
                       ];
    });
    return _mealTypes;
}

@end
