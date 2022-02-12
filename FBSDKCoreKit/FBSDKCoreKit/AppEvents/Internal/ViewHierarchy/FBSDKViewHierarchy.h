/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, FBCodelessClassBitmask) {
  /// Indicates that the class is subclass of UIControl
  FBCodelessClassBitmaskUIControl = 1 << 3,
  /// Indicates that the class is subclass of UIControl
  FBCodelessClassBitmaskUIButton = 1 << 4,
  /// Indicates that the class is ReactNative Button
  FBCodelessClassBitmaskReactNativeButton = 1 << 6,
  /// Indicates that the class is UITableViewCell
  FBCodelessClassBitmaskUITableViewCell = 1 << 7,
  /// Indicates that the class is UICollectionViewCell
  FBCodelessClassBitmaskUICollectionViewCell = 1 << 8,
  /// Indicates that the class is UILabel
  FBCodelessClassBitmaskLabel = 1 << 10,
  /// Indicates that the class is UITextView or UITextField
  FBCodelessClassBitmaskInput = 1 << 11,
  /// Indicates that the class is UIPicker
  FBCodelessClassBitmaskPicker = 1 << 12,
  /// Indicates that the class is UISwitch
  FBCodelessClassBitmaskSwitch = 1 << 13,
  /// Indicates that the class is UIViewController
  FBCodelessClassBitmaskUIViewController = 1 << 17,
};

NS_ASSUME_NONNULL_BEGIN

@class FBSDKCodelessPathComponent;

NS_SWIFT_NAME(ViewHierarchy)
@interface FBSDKViewHierarchy : NSObject

+ (nullable NSObject *)getParent:(nullable NSObject *)obj;
+ (nullable NSArray<NSObject *> *)getChildren:(NSObject *)obj;
+ (nullable NSArray<FBSDKCodelessPathComponent *> *)getPath:(NSObject *)obj;
+ (nullable NSMutableDictionary<NSString *, id> *)getDetailAttributesOf:(NSObject *)obj;

+ (NSString *)getText:(nullable NSObject *)obj;
+ (NSString *)getHint:(nullable NSObject *)obj;
+ (nullable NSIndexPath *)getIndexPath:(NSObject *)obj;
+ (NSUInteger)getClassBitmask:(NSObject *)obj;
+ (nullable UITableView *)getParentTableView:(UIView *)cell;
+ (nullable UICollectionView *)getParentCollectionView:(UIView *)cell;
+ (NSInteger)getTag:(NSObject *)obj;
+ (nullable NSNumber *)getViewReactTag:(UIView *)view;

+ (nullable NSDictionary<NSString *, id> *)recursiveCaptureTreeWithCurrentNode:(NSObject *)currentNode
                                                                    targetNode:(nullable NSObject *)targetNode
                                                                 objAddressSet:(nullable NSMutableSet<NSObject *> *)objAddressSet
                                                                          hash:(BOOL)hash;

+ (BOOL)isUserInputView:(NSObject *)obj;

@end

NS_ASSUME_NONNULL_END

#endif
