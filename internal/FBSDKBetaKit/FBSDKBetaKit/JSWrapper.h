// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

/**
  @class JSWrapper

  @brief
  Defines the JS Bridge class that will connect the App Events between ObjC and JS in the
  FBSDKBetaKit folder connected to the AppEvents JS file.
*/
@interface JSWrapper : NSObject

/**
  @brief The same JSContext that will be used throughout the JS to ObjC bridge class.
 */
@property (nonatomic) JSContext *context;

/**
  @method

  @brief
  The logEvents() function encapsulates the implementation by calling the two
  aforementioned functions, namely setupContext:context and executeJs:code:params:context.
 */
+ (void)logEvents:(NSArray<id> *)events;

/**
  @method

  @description
  The setUp() function passes two blocks to the JS:

   - The callback block, which is sent to the JS, and then the result of the
    request are passed to it and they are analyzed in the JSWrapper class.
    Once the request completes, at that point the callback block is called
    upon indirectly in the JS file via the networkRequest block in the ObjC
    to verify if a success or error is logged.
   - The networkRequest callback replaces the fetch(url) that was previously
    done in the GraphRequestConnection.sendNetworkRequest() function.
    This block makes a single-threaded connection with the server.
 */
+ (void)setupContext:(JSContext *)context;

/**
  @method

  @brief
  The executeJS() function calls the logEvents() fuction in the JS file.
 */
+ (void)executeJS:(NSString *)code params:(NSString *)params context:(JSContext *)context;

@end

NS_ASSUME_NONNULL_END
