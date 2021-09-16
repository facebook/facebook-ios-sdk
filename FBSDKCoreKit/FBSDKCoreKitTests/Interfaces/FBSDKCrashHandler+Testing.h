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

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

@protocol FBSDKFileManaging;
@protocol FBSDKFileDataExtracting;

NS_ASSUME_NONNULL_BEGIN


@interface FBSDKCrashHandler (Testing)

@property (nonatomic) id<FBSDKFileManaging> fileManager;
@property (nonatomic) id<FBSDKInfoDictionaryProviding> bundle;
@property (nonatomic, strong) Class<FBSDKFileDataExtracting> dataExtractor;

- (instancetype)init;

- (instancetype)initWithFileManager: (id<FBSDKFileManaging>)fileManager
                           bundle: (id<FBSDKInfoDictionaryProviding>)bundle
                  fileDataExtractor:(nonnull Class<FBSDKFileDataExtracting>)dataExtractor
NS_SWIFT_NAME(init(fileManager:bundle:dataExtractor:));

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
