/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKMetadataIndexer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKMetadataIndexer ()

@property (nonnull, nonatomic, readonly) NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *store;
@property (nonnull, nonatomic, readonly) id<FBSDKUserDataPersisting> userDataStore;
@property (nonnull, nonatomic, readonly) Class<FBSDKSwizzling> swizzler;

- (void)constructRules:(NSDictionary<NSString *, id> *)rules;

- (void)initStore;

- (BOOL)checkSecureTextEntry:(UIView *)view;

- (UIKeyboardType)getKeyboardType:(UIView *)view;

- (void)getMetadataWithText:(NSString *)text
                placeholder:(NSString *)placeholder
                     labels:(nullable NSArray<NSString *> *)labels
            secureTextEntry:(BOOL)secureTextEntry
                  inputType:(UIKeyboardType)inputType;

- (void)checkAndAppendData:(NSString *)data forKey:(NSString *)key;

- (void)setupWithRules:(NSDictionary<NSString *, id> *_Nullable)rules;

@end

NS_ASSUME_NONNULL_END
