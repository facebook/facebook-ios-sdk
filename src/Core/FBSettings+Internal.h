/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FBSDKMacros.h"
#import "FBSettings.h"

FBSDK_EXTERN NSString *const FBPLISTUrlSchemeSuffixKey;

@interface FBSettings (Internal)

+ (void)autoPublishInstall:(NSString *)appID;

/*!
 @method

 @abstract Get the default url scheme used for the session. This is generated based
 on the url scheme suffix and the app id.
 @param appID If nil, defaults to [FBSettings defaultAppID]
 @param urlSchemeSuffix If nil, defaults to [FBSettings defaultUrlSchemeSuffix]
 */
+ (NSString *)defaultURLSchemeWithAppID:(NSString *)appID urlSchemeSuffix:(NSString *)urlSchemeSuffix;

/*!
 @method

 @abstract Set the default JPEG Compression Quality used for UIImage uploads. If not specified
 we use a default value of 0.9

 @param compressionQuality The default url scheme suffix to be used by the SDK.
 */
+ (void)setdefaultJPEGCompressionQuality:(CGFloat)compressionQuality;

/*!
 @method

 @abstract Get the default JPEG Compression Quality used for UIImage uploads.  This value is the
 compressionQuality value passed to UIImageJPEGRepresentation
 */
+ (CGFloat)defaultJPEGCompressionQuality;

/*!
 @method

 @abstract Returns the current setting indicating if this app should be restricted.
 */
+ (FBRestrictedTreatment)restrictedTreatment;

/*!
 @method Sets the current setting indicating if this app should be restricted. This
 will close FBSession.activeSession if the session is open.

 @abstract Sets the current setting indicating if this app should be restricted. This
 will close FBSession.activeSession if the session is open.

 @param treatment The desired treatment
 */
+ (void)setRestrictedTreatment:(FBRestrictedTreatment)treatment;

+ (NSString *)platformVersion;

@end
