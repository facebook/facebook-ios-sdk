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

#import <FBSDKCoreKit/FBSDKCopying.h>

#import "FBSDKDialogConfiguration.h"
#import "FBSDKErrorConfiguration.h"

@interface FBSDKServerConfiguration : NSObject <FBSDKCopying, NSSecureCoding>

- (instancetype)initWithAppID:(NSString *)appID
                      appName:(NSString *)appName
          loginTooltipEnabled:(BOOL)loginTooltipEnabled
             loginTooltipText:(NSString *)loginTooltipText
             defaultShareMode:(NSString *)defaultShareMode
         advertisingIDEnabled:(BOOL)advertisingIDEnabled
       implicitLoggingEnabled:(BOOL)implicitLoggingEnabled
implicitPurchaseLoggingEnabled:(BOOL)implicitPurchaseLoggingEnabled
  systemAuthenticationEnabled:(BOOL)systemAuthenticationEnabled
         dialogConfigurations:(NSDictionary *)dialogConfigurations
                    timestamp:(NSDate *)timestamp
           errorConfiguration:(FBSDKErrorConfiguration *)errorConfiguration
NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign, readonly, getter=isAdvertisingIDEnabled) BOOL advertisingIDEnabled;
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, copy, readonly) NSString *appName;
@property (nonatomic, assign, readonly, getter=isImplicitLoggingSupported) BOOL implicitLoggingEnabled;
@property (nonatomic, assign, readonly, getter=isImplicitPurchaseLoggingSupported) BOOL implicitPurchaseLoggingEnabled;
@property (nonatomic, assign, readonly, getter=isLoginTooltipEnabled) BOOL loginTooltipEnabled;
@property (nonatomic, copy, readonly) NSString *loginTooltipText;
@property (nonatomic, copy, readonly) NSString *defaultShareMode;
@property (nonatomic, assign, readonly, getter=isSystemAuthenticationEnabled) BOOL systemAuthenticationEnabled;
@property (nonatomic, copy, readonly) NSDate *timestamp;
@property (nonatomic, strong, readonly) FBSDKErrorConfiguration *errorConfiguration;

- (FBSDKDialogConfiguration *)dialogConfigurationForDialogName:(NSString *)dialogName;

@end
