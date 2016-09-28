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

#import <Foundation/Foundation.h>

#import <AccountKit/AccountKit.h>

@class ReverbTheme;

@protocol ReverbUIManagerDelegate;

@interface ReverbUIManager : NSObject <AKFAdvancedUIManager>

- (instancetype)initWithConfirmButtonType:(AKFButtonType)confirmButtonType
                          entryButtonType:(AKFButtonType)entryButtonType
                                loginType:(AKFLoginType)loginType
                             textPosition:(AKFTextPosition)textPosition
                                    theme:(ReverbTheme *)theme
                                 delegate:(id<ReverbUIManagerDelegate>)delegate
NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@property (nonatomic, assign, readonly) AKFButtonType confirmButtonType;
@property (nonatomic, weak) id<ReverbUIManagerDelegate> delegate;
@property (nonatomic, assign, readonly) AKFButtonType entryButtonType;
@property (nonatomic, assign, readonly) AKFLoginType loginType;
@property (nonatomic, assign, readonly) AKFTextPosition textPosition;
@property (nonatomic, copy, readonly) ReverbTheme *theme;

@end

@protocol ReverbUIManagerDelegate <NSObject>

- (void)reverbUIManager:(ReverbUIManager *)reverbUIManager didSwitchLoginType:(AKFLoginType)loginType;

@end
