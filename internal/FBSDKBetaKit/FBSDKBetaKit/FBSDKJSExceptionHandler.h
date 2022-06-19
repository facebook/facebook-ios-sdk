// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
  @class FBSDKJSExceptionHandler

  @brief
  Save any captured JS exception data as the same format as ErrorReport in the local device.
  Uploads the reports of the JS errors to the endpoint.
*/
@interface FBSDKJSExceptionHandler : NSObject

/**
  @method

  @brief Gets the string of exception and puts it as "error_message".
 */
+ (void)saveError:(nullable NSString *)message;

/**
  @method

  @brief This functions enables FBSDKJSExceptionHandler and
         creates "/instrument" as FBSDKErrorReport.
 */
+ (void)enable;

@end

NS_ASSUME_NONNULL_END
