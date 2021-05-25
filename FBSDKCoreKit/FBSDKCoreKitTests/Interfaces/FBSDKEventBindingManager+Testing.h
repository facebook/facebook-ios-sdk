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

#import "FBSDKEventBindingManager.h"

@protocol FBSDKSwizzling;
@protocol FBSDKEventLogging;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKEventBindingManager (Testing)

@property (nonatomic) BOOL isStarted;
@property (nullable, nonatomic) NSMutableDictionary *reactBindings;
@property (nonatomic, readonly) NSSet *validClasses;
@property (nonatomic) BOOL hasReactNative;
@property (nullable, nonatomic) NSArray<FBSDKEventBinding *> *eventBindings;
@property (nullable, nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonnull, nonatomic) id<FBSDKEventLogging> eventLogger;

- (instancetype)initWithJSON:(NSDictionary *)dict
                    swizzler:(Class<FBSDKSwizzling>)swizzler
                 eventLogger:(id<FBSDKEventLogging>)eventLogger;
- (void)start;
- (void)handleReactNativeTouchesWithHandler:(nullable id)handler
                                    command:(nullable SEL)command
                                    touches:(id)touches
                                  eventName:(id)eventName;
- (void)handleDidSelectRowWithBindings:(NSArray<FBSDKEventBinding *> *)bindings
                                target:(nullable id)target
                               command:(nullable SEL)command
                             tableView:(UITableView *)tableView
                             indexPath:(NSIndexPath *)indexPath;
- (void)handleDidSelectItemWithBindings:(NSArray<FBSDKEventBinding *> *)bindings
                                 target:(nullable id)target
                                command:(nullable SEL)command
                         collectionView:(UICollectionView *)collectionView
                              indexPath:(NSIndexPath *)indexPath;
- (void)matchView:(UIView *)view
         delegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
