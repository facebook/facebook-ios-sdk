// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_SWIFT_NAME(ViewHierarchy)
@interface HRTViewHierarchy : NSObject

+ (NSObject *)getParent:(NSObject *)obj;
+ (NSArray<NSObject *> *)getChildren:(NSObject *)obj;
+ (NSArray<NSObject *> *)getPath:(NSObject *)obj;
+ (NSMutableDictionary<NSString *, id> *)getDetailAttributesOf:(NSObject *)obj;

+ (NSString *)getText:(NSObject *)obj;
+ (NSString *)getHint:(NSObject *)obj;
+ (NSIndexPath *)getIndexPath:(NSObject *)obj;
+ (NSUInteger)getClassBitmask:(NSObject *)obj;
+ (UITableView *)getParentTableView:(UIView *)cell;
+ (UICollectionView *)getParentCollectionView:(UIView *)cell;
+ (NSInteger)getTag:(NSObject *)obj;
+ (NSNumber *)getViewReactTag:(UIView *)view;

+ (BOOL)isUserInputView:(NSObject *)obj;

@end
