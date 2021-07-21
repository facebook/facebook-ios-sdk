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

#import "TargetConditionals.h"

#if !TARGET_OS_TV

 #import "FBAEMNetworker.h"

 #import "FBAEMKitVersions.h"
 #import "FBAEMRequestBody.h"
 #import "FBCoreKitBasicsImportForAEMKit.h"

 #define kNewline @"\r\n"

static NSString *const kSDK = @"ios";
static NSString *const kUserAgentBase = @"FBiOSAEM";

@implementation FBAEMNetworker

static NSString *const FB_GRAPH_API_ENDPOINT = @"https://graph.facebook.com/v11.0/";
static NSString *const FB_GRAPH_API_CONTENT_TYPE = @"application/json";
NSErrorDomain const FBAEMErrorDomain = @"com.facebook.aemkit";

- (void)startGraphRequestWithGraphPath:(NSString *)graphPath
                            parameters:(NSDictionary *)parameters
                           tokenString:(nullable NSString *)tokenString
                            HTTPMethod:(nullable NSString *)method
                            completion:(FBGraphRequestCompletion)completion
{
  NSURL *url = [NSURL URLWithString:[FB_GRAPH_API_ENDPOINT stringByAppendingString:graphPath]];

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];

  [request setHTTPMethod:method];
  [request setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
  [request setValue:FB_GRAPH_API_CONTENT_TYPE forHTTPHeaderField:@"Content-Type"];
  [request setHTTPShouldHandleCookies:NO];

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

  FBSDKURLSession *session = [[FBSDKURLSession alloc] initWithDelegate:self delegateQueue:[NSOperationQueue currentQueue]];

  [session executeURLRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSDictionary *result = [self parseJSONResponse:responseData error:&error statusCode:httpResponse.statusCode];
    completion(result, error);
  }];
}

- (NSDictionary *)parseJSONResponse:(NSData *)data
                              error:(NSError **)error
                         statusCode:(NSInteger)statusCode
{
  NSString *responseUTF8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  id response = [self parseJSONOrOtherwise:responseUTF8 error:error];
  NSDictionary *result;

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
  } else if ([response isKindOfClass:[NSDictionary class]]) {
    result = response;
  }

  return result;
}

- (id)parseJSONOrOtherwise:(NSString *)unsafeString
                     error:(NSError **)error
{
  id parsed = nil;
  NSString *const utf8 = FBSDK_CAST_TO_CLASS_OR_NIL(unsafeString, NSString);
  if (!(*error) && utf8) {
    parsed = [FBSDKBasicUtility objectForJSONString:utf8 error:error];
  }
  return parsed;
}

- (void)appendAttachments:(NSDictionary *)attachments
                   toBody:(FBAEMRequestBody *)body
              addFormData:(BOOL)addFormData
{
  [FBSDKTypeUtility dictionary:attachments enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    value = [FBSDKBasicUtility convertRequestValue:value];
    if ([value isKindOfClass:[NSString class]]) {
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
  if (@available(iOS 13.0, *)) {
    SEL selector = NSSelectorFromString(@"isMacCatalystApp");
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if (selector && [NSProcessInfo.processInfo respondsToSelector:selector] && [NSProcessInfo.processInfo performSelector:selector]) {
      #pragma clang diagnostic pop
      return [NSString stringWithFormat:@"%@/%@", agent, @"macOS"];
    }
  }
  return agent;
}

@end

#endif
