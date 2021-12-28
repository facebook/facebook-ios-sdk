/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@protocol FBSDKFileManaging;
@protocol FBSDKFileDataExtracting;

NS_ASSUME_NONNULL_BEGIN

@interface FBSDKCrashHandler (Testing)

@property (nonatomic) id<FBSDKFileManaging> fileManager;
@property (nonatomic) id<FBSDKInfoDictionaryProviding> bundle;
@property (nonatomic, strong) Class<FBSDKFileDataExtracting> dataExtractor;

- (instancetype)init;

// UNCRUSTIFY_FORMAT_OFF
- (instancetype)initWithFileManager:(id<FBSDKFileManaging>)fileManager
                             bundle:(id<FBSDKInfoDictionaryProviding>)bundle
                  fileDataExtractor:(nonnull Class<FBSDKFileDataExtracting>)dataExtractor
NS_SWIFT_NAME(init(fileManager:bundle:dataExtractor:));
// UNCRUSTIFY_FORMAT_ON

- (NSArray<NSString *> *)_getCrashLogFileNames:(NSArray<NSString *> *)files;
- (NSString *)_getPathToCrashFile:(NSString *)timestamp;
- (BOOL)_callstack:(NSArray<NSString *> *)callstack
    containsPrefix:(NSArray<NSString *> *)prefixList;
- (NSArray<NSDictionary<NSString *, id> *> *)_filterCrashLogs:(NSArray<NSString *> *)prefixList
                                           processedCrashLogs:(NSArray<NSDictionary<NSString *, id> *> *)processedCrashLogs;
- (void)_saveCrashLog:(NSDictionary<NSString *, id> *)crashLog;
- (nullable NSData *)_loadCrashLog:(NSString *)fileName;

@end
NS_ASSUME_NONNULL_END
