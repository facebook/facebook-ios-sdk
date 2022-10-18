// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "JSWrapper.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

// TODO T103300381: Expose this correctly or dynamically call the private class
// #import "FBSDKAppEventsUtility.h"

#import "FBSDKJSExceptionHandler.h"

/**
  @brief The path of the JS file in device.
 */
static NSString *FBSDK_JS_PATH = @"fbsdk_js";

/**
  @brief The AppEvents.js script content.
 */
static NSString *script = nil;

/**
  @see GraphAPI AppEvents Logging.
 */
@implementation JSWrapper

#pragma mark - Singleton for using the same JSContext throughout the code.

+ (JSWrapper *)singleton
{
  static JSWrapper *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[JSWrapper alloc] init];
  });
  return shared;
}

- (JSWrapper *)init
{
  /**
   @brief JSContext to be used across all logEvents calls.
   */
  self.context = [JSContext new];
  /**
   @brief Registers two blocks - callback & networkRequest.
   */
  [JSWrapper setupContext:self.context];
  return self;
}

#pragma mark - Calling logEvents JavaScript Function

/**
  @method

  @brief
  Function that initializes the script and downloads the file properly.
 */
+ (void)initialize
{
  /**
   @brief Upload all the JS Error Reports to the Facebook Servers
          firstly when the SDK loads up.
  */
  [FBSDKJSExceptionHandler enable];

  NSString *urlString = @"http://127.0.0.1:8080/download/AppEvents.js";
  NSString *directoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:FBSDK_JS_PATH];

  /**
   @brief Check that the file does not already exist at the path/directory.
   */
  if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:NULL error:NULL];
  }

  NSString *filePath = [directoryPath stringByAppendingPathComponent:@"AppEvents.js"];

  /**
   @brief Before loading the file, check that it exists at the specified path location.
   */
  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    /**
     @brief If the file path is new, then download the file from the remote server.
     */
    [JSWrapper download:urlString filePath:filePath];
  } else {
    script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
  }
}

/**
 @method

 @brief
 Calls the setUp function & the executeJS function.

 @param events - The `NSArray` used as the structure of events.
 */
+ (void)logEvents:(NSArray<id> *)events
{
  /**
    @brief Verify that the file is downloaded. If it remains nil, then return.
   */
  if (!script) {
    return;
  }

  NSString *eventsString = [FBSDKBasicUtility JSONStringForObject:events error:nil invalidObjectHandler:nil];
  if (!eventsString) {
    return;
  }

  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary new];
  [FBSDKTypeUtility dictionary:params setObject:[[FBSDKSettings sharedSettings] appID] forKey:@"appId"];

  // TODO T103300381: Re-enable once private import is fixed
  // NSMutableDictionary<NSString *, id> *requestParams = [FBSDKAppEventsUtility activityParametersDictionaryForEvent:@"CUSTOM_APP_EVENTS"
  // shouldAccessAdvertisingID:YES];
  // [FBSDKTypeUtility dictionary:requestParams setObject:eventsString forKey:@"custom_events"];

  // [FBSDKTypeUtility dictionary:params setObject:requestParams forKey:@"requestParams"];
  NSString *paramsString = @""; // [FBSDKBasicUtility JSONStringForObject:params error:nil invalidObjectHandler:nil];

  /**
    @brief Error checking of params and exception handling.
   */
  bool isValidated = [JSWrapper isValid:params];
  if (!isValidated) {
    NSString *notValidated = @"The parameters for logEvents have not passed validation.";
    [JSWrapper callback:notValidated];
    return;
  }

  /**
   @brief Executes the AppEvents JS file.
   */
  [JSWrapper executeJS:script params:paramsString context:[JSWrapper singleton].context];
}

/**
  @method

  @brief
  Download & load function to fetch AppEvents.js from the remote server.

  @param urlString - The `NSString` used as URL that holds AppEvents.js.
  @param filePath - The `NSString` path where the file will be downloaded.
 */
+ (void)download:(NSString *)urlString filePath:(NSString *)filePath
{
  if (!filePath || [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    return;
  }

  /**
    @brief The `dispatch_queue_t` that serves as a semaphore for multi-threading.
   */
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *urlData = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
    if (urlData) {
      [urlData writeToFile:filePath atomically:YES];
      script = [[NSString alloc] initWithData:urlData encoding:NSUTF8StringEncoding];
    }
  });
}

/**
  @method

  @brief
  Logs the result of the request from the logEvents() function in AppEvents.js is the input to the callback or block.

  @param data - The `NSString` of the result returned from the network request.
 */
+ (void)callback:(NSString *)data
{
  if (![data isKindOfClass:[NSString class]]) {
    NSLog(@"[callback]data is not a string");
    return;
  }
  NSLog(@"[callback]data: %@", data);
};

/**
  @method

  @brief
  This function registers the callback block.
  This function will also register the networkRequest block.

  @param context - `JSContext` used for the ObjC to JS Bridge Class.
 */
+ (void)setupContext:(JSContext *)context
{
  /**
   @brief Making an exception in case the JavaScriptCore connection fails somewhere.
   */
  context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
    NSString *message = [NSString stringWithFormat:@"Exception occurred during the bridge between JS and ObjC: %@", exception];
    NSLog(message);
    [FBSDKJSExceptionHandler saveError:message];
  };

  /**
   @brief
   This function always does an HTTPMethodPOST and it handles any nil cases.

   @param url - The `NSString` URL to be sent to the Facebook servers.

   @param body - The `NSString` of the JSON stringified body parameters to send to the request.
   */
  void (^networkRequest)(NSString *, NSString *) =
  ^(NSString *url, NSString *body) {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:60];

    NSDictionary *bodyDict = [FBSDKTypeUtility JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];

    NSData *data = [FBSDKTypeUtility dataWithJSONObject:bodyDict options:0 error:nil];

    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"JavaScript" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];

    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      /**
        @brief The result of the data received from sending the URL request.
       */
      NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
      [JSWrapper callback:result];
    }] resume];
  };

  /**
   @brief
   This function logs the value of an exception that arises from the JS file.

   @param data - The `NSString` exception to be logged from the JS file.
   */
  void (^log)(NSString *) =
  ^(NSString *data) {
    if (![data isKindOfClass:[NSString class]]) {
      NSLog(@"[JSLog]data is not a string");
      return;
    }
    NSLog(@"[JSLog]data: %@", data);
  };

  context[@"log"] = log;
  context[@"networkRequest"] = networkRequest;
}

/**
  @method

  @brief
  Loads the AppEvents JS file into a string.

  @param code - The `NSString` of the loaded JS code file.

  @param params - The `NSString` passed as a parameter to the call
                 of the logEvents function.

  @param context - The `JSContext` used for the ObjC to JS Bridge Class.
*/
+ (void)executeJS:(NSString *)code params:(NSString *)params context:(JSContext *)context
{
  [context evaluateScript:code];
  JSValue *logEvents = context[@"logEvents"];

  [logEvents callWithArguments:@[params]];

  return;
}

#pragma mark - Validation for the parameters of the request

/**
  @method

  @brief
  Error checking is done for all the keys and values of the params dictionary.
  The function that checks for any errors in the parameters to be sent to the
  logEvents() function in the AppEvents JS file before they are even sent.

  @param params - The `NSDictionary` passed as a parameter to the call
                of the logEvents function.

  @return bool - The `bool` value if the params is a valid dictionary for App Events.
 */
+ (bool)isValid:(NSDictionary<NSString *, id> *)params
{
  if ([params isEqual:[NSNull null]] || !params.count) {
    return false;
  }

  if (![params[@"appId"] isKindOfClass:[NSString class]] || [params[@"appId"] length] == 0) {
    return false;
  }
  if (![params[@"graphPath"] isKindOfClass:[NSString class]] || [params[@"graphPath"] length] == 0) {
    return false;
  }
  if ([params[@"requestParams"] isEqual:[NSNull null]] || ![params[@"requestParams"] isKindOfClass:[NSDictionary class]]) {
    return false;
  }
  NSDictionary<NSString *, id> *requestParams = params[@"requestParams"];
  if (!requestParams.count) {
    return false;
  }
  if (![requestParams[@"event"] isKindOfClass:[NSString class]] || [requestParams[@"event"] length] == 0) {
    return false;
  }
  if (![requestParams[@"application_tracking_enabled"] isKindOfClass:[NSNumber class]]) {
    return false;
  }
  if (![requestParams[@"application_tracking_enabled"] isKindOfClass:[NSNumber class]]) {
    return false;
  }
  if (![requestParams[@"anon_id"] isKindOfClass:[NSString class]] || [requestParams[@"anon_id"] length] == 0) {
    return false;
  }
  if ([requestParams[@"custom_events"] isEqual:[NSNull null]] || ![requestParams[@"custom_events"] isKindOfClass:[NSArray class]]) {
    return false;
  }
  NSArray<id> *custom_events = requestParams[@"custom_events"];
  if (!custom_events.count) {
    return false;
  }
  if ([requestParams[@"extinfo"] isEqual:[NSNull null]] || ![requestParams[@"extinfo"] isKindOfClass:[NSArray class]]) {
    return false;
  }
  NSArray<id> *extinfo = requestParams[@"extinfo"];
  if (!extinfo.count) {
    return false;
  }

  // Assuming all required cases were considered, return true.
  return true;
}

@end
