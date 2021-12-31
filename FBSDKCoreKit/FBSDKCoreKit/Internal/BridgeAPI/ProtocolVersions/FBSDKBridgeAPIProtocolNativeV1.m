/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKBridgeAPIProtocolNativeV1.h"

#import <UIKit/UIKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKApplicationLifecycleNotifications.h"
#import "FBSDKBridgeAPIRequest.h"
#import "FBSDKConstants.h"
#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKInternalUtility+Internal.h"
#import "FBSDKPasteboard.h"
#import "FBSDKSettings.h"
#import "UIPasteboard+Pasteboard.h"

#define FBSDKBridgeAPIProtocolNativeV1BridgeMaxBase64DataLengthThreshold (1024 * 16)

const FBSDKBridgeAPIProtocolNativeV1OutputKeysStruct FBSDKBridgeAPIProtocolNativeV1OutputKeys =
{
  .bridgeArgs = @"bridge_args",
  .methodArgs = @"method_args",
};

const FBSDKBridgeAPIProtocolNativeV1BridgeParameterOutputKeysStruct FBSDKBridgeAPIProtocolNativeV1BridgeParameterOutputKeys =
{
  .actionID = @"action_id",
  .appIcon = @"app_icon",
  .appName = @"app_name",
  .sdkVersion = @"sdk_version",
};

const FBSDKBridgeAPIProtocolNativeV1InputKeysStruct FBSDKBridgeAPIProtocolNativeV1InputKeys =
{
  .bridgeArgs = @"bridge_args",
  .methodResults = @"method_results",
};

const FBSDKBridgeAPIProtocolNativeV1BridgeParameterInputKeysStruct FBSDKBridgeAPIProtocolNativeV1BridgeParameterInputKeys =
{
  .actionID = @"action_id",
  .error = @"error",
};

static const struct {
  __unsafe_unretained NSString *isBase64;
  __unsafe_unretained NSString *isPasteboard;
  __unsafe_unretained NSString *tag;
  __unsafe_unretained NSString *value;
} FBSDKBridgeAPIProtocolNativeV1DataKeys =
{
  .isBase64 = @"isBase64",
  .isPasteboard = @"isPasteboard",
  .tag = @"tag",
  .value = @"fbAppBridgeType_jsonReadyValue",
};

static NSString *const FBSDKBridgeAPIProtocolNativeV1DataPasteboardKey = @"com.facebook.Facebook.FBAppBridgeType";

static const struct {
  __unsafe_unretained NSString *data;
  __unsafe_unretained NSString *image;
} FBSDKBridgeAPIProtocolNativeV1DataTypeTags =
{
  .data = @"data",
  // we serialize jpegs but use png for backward compatibility - it is any image format that UIImage can handle
  .image = @"png",
};

static const struct {
  __unsafe_unretained NSString *code;
  __unsafe_unretained NSString *domain;
  __unsafe_unretained NSString *userInfo;
} FBSDKBridgeAPIProtocolNativeV1ErrorKeys =
{
  .code = @"code",
  .domain = @"domain",
  .userInfo = @"user_info",
};

@implementation FBSDKBridgeAPIProtocolNativeV1

#pragma mark - Object Lifecycle

- (instancetype)initWithAppScheme:(nullable NSString *)appScheme
{
  id<FBSDKErrorCreating> errorFactory = [[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared];
  return [self initWithAppScheme:appScheme
                      pasteboard:[UIPasteboard generalPasteboard]
             dataLengthThreshold:FBSDKBridgeAPIProtocolNativeV1BridgeMaxBase64DataLengthThreshold
                  includeAppIcon:YES
                    errorFactory:errorFactory];
}

- (instancetype)initWithAppScheme:(nullable NSString *)appScheme
                       pasteboard:(nullable id<FBSDKPasteboard>)pasteboard
              dataLengthThreshold:(NSUInteger)dataLengthThreshold
                   includeAppIcon:(BOOL)includeAppIcon
                     errorFactory:(id<FBSDKErrorCreating>)errorFactory
{
  if ((self = [super init])) {
    _appScheme = [appScheme copy];
    _pasteboard = pasteboard;
    _dataLengthThreshold = dataLengthThreshold;
    _includeAppIcon = includeAppIcon;
    _errorFactory = errorFactory;
  }
  return self;
}

#pragma mark - FBSDKBridgeAPIProtocol

- (nullable NSURL *)requestURLWithActionID:(NSString *)actionID
                                    scheme:(NSString *)scheme
                                methodName:(NSString *)methodName
                                parameters:(NSDictionary<NSString *, id> *)parameters
                                     error:(NSError *__autoreleasing *)errorRef
{
  NSString *const host = @"dialog";
  NSString *const path = [@"/" stringByAppendingString:methodName];

  NSMutableDictionary<NSString *, id> *const queryParameters = [NSMutableDictionary new];

  if (parameters.count) {
    NSString *const parametersString = [self _JSONStringForObject:parameters enablePasteboard:YES error:errorRef];
    if (!parametersString) {
      return nil;
    }
    NSString *const escapedParametersString = [parametersString stringByReplacingOccurrencesOfString:@"&"
                                                                                          withString:@"%26"
                                                                                             options:NSCaseInsensitiveSearch
                                                                                               range:NSMakeRange(
                                                 0,
                                                 parametersString.length
                                               )];
    [FBSDKTypeUtility dictionary:queryParameters
                       setObject:escapedParametersString
                          forKey:FBSDKBridgeAPIProtocolNativeV1OutputKeys.methodArgs];
  }

  NSDictionary<NSString *, id> *const bridgeParameters = [self _bridgeParametersWithActionID:actionID error:errorRef];
  if (!bridgeParameters) {
    return nil;
  }
  NSString *const bridgeParametersString = [self _JSONStringForObject:bridgeParameters enablePasteboard:NO error:errorRef];
  if (!bridgeParametersString) {
    return nil;
  }
  [FBSDKTypeUtility dictionary:queryParameters
                     setObject:bridgeParametersString
                        forKey:FBSDKBridgeAPIProtocolNativeV1OutputKeys.bridgeArgs];

  return [FBSDKInternalUtility.sharedUtility URLWithScheme:self.appScheme
                                                      host:host
                                                      path:path
                                           queryParameters:queryParameters
                                                     error:errorRef];
}

- (nullable NSDictionary<NSString *, id> *)responseParametersForActionID:(NSString *)actionID
                                                         queryParameters:(NSDictionary<NSString *, id> *)queryParameters
                                                               cancelled:(BOOL *)cancelledRef
                                                                   error:(NSError *__autoreleasing *)errorRef
{
  if (cancelledRef != NULL) {
    *cancelledRef = NO;
  }
  if (errorRef != NULL) {
    *errorRef = nil;
  }
  NSError *error;
  NSString *bridgeParametersJSON = queryParameters[FBSDKBridgeAPIProtocolNativeV1InputKeys.bridgeArgs];
  NSDictionary<id, id> *bridgeParameters = [FBSDKBasicUtility objectForJSONString:bridgeParametersJSON error:&error];
  bridgeParameters = [FBSDKTypeUtility dictionaryValue:bridgeParameters];
  if (!bridgeParameters) {
    if (error && (errorRef != NULL)) {
      *errorRef = [self.errorFactory invalidArgumentErrorWithName:FBSDKBridgeAPIProtocolNativeV1InputKeys.bridgeArgs
                                                            value:bridgeParametersJSON
                                                          message:@"Invalid bridge_args."
                                                  underlyingError:error];
    }
    return nil;
  }
  NSString *responseActionID = bridgeParameters[FBSDKBridgeAPIProtocolNativeV1BridgeParameterInputKeys.actionID];
  responseActionID = [FBSDKTypeUtility coercedToStringValue:responseActionID];
  if (![responseActionID isEqualToString:actionID]) {
    return nil;
  }
  NSDictionary<NSString *, id> *errorDictionary = bridgeParameters[FBSDKBridgeAPIProtocolNativeV1BridgeParameterInputKeys.error];
  errorDictionary = [FBSDKTypeUtility dictionaryValue:errorDictionary];
  if (errorDictionary) {
    error = [self _errorWithDictionary:errorDictionary];
    if (errorRef != NULL) {
      *errorRef = error;
    }
    return nil;
  }
  NSString *resultParametersJSON = queryParameters[FBSDKBridgeAPIProtocolNativeV1InputKeys.methodResults];
  NSDictionary<id, id> *resultParameters = [FBSDKBasicUtility objectForJSONString:resultParametersJSON error:&error];
  if (!resultParameters) {
    if (errorRef != NULL) {
      *errorRef = [self.errorFactory invalidArgumentErrorWithName:FBSDKBridgeAPIProtocolNativeV1InputKeys.methodResults
                                                            value:resultParametersJSON
                                                          message:@"Invalid method_results."
                                                  underlyingError:error];
    }
    return nil;
  }
  if (cancelledRef != NULL) {
    NSString *completionGesture = [FBSDKTypeUtility coercedToStringValue:resultParameters[@"completionGesture"]];
    *cancelledRef = [completionGesture isEqualToString:@"cancel"];
  }
  return resultParameters;
}

- (nullable UIImage *)_appIcon
{
  if (!_includeAppIcon) {
    return nil;
  }
  NSArray *files = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIcons"]
  [@"CFBundlePrimaryIcon"]
  [@"CFBundleIconFiles"];
  if (!files.count) {
    return nil;
  }
  return [UIImage imageNamed:[FBSDKTypeUtility array:files objectAtIndex:0]];
}

- (NSDictionary<NSString *, id> *)_bridgeParametersWithActionID:(NSString *)actionID error:(NSError *__autoreleasing *)errorRef
{
  NSMutableDictionary<NSString *, id> *bridgeParameters = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:bridgeParameters setObject:actionID
                        forKey:FBSDKBridgeAPIProtocolNativeV1BridgeParameterOutputKeys.actionID];
  [FBSDKTypeUtility dictionary:bridgeParameters setObject:[self _appIcon]
                        forKey:FBSDKBridgeAPIProtocolNativeV1BridgeParameterOutputKeys.appIcon];
  [FBSDKTypeUtility dictionary:bridgeParameters setObject:FBSDKSettings.sharedSettings.displayName
                        forKey:FBSDKBridgeAPIProtocolNativeV1BridgeParameterOutputKeys.appName];
  [FBSDKTypeUtility dictionary:bridgeParameters setObject:FBSDKSettings.sharedSettings.sdkVersion
                        forKey:FBSDKBridgeAPIProtocolNativeV1BridgeParameterOutputKeys.sdkVersion];
  return bridgeParameters;
}

- (nullable NSError *)_errorWithDictionary:(NSDictionary<NSString *, id> *)dictionary
{
  if (!dictionary) {
    return nil;
  }
  NSString *domain = [FBSDKTypeUtility coercedToStringValue:dictionary[FBSDKBridgeAPIProtocolNativeV1ErrorKeys.domain]]
  ?: FBSDKErrorDomain;
  NSInteger code = [FBSDKTypeUtility integerValue:dictionary[FBSDKBridgeAPIProtocolNativeV1ErrorKeys.code]]
  ?: FBSDKErrorUnknown;
  NSDictionary<NSString *, id> *userInfo = [FBSDKTypeUtility dictionaryValue:dictionary[FBSDKBridgeAPIProtocolNativeV1ErrorKeys.userInfo]];
  return [self.errorFactory errorWithDomain:domain
                                       code:code
                                   userInfo:userInfo
                                    message:nil
                            underlyingError:nil];
}

- (NSString *)_JSONStringForObject:(id)object enablePasteboard:(BOOL)enablePasteboard error:(NSError **)errorRef
{
  __block BOOL didAddToPasteboard = NO;
  return [FBSDKBasicUtility JSONStringForObject:object error:errorRef invalidObjectHandler:^id (id invalidObject, BOOL *stop) {
    NSString *dataTag = FBSDKBridgeAPIProtocolNativeV1DataTypeTags.data;
    if ([invalidObject isKindOfClass:UIImage.class]) {
      UIImage *image = (UIImage *)invalidObject;
      // due to backward compatibility, we must send UIImage as NSData even though UIPasteboard can handle UIImage
      invalidObject = UIImageJPEGRepresentation(image, FBSDKSettings.sharedSettings.JPEGCompressionQuality);
      dataTag = FBSDKBridgeAPIProtocolNativeV1DataTypeTags.image;
    }
    if ([invalidObject isKindOfClass:NSData.class]) {
      NSData *data = (NSData *)invalidObject;
      NSMutableDictionary<NSString *, id> *dictionary = [NSMutableDictionary new];
      if (didAddToPasteboard || !enablePasteboard || !self->_pasteboard || (data.length < self->_dataLengthThreshold)) {
        dictionary[FBSDKBridgeAPIProtocolNativeV1DataKeys.isBase64] = @YES;
        [FBSDKTypeUtility dictionary:dictionary setObject:dataTag forKey:FBSDKBridgeAPIProtocolNativeV1DataKeys.tag];
        [FBSDKTypeUtility dictionary:dictionary
                           setObject:[FBSDKBase64 encodeData:data]
                              forKey:FBSDKBridgeAPIProtocolNativeV1DataKeys.value];
      } else {
        dictionary[FBSDKBridgeAPIProtocolNativeV1DataKeys.isPasteboard] = @YES;
        [FBSDKTypeUtility dictionary:dictionary setObject:dataTag forKey:FBSDKBridgeAPIProtocolNativeV1DataKeys.tag];
        [FBSDKTypeUtility dictionary:dictionary setObject:self->_pasteboard.name forKey:FBSDKBridgeAPIProtocolNativeV1DataKeys.value];
        [self->_pasteboard setData:data forPasteboardType:FBSDKBridgeAPIProtocolNativeV1DataPasteboardKey];
        // this version of the protocol only supports a single item on the pasteboard, so if when we add an item, make
        // sure we don't add another item
        didAddToPasteboard = YES;
        // if we are adding this to the general pasteboard, then we want to remove it when we are done with the share.
        // the Facebook app will not clear the value with this version of the protocol, so we should do it when the app
        // becomes active again
        if (self->_pasteboard._isGeneralPasteboard) {
          [self.class clearData:data fromPasteboardOnApplicationDidBecomeActive:self->_pasteboard];
        }
      }
      return dictionary;
    } else if ([invalidObject isKindOfClass:NSURL.class]) {
      return ((NSURL *)invalidObject).absoluteString;
    }
    return invalidObject;
  }];
}

+ (void)clearData:(NSData *)data fromPasteboardOnApplicationDidBecomeActive:(id<FBSDKPasteboard>)pasteboard
{
  void (^notificationBlock)(NSNotification *) = ^(NSNotification *note) {
    // After testing, it seems that reading the pasteboard will not result in a system dialog since
    // the clipboard write originates from the app that loads the SDK
    NSData *pasteboardData = [pasteboard dataForPasteboardType:FBSDKBridgeAPIProtocolNativeV1DataPasteboardKey];
    // We need to compare the data to make sure we don't clear different apps data in a multi-tasking environment
    if ([data isEqualToData:pasteboardData]) {
      [pasteboard setData:[NSData data] forPasteboardType:FBSDKBridgeAPIProtocolNativeV1DataPasteboardKey];
    }
  };
  [NSNotificationCenter.defaultCenter addObserverForName:FBSDKApplicationDidBecomeActiveNotification
                                                  object:nil
                                                   queue:nil
                                              usingBlock:notificationBlock];
}

@end

#endif
