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

#import "LegacyContextDialogPresenter.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBSDKCreateContextDialogMaking;
@protocol FBSDKSwitchContextDialogMaking;
@protocol FBSDKChooseContextDialogMaking;
@protocol FBSDKShowable;
@class FBSDKCreateContextDialog;

@interface LegacyContextDialogPresenter (Testing)

@property (class, nonatomic, readonly) LegacyContextDialogPresenter *shared;
@property (nonatomic) id<FBSDKCreateContextDialogMaking> createContextDialogFactory;
@property (nonatomic) id<FBSDKSwitchContextDialogMaking> switchContextDialogFactory;
@property (nonatomic) id<FBSDKChooseContextDialogMaking> chooseContextDialogFactory;

- (instancetype)initWithCreateContextDialogFactory:(id<FBSDKCreateContextDialogMaking>)createContextDialogFactory
                        switchContextDialogFactory:(id<FBSDKSwitchContextDialogMaking>)switchContextDialogFactory
                        chooseContextDialogFactory:(id<FBSDKChooseContextDialogMaking>)chooseContextDialogFactory;

- (nullable id<FBSDKShowable>)makeCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate;
- (nullable NSError *)makeAndShowCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                       delegate:(id<FBSDKContextDialogDelegate>)delegate;
- (nullable id<FBSDKShowable>)makeSwitchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate;
- (nullable NSError *)makeAndShowSwitchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                       delegate:(id<FBSDKContextDialogDelegate>)delegate;
- (nullable id<FBSDKShowable>)makeChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate;
- (id<FBSDKShowable>)makeAndShowChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                                      delegate:(id<FBSDKContextDialogDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
