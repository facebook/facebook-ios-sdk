/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
