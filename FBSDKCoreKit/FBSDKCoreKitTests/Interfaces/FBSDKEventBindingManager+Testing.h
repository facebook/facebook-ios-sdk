/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKEventBindingManager.h"

@protocol FBSDKSwizzling;
@protocol FBSDKEventLogging;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKEventBindingManager (Testing)

@property (nonatomic) BOOL isStarted;
@property (nullable, nonatomic) NSMutableDictionary<NSString *, id> *reactBindings;
@property (nonatomic, readonly) NSSet<Class> *validClasses;
@property (nonatomic) BOOL hasReactNative;
@property (nullable, nonatomic) NSArray<FBSDKEventBinding *> *eventBindings;
@property (nullable, nonatomic, readonly) Class<FBSDKSwizzling> swizzler;
@property (nonnull, nonatomic) id<FBSDKEventLogging> eventLogger;

- (instancetype)initWithJSON:(NSDictionary<NSString *, id> *)dict
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
