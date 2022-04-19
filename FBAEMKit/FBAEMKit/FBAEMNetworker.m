/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBAEMNetworker.h"

#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import <FBAEMKit/FBAEMKit-Swift.h>

#import "FBAEMKitVersions.h"
#import "FBAEMRequestBody.h"

#define kNewline @"\r\n"

static NSString *const kSDK = @"ios";
static NSString *const kUserAgentBase = @"FBiOSAEM";

@implementation FBAEMNetworker

static NSString *const FB_GRAPH_API_ENDPOINT = @"https://graph.facebook.com/v13.0/";
static NSString *const FB_GRAPH_API_CONTENT_TYPE = @"application/json";
NSErrorDomain const FBAEMErrorDomain = @"com.facebook.aemkit";

@synthesize userAgentSuffix = _userAgentSuffix;

- (void)startGraphRequestWithGraphPath:(NSString *)graphPath
                            parameters:(NSDictionary<NSString *, id> *)parameters
                           tokenString:(nullable NSString *)tokenString
                            HTTPMethod:(nullable NSString *)method
                            completion:(FBGraphRequestCompletion)completion
{
  NSURL *url = [NSURL URLWithString:[FB_GRAPH_API_ENDPOINT stringByAppendingString:graphPath]];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];

  request.HTTPMethod = method;
  [request setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
  [request setValue:FB_GRAPH_API_CONTENT_TYPE forHTTPHeaderField:@"Content-Type"];
  request.HTTPShouldHandleCookies = NO;

  // add parameters to body
  FBAEMRequestBody *body = [FBAEMRequestBody new];

  NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionaryWithDictionary:parameters];
  [FBSDKTypeUtility dictionary:params setObject:@"json" forKey:@"format"];
  [FBSDKTypeUtility dictionary:params setObject:kSDK forKey:@"sdk"];
  [FBSDKTypeUtility dictionary:params setObject:@"false" forKey:@"include_headers"];

  [self appendAttachments:params toBody:body addFormData:[method isEqual:@"POST"]];

  if ([request.HTTPMethod isEqualToString:@"POST"]) {
    request.HTTPBody = body.compressedData;
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
  } else {
    request.HTTPBody = body.data;
  }

  FBSDKURLSession *session = [[FBSDKURLSession alloc] initWithDelegate:self delegateQueue:NSOperationQueue.currentQueue];

  [session executeURLRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSDictionary<NSString *, id> *result = [self parseJSONResponse:responseData error:&error statusCode:httpResponse.statusCode];
    completion(result, error);
  }];
}

- (NSDictionary<NSString *, id> *)parseJSONResponse:(NSData *)data
                                              error:(NSError **)error
                                         statusCode:(NSInteger)statusCode
{
  NSString *responseUTF8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  id response = [self parseJSONOrOtherwise:responseUTF8 error:error];
  NSDictionary<NSString *, id> *result;

  if (responseUTF8 == nil) {
    NSString *base64Data = data.length != 0 ? [data base64EncodedStringWithOptions:0] : @"";
    if (base64Data != nil) {
      NSLog(@"fb_response_invalid_utf8");
    }
  }

  if (!response) {
    if ((error != NULL) && (*error == nil)) {
      *error = [[NSError alloc] initWithDomain:FBAEMErrorDomain code:statusCode userInfo:nil];
    }
  } else if ([response isKindOfClass:[NSDictionary<NSString *, id> class]]) {
    result = response;
  }

  return result;
}

- (id)parseJSONOrOtherwise:(NSString *)unsafeString
                     error:(NSError **)error
{
  id parsed = nil;
  NSString *const utf8 = [(NSObject *)unsafeString isKindOfClass:NSString.class] ? unsafeString : nil;
  if (!(*error) && utf8) {
    parsed = [FBSDKBasicUtility objectForJSONString:utf8 error:error];
  }
  return parsed;
}

- (void)appendAttachments:(NSDictionary<NSString *, id> *)attachments
                   toBody:(FBAEMRequestBody *)body
              addFormData:(BOOL)addFormData
{
  [FBSDKTypeUtility dictionary:attachments enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    value = [FBSDKBasicUtility convertRequestValue:value];
    if ([value isKindOfClass:NSString.class]) {
      if (addFormData) {
        [body appendWithKey:key formValue:(NSString *)value];
      }
    } else {
      NSString *msg = [NSString stringWithFormat:@"Unsupported attachment:%@, skipping.", value];
      NSLog(@"%@", msg);
    }
  }];
}

- (NSString *)userAgent
{
  static NSString *agent = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    agent = [NSString stringWithFormat:@"%@.%@", kUserAgentBase, FBAEMKit_VERSION_STRING];
  });
  NSString *agentWithSuffix = agent;
  if (_userAgentSuffix) {
    agentWithSuffix = [NSString stringWithFormat:@"%@/%@", agent, _userAgentSuffix];
  }
  if (@available(iOS 13.0, *)) {
    if (NSProcessInfo.processInfo.isMacCatalystApp) {
      return [NSString stringWithFormat:@"%@/%@", agentWithSuffix ?: agent, @"macOS"];
    }
  }
  return agentWithSuffix;
}

@end

#endif
