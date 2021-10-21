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

#import "FBSDKError+Internal.h"
#import "FBSDKErrorReporting.h"

@protocol FBSDKGraphRequestFactory;
@protocol FBSDKFileManaging;
@protocol FBSDKSettings;
@protocol FBSDKFileDataExtracting;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(ErrorReporter)
@interface FBSDKErrorReporter : NSObject <FBSDKErrorReporting>

@property (class, nonatomic, readonly) FBSDKErrorReporter *shared;

@property (nonatomic, strong) id<FBSDKGraphRequestFactory> graphRequestFactory;
@property (nonatomic, strong) id<FBSDKFileManaging> fileManager;
@property (nonatomic, strong) id<FBSDKSettings> settings;
@property (nonatomic, strong) Class<FBSDKFileDataExtracting> dataExtractor;
@property (nonatomic, readonly, strong) NSString *directoryPath;
@property (nonatomic) BOOL isEnabled;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)saveError:(NSInteger)errorCode
      errorDomain:(NSErrorDomain)errorDomain
          message:(nullable NSString *)message;

- (instancetype)initWithGraphRequestFactory:(id<FBSDKGraphRequestFactory>)graphRequestFactory
                                 fileManager:(id<FBSDKFileManaging>)fileManager
                                    settings:(id<FBSDKSettings>)settings
                           fileDataExtractor:(Class<FBSDKFileDataExtracting>)dataExtractor;
- (void)enable;

@end

NS_ASSUME_NONNULL_END
