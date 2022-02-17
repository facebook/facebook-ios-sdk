/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if !TARGET_OS_TV

#import "FBSDKWebViewAppLinkResolver.h"

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit_Basics/FBSDKCoreKit_Basics.h>

#import "FBSDKAppLink.h"
#import "FBSDKErrorFactory+Internal.h"
#import "FBSDKErrorReporter.h"
#import "FBSDKWebViewAppLinkResolverWebViewDelegate.h"
#import "NSURLSession+Protocols.h"

/**
 Describes the callback for appLinkFromURLInBackground.
 @param result the results from following redirects
 @param error the error during the request, if any
 */
typedef void (^ FBSDKURLFollowRedirectsBlock)(NSDictionary<NSString *, id> *result, NSError *_Nullable error)
NS_SWIFT_NAME(URLFollowRedirectsBlock);

// Defines JavaScript to extract app link tags from HTML content
static NSString *const FBSDKWebViewAppLinkResolverTagExtractionJavaScript = @""
"(function() {"
"  var metaTags = document.getElementsByTagName('meta');"
"  var results = [];"
"  for (var i = 0; i < metaTags.length; i++) {"
"    var property = metaTags[i].getAttribute('property');"
"    if (property && property.substring(0, 'al:'.length) === 'al:') {"
"      var tag = { \"property\": metaTags[i].getAttribute('property') };"
"      if (metaTags[i].hasAttribute('content')) {"
"        tag['content'] = metaTags[i].getAttribute('content');"
"      }"
"      results.push(tag);"
"    }"
"  }"
"  return JSON.stringify(results);"
"})()";
static NSString *const FBSDKWebViewAppLinkResolverIOSURLKey = @"url";
static NSString *const FBSDKWebViewAppLinkResolverIOSAppStoreIdKey = @"app_store_id";
static NSString *const FBSDKWebViewAppLinkResolverIOSAppNameKey = @"app_name";
static NSString *const FBSDKWebViewAppLinkResolverDictionaryValueKey = @"_value";
static NSString *const FBSDKWebViewAppLinkResolverPreferHeader = @"Prefer-Html-Meta-Tags";
static NSString *const FBSDKWebViewAppLinkResolverMetaTagPrefix = @"al";
static NSString *const FBSDKWebViewAppLinkResolverWebKey = @"web";
static NSString *const FBSDKWebViewAppLinkResolverIOSKey = @"ios";
static NSString *const FBSDKWebViewAppLinkResolverIPhoneKey = @"iphone";
static NSString *const FBSDKWebViewAppLinkResolverIPadKey = @"ipad";
static NSString *const FBSDKWebViewAppLinkResolverWebURLKey = @"url";
static NSString *const FBSDKWebViewAppLinkResolverShouldFallbackKey = @"should_fallback";

@interface FBSDKWebViewAppLinkResolver ()

@property (nonatomic, strong) id<FBSDKSessionProviding> sessionProvider;
@property (nonatomic, strong) id<FBSDKErrorCreating> errorFactory;

@end

@implementation FBSDKWebViewAppLinkResolver

- (instancetype)init
{
  FBSDKErrorFactory *factory = [[FBSDKErrorFactory alloc] initWithReporter:FBSDKErrorReporter.shared];
  return [self initWithSessionProvider:NSURLSession.sharedSession
                          errorFactory:factory];
}

- (instancetype)initWithSessionProvider:(id<FBSDKSessionProviding>)sessionProvider
                           errorFactory:(id<FBSDKErrorCreating>)errorFactory
{
  if ((self = [super init])) {
    _sessionProvider = sessionProvider;
    _errorFactory = errorFactory;
  }
  return self;
}

+ (instancetype)sharedInstance
{
  static id instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [self new];
  });
  return instance;
}

- (void)followRedirects:(NSURL *)url handler:(FBSDKURLFollowRedirectsBlock)handler
{
  // This task will be resolved with either the redirect NSURL
  // or a dictionary with the response data to be returned.
  void (^completion)(NSURLResponse *response, NSData *data, NSError *error) = ^(NSURLResponse *response, NSData *data, NSError *error) {
    if (error) {
      handler(nil, error);
      return;
    }

    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

      // NSURLConnection usually follows redirects automatically, but the
      // documentation is unclear what the default is. This helps it along.
      if (httpResponse.statusCode >= 300 && httpResponse.statusCode < 400) {
        NSString *redirectString = httpResponse.allHeaderFields[@"Location"];
        NSURL *redirectURL = [NSURL URLWithString:redirectString];
        [self followRedirects:redirectURL handler:handler];
        return;
      }
    }

    if (data) {
      handler(@{ @"response" : response, @"data" : data }, nil);
    } else {
      NSString *message = @"Invalid network response - missing data";
      NSError *sdkError = [self.errorFactory unknownErrorWithMessage:message
                                                            userInfo:nil];
      handler(nil, sdkError);
    }
  };

  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setValue:FBSDKWebViewAppLinkResolverMetaTagPrefix forHTTPHeaderField:FBSDKWebViewAppLinkResolverPreferHeader];

  id<FBSDKSessionDataTask> task = [self.sessionProvider dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    completion(response, data, error);
  }];
  [task resume];
}

- (void)appLinkFromURL:(NSURL *)url handler:(FBSDKAppLinkBlock)handler
{
  [self followRedirects:url handler:^(NSDictionary<NSString *, id> *result, NSError *_Nullable error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) {
        handler(nil, error);
        return;
      }

      NSHTTPURLResponse *response = result[@"response"];

      WKWebView *webView = [WKWebView new];

      FBSDKWebViewAppLinkResolverWebViewDelegate *listener = [FBSDKWebViewAppLinkResolverWebViewDelegate new];
      __block FBSDKWebViewAppLinkResolverWebViewDelegate *retainedListener = listener;
      listener.didFinishLoad = ^(WKWebView *view) {
        if (retainedListener) {
          [self getALDataFromLoadedPage:view handler:^(NSDictionary<NSString *, id> *ogData) {
            [view removeFromSuperview];
            view.navigationDelegate = nil;
            retainedListener = nil;
            handler([self appLinkFromALData:ogData destination:url], nil);
          }];
        }
      };
      listener.didFailLoadWithError = ^(WKWebView *view, NSError *loadError) {
        if (retainedListener) {
          [view removeFromSuperview];
          view.navigationDelegate = nil;
          retainedListener = nil;
          handler(nil, loadError);
        }
      };
      webView.navigationDelegate = listener;
      webView.hidden = YES;
      [webView loadRequest:[NSURLRequest requestWithURL:response.URL]];
      UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
      [window addSubview:webView];
    });
  }];
}

/*
 Builds up a data structure filled with the app link data from the meta tags on a page.
 The structure of this object is a dictionary where each key holds an array of app link
 data dictionaries.  Values are stored in a key called "_value".
 */
- (NSDictionary<NSString *, id> *)parseALData:(NSArray<NSDictionary<NSString *, id> *> *)dataArray
{
  NSMutableDictionary<NSString *, id> *al = [NSMutableDictionary dictionary];
  for (NSDictionary<NSString *, id> *tag in dataArray) {
    NSString *name = tag[@"property"];
    if (![name isKindOfClass:NSString.class]) {
      continue;
    }
    NSArray<NSString *> *nameComponents = [name componentsSeparatedByString:@":"];
    if (![nameComponents.firstObject isEqualToString:FBSDKWebViewAppLinkResolverMetaTagPrefix]) {
      continue;
    }
    NSMutableDictionary<NSString *, id> *root = al;
    for (NSUInteger i = 1; i < nameComponents.count; i++) {
      NSMutableArray<NSMutableDictionary<NSString *, id> *> *children = root[[FBSDKTypeUtility array:nameComponents objectAtIndex:i]];
      if (!children) {
        children = [NSMutableArray array];
        [FBSDKTypeUtility dictionary:root setObject:children forKey:[FBSDKTypeUtility array:nameComponents objectAtIndex:i]];
      }
      NSMutableDictionary<NSString *, id> *child = children.lastObject;
      if (!child || i == nameComponents.count - 1) {
        child = [NSMutableDictionary dictionary];
        [FBSDKTypeUtility array:children addObject:child];
      }
      root = child;
    }
    if (tag[@"content"]) {
      [FBSDKTypeUtility dictionary:root setObject:tag[@"content"] forKey:FBSDKWebViewAppLinkResolverDictionaryValueKey];
    }
  }
  return al;
}

- (void)getALDataFromLoadedPage:(WKWebView *)webView
                        handler:(void (^)(NSDictionary<NSString *, id> *))handler
{
  // Run some JavaScript in the webview to fetch the meta tags.
  [webView evaluateJavaScript:FBSDKWebViewAppLinkResolverTagExtractionJavaScript
            completionHandler:^(id _Nullable evaluateResult, NSError *_Nullable error) {
              NSString *jsonString = [evaluateResult isKindOfClass:NSString.class] ? evaluateResult : nil;
              error = nil;
              NSData *encodedJSON = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
              if (encodedJSON) {
                NSArray<NSDictionary<NSString *, id> *> *arr =
                [FBSDKTypeUtility JSONObjectWithData:encodedJSON
                                             options:0
                                               error:&error];
                handler([self parseALData:arr]);
              }
            }];
}

/*
 Converts app link data into a FBSDKAppLink containing the targets relevant for this platform.
 */
- (FBSDKAppLink *)appLinkFromALData:(NSDictionary<NSString *, id> *)appLinkDict destination:(NSURL *)destination
{
  NSMutableArray<FBSDKAppLinkTarget *> *linkTargets = [NSMutableArray array];

  NSArray<NSDictionary<NSString *, id> *> *platformData = nil;
  const UIUserInterfaceIdiom idiom = UIDevice.currentDevice.userInterfaceIdiom;
  if (idiom == UIUserInterfaceIdiomPad) {
    platformData = @[appLinkDict[FBSDKWebViewAppLinkResolverIPadKey] ?: @{},
                     appLinkDict[FBSDKWebViewAppLinkResolverIOSKey] ?: @{}];
  } else if (idiom == UIUserInterfaceIdiomPhone) {
    platformData = @[appLinkDict[FBSDKWebViewAppLinkResolverIPhoneKey] ?: @{},
                     appLinkDict[FBSDKWebViewAppLinkResolverIOSKey] ?: @{}];
  } else {
    // Future-proofing. Other User Interface idioms should only hit ios.
    platformData = @[appLinkDict[FBSDKWebViewAppLinkResolverIOSKey] ?: @{}];
  }

  for (NSArray<NSDictionary<NSString *, id> *> *platformObjects in platformData) {
    for (NSDictionary<NSString *, NSArray<NSDictionary<NSString *, id> *> *> *platformDict in platformObjects) {
      // The schema requires a single url/app store id/app name,
      // but we could find multiple of them. We'll make a best effort
      // to interpret this data.
      NSArray<NSDictionary<NSString *, id> *> *urls = platformDict[FBSDKWebViewAppLinkResolverIOSURLKey];
      NSArray<NSDictionary<NSString *, id> *> *appStoreIds = platformDict[FBSDKWebViewAppLinkResolverIOSAppStoreIdKey];
      NSArray<NSDictionary<NSString *, id> *> *appNames = platformDict[FBSDKWebViewAppLinkResolverIOSAppNameKey];

      NSUInteger maxCount = MAX(urls.count, MAX(appStoreIds.count, appNames.count));

      for (NSUInteger i = 0; i < maxCount; i++) {
        NSString *urlString = [FBSDKTypeUtility array:urls objectAtIndex:i][FBSDKWebViewAppLinkResolverDictionaryValueKey];
        NSURL *url = urlString ? [NSURL URLWithString:urlString] : nil;
        NSString *appStoreId = [FBSDKTypeUtility array:appStoreIds objectAtIndex:i][FBSDKWebViewAppLinkResolverDictionaryValueKey];
        NSString *appName = [FBSDKTypeUtility array:appNames objectAtIndex:i][FBSDKWebViewAppLinkResolverDictionaryValueKey];
        FBSDKAppLinkTarget *target = [FBSDKAppLinkTarget appLinkTargetWithURL:url
                                                                   appStoreId:appStoreId
                                                                      appName:appName];
        [FBSDKTypeUtility array:linkTargets addObject:target];
      }
    }
  }

  NSDictionary<NSString *, id> *webDict = appLinkDict[FBSDKWebViewAppLinkResolverWebKey][0];
  NSString *webUrlString = webDict[FBSDKWebViewAppLinkResolverWebURLKey][0][FBSDKWebViewAppLinkResolverDictionaryValueKey];
  NSString *shouldFallbackString = webDict[FBSDKWebViewAppLinkResolverShouldFallbackKey][0][FBSDKWebViewAppLinkResolverDictionaryValueKey];

  NSURL *webUrl = destination;

  if (shouldFallbackString
      && [@[@"no", @"false", @"0"] containsObject:shouldFallbackString.lowercaseString]) {
    webUrl = nil;
  }
  if (webUrl && webUrlString) {
    webUrl = [NSURL URLWithString:webUrlString];
  }

  return [FBSDKAppLink appLinkWithSourceURL:destination
                                    targets:linkTargets
                                     webURL:webUrl];
}

@end

#endif
