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

#import "FBAppLinkResolver.h"

#import <UIKit/UIKit.h>

#import <Bolts/BFAppLink.h>
#import <Bolts/BFAppLinkTarget.h>
#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "FBInternalSettings.h"
#import "FBRequest+Internal.h"
#import "FBRequestConnection.h"
#import "FBUtility.h"

static NSString *const kURLKey = @"url";
static NSString *const kIOSAppStoreIdKey = @"app_store_id";
static NSString *const kIOSAppNameKey = @"app_name";
static NSString *const kWebKey = @"web";
static NSString *const kIOSKey = @"ios";
static NSString *const kIPhoneKey = @"iphone";
static NSString *const kIPadKey = @"ipad";
static NSString *const kShouldFallbackKey = @"should_fallback";
static NSString *const kAppLinksKey = @"app_links";

static void FBAppLinkResolverBoltsClassFromString(Class *clazz, NSString *className) {
    *clazz = NSClassFromString(className);
    if (*clazz == nil) {
        NSString *message = [NSString stringWithFormat:@"Unable to load class %@. Did you link Bolts.framework?", className];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:message
                                     userInfo:nil];
    }
}

@interface FBAppLinkResolver ()

@property (nonatomic, strong) NSMutableDictionary *cachedLinks;
@property (nonatomic, assign) UIUserInterfaceIdiom userInterfaceIdiom;
@end

@implementation FBAppLinkResolver

static Class g_BFTaskCompletionSourceClass;
static Class g_BFAppLinkTargetClass;
static Class g_BFAppLinkClass;
static Class g_BFTaskClass;

+ (void)initialize {
    if (self == [FBAppLinkResolver class]) {
        FBAppLinkResolverBoltsClassFromString(&g_BFTaskCompletionSourceClass, @"BFTaskCompletionSource");
        FBAppLinkResolverBoltsClassFromString(&g_BFAppLinkTargetClass, @"BFAppLinkTarget");
        FBAppLinkResolverBoltsClassFromString(&g_BFAppLinkClass, @"BFAppLink");
        FBAppLinkResolverBoltsClassFromString(&g_BFTaskClass, @"BFTask");
    }
}

- (id)initWithUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom {
    if (self = [super init]) {
        self.cachedLinks = [NSMutableDictionary dictionary];
        self.userInterfaceIdiom = userInterfaceIdiom;
    }
    return self;
}

- (void)dealloc {
    [_cachedLinks release];
    [super dealloc];
}

- (BFTask *)appLinksFromURLsInBackground:(NSArray *)urls {
    if (![FBSettings clientToken]) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                            logEntry:@"clientToken is missing for FBAppLinkResolver"];
    }
    NSMutableDictionary *appLinks = [NSMutableDictionary dictionary];
    NSMutableArray *toFind = [NSMutableArray array];
    NSMutableArray *toFindStrings = [NSMutableArray array];
    for (NSURL *url in urls) {
        @synchronized (self.cachedLinks) {
            if (self.cachedLinks[url]) {
                appLinks[url] = self.cachedLinks[url];
            } else {
                [toFind addObject:url];
                [toFindStrings addObject:[FBUtility stringByURLEncodingString:url.absoluteString]];
            }
        }
    }
    if (toFind.count == 0) {
        // All of the URLs have already been found.
        return [g_BFTaskClass taskWithResult:appLinks];
    }
    NSMutableArray *fields = [NSMutableArray arrayWithObject:kIOSKey];

    NSString *idiomSpecificField = nil;

    switch (self.userInterfaceIdiom) {
        case UIUserInterfaceIdiomPad:
            idiomSpecificField = kIPadKey;
            break;
        case UIUserInterfaceIdiomPhone:
            idiomSpecificField = kIPhoneKey;
            break;
        default:
            break;
    }
    if (idiomSpecificField) {
        [fields addObject:idiomSpecificField];
    }
    NSString *path = [NSString stringWithFormat:@"?fields=%@.fields(%@)&ids=%@",
                      kAppLinksKey,
                      [fields componentsJoinedByString:@","],
                      [toFindStrings componentsJoinedByString:@","]];
    FBRequest *request = [[[FBRequest alloc] initWithSession:nil
                                                   graphPath:path
                                                  parameters:nil
                                                  HTTPMethod:@"GET"] autorelease];
    BFTaskCompletionSource *tcs = [g_BFTaskCompletionSourceClass taskCompletionSource];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            [tcs setError:error];
            return;
        }
        for (NSURL *url in toFind) {
            id nestedObject = [[result objectForKey:url.absoluteString] objectForKey:kAppLinksKey];
            NSMutableArray *rawTargets = [NSMutableArray array];
            if (idiomSpecificField) {
                [rawTargets addObjectsFromArray:[nestedObject objectForKey:idiomSpecificField]];
            }
            [rawTargets addObjectsFromArray:[nestedObject objectForKey:kIOSKey]];

            NSMutableArray *targets = [NSMutableArray arrayWithCapacity:rawTargets.count];
            for (id rawTarget in rawTargets) {
                [targets addObject:[g_BFAppLinkTargetClass appLinkTargetWithURL:[NSURL URLWithString:[rawTarget objectForKey:kURLKey]]
                                                                     appStoreId:[rawTarget objectForKey:kIOSAppStoreIdKey]
                                                                        appName:[rawTarget objectForKey:kIOSAppNameKey]]];
            }

            id webTarget = [nestedObject objectForKey:kWebKey];
            NSString *webFallbackString = [webTarget objectForKey:kURLKey];
            NSURL *fallbackUrl = webFallbackString ? [NSURL URLWithString:webFallbackString] : url;

            NSNumber *shouldFallback = [webTarget objectForKey:kShouldFallbackKey];
            if (shouldFallback && !shouldFallback.boolValue) {
                fallbackUrl = nil;
            }

            BFAppLink *link = [g_BFAppLinkClass appLinkWithSourceURL:url
                                                             targets:targets
                                                              webURL:fallbackUrl];
            @synchronized (self.cachedLinks) {
                self.cachedLinks[url] = link;
            }
            appLinks[url] = link;
        }
        [tcs setResult:appLinks];
    }];
    return tcs.task;
}

- (BFTask *)appLinkFromURLInBackground:(NSURL *)url {
    // Implement in terms of appLinksFromURLsInBackground
    BFTask *resolveTask = [self appLinksFromURLsInBackground:@[url]];
    return [resolveTask continueWithSuccessBlock:^id(BFTask *task) {
        return task.result[url];
    }];
}

+ (id)resolver {
    return [[[self alloc] initWithUserInterfaceIdiom:UI_USER_INTERFACE_IDIOM()] autorelease];
}

@end
