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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "LegacyContextDialogPresenter.h"

 #import "FBSDKChooseContextContent.h"
 #import "FBSDKChooseContextDialog.h"
 #import "FBSDKChooseContextDialogFactory.h"
 #import "FBSDKContextDialogFactoryProtocols.h"
 #import "FBSDKCreateContextDialog.h"
 #import "FBSDKCreateContextDialogFactory.h"
 #import "FBSDKDialogProtocol.h"
 #import "FBSDKGamingContext.h"
 #import "FBSDKGamingServicesCoreKitImport.h"
 #import "FBSDKShowable.h"
 #import "FBSDKSwitchContextDialog.h"
 #import "FBSDKSwitchContextDialogFactory.h"

@interface FBSDKInternalUtility () <FBSDKWindowFinding>
@end

@interface LegacyContextDialogPresenter ()

@property (nonatomic) FBSDKWebDialog *webDialog;
@property (nonatomic) id<FBSDKCreateContextDialogMaking> createContextDialogFactory;
@property (nonatomic) id<FBSDKSwitchContextDialogMaking> switchContextDialogFactory;
@property (nonatomic) id<FBSDKChooseContextDialogMaking> chooseContextDialogFactory;

@end

@implementation LegacyContextDialogPresenter

+ (LegacyContextDialogPresenter *)shared
{
  static LegacyContextDialogPresenter *shared;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [self new];
  });
  return shared;
}

- (instancetype)init
{
  return [self initWithCreateContextDialogFactory:[FBSDKCreateContextDialogFactory new]
                       switchContextDialogFactory:[FBSDKSwitchContextDialogFactory new]
                       chooseContextDialogFactory:[FBSDKChooseContextDialogFactory new]];
}

- (instancetype)initWithCreateContextDialogFactory:(id<FBSDKCreateContextDialogMaking>)createContextDialogFactory
                        switchContextDialogFactory:(id<FBSDKSwitchContextDialogMaking>)switchContextDialogFactory
                        chooseContextDialogFactory:(id<FBSDKChooseContextDialogMaking>)chooseContextDialogFactory
{
  if ((self = [super init])) {
    _createContextDialogFactory = createContextDialogFactory;
    _switchContextDialogFactory = switchContextDialogFactory;
    _chooseContextDialogFactory = chooseContextDialogFactory;
  }
  return self;
}

 #pragma mark - Class Methods

+ (nullable FBSDKCreateContextDialog *)createContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                             delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  return (FBSDKCreateContextDialog *)[self.shared makeCreateContextDialogWithContent:content delegate:delegate];
}

- (id<FBSDKShowable>)makeCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                               delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  if (![FBSDKAccessToken currentAccessToken]) {
    return nil;
  }
  return [self.createContextDialogFactory makeCreateContextDialogWithContent:content
                                                                windowFinder:FBSDKInternalUtility.sharedUtility
                                                                    delegate:delegate];
}

+ (nullable NSError *)showCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  return [self.shared makeAndShowCreateContextDialogWithContent:content delegate:delegate];
}

- (nullable NSError *)makeAndShowCreateContextDialogWithContent:(FBSDKCreateContextContent *)content
                                                       delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  id<FBSDKShowable> dialog = [self makeCreateContextDialogWithContent:content delegate:delegate];
  if (dialog) {
    [dialog show];
    return nil;
  }
  NSError *tokenError = [FBSDKError
                         errorWithCode:FBSDKErrorAccessTokenRequired
                         message:@"A valid access token is required to launch the Dialog"];
  return tokenError;
}

+ (nullable FBSDKSwitchContextDialog *)switchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                             delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  return (FBSDKSwitchContextDialog *)[self.shared makeSwitchContextDialogWithContent:content delegate:delegate];
}

- (nullable id<FBSDKShowable>)makeSwitchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  if (![FBSDKAccessToken currentAccessToken]) {
    return nil;
  }
  return [self.switchContextDialogFactory makeSwitchContextDialogWithContent:content
                                                                windowFinder:FBSDKInternalUtility.sharedUtility
                                                                    delegate:delegate];
}

+ (nullable NSError *)showSwitchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  return [self.shared makeAndShowSwitchContextDialogWithContent:content delegate:delegate];
}

- (nullable NSError *)makeAndShowSwitchContextDialogWithContent:(FBSDKSwitchContextContent *)content
                                                       delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  id<FBSDKShowable> dialog = [self makeSwitchContextDialogWithContent:content
                                                             delegate:delegate];
  if (dialog) {
    [dialog show];
    return nil;
  }
  NSError *tokenError = [FBSDKError
                         errorWithCode:FBSDKErrorAccessTokenRequired
                         message:@"A valid access token is required to launch the Dialog"];
  return tokenError;
}

- (nullable id<FBSDKShowable>)makeChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  return [self.chooseContextDialogFactory makeChooseContextDialogWithContent:content
                                                                    delegate:delegate];
}

+ (FBSDKChooseContextDialog *)showChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                                        delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  FBSDKChooseContextDialog *dialog = [FBSDKChooseContextDialog dialogWithContent:content delegate:delegate];
  [dialog show];
  return dialog;
}

- (id<FBSDKShowable>)makeAndShowChooseContextDialogWithContent:(FBSDKChooseContextContent *)content
                                                      delegate:(id<FBSDKContextDialogDelegate>)delegate
{
  id<FBSDKShowable> dialog = [self makeChooseContextDialogWithContent:content delegate:delegate];
  [dialog show];
  return dialog;
}

@end

#endif
