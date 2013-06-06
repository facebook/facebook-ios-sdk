/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Social/Social.h>

#import "FBSession+Internal.h"
#import "FBAccessTokenData.h"
#import "FBWebDialogs.h"
#import "FBUtility.h"
#import "FBDialog.h"
#import "FBSDKVersion.h"
#import "FBViewController+Internal.h"
#import "FBFrictionlessDialogSupportDelegate.h"
#import "FBFrictionlessRequestSettings.h"
#import "FBFrictionlessRecipientCache.h"
#import "FBSettings.h"
#import "FBLogger.h"

static NSString* dialogBaseURL = @"https://m." FB_BASE_URL "/dialog/";

// this is an implementation detail class which acts
// as the delegate in or to map to a block 
@interface FBWebDialogInternalDelegate : NSObject <FBDialogDelegate>

@property (nonatomic, copy) FBWebDialogHandler handler;
@property (nonatomic, retain) FBDialog *dialog;
@property (nonatomic, copy) NSString *dialogMethod;
@property (nonatomic, copy) NSDictionary *parameters;
@property (nonatomic, retain) FBSession *session;
@property (nonatomic, assign) id<FBWebDialogsDelegate> delegate;

- (void)goRetainYourself;

@end

@implementation FBWebDialogInternalDelegate {
    BOOL _isSelfRetained;
}

@synthesize handler = _handler;
@synthesize dialog = _dialog;
@synthesize dialogMethod = _dialogMethod;
@synthesize parameters = _parameters;
@synthesize session = _session;
@synthesize delegate = _delegate;

- (id)init {
    self = [super init];
    if (self) {
        _isSelfRetained = NO;
    }
    return self;
}

- (void)dealloc {
    self.handler = nil;
    self.dialog = nil;
    self.dialogMethod = nil;
    self.parameters = nil;
    self.session = nil;
    // self.delegate is assign per the pattern
    [super dealloc];
}

// The SDK 3.* and greater maintains compatibility with the 2.0 SDKs, in order to simplify migration
// for customers moving to 3.*. Due to this, there are a few ugly bits where we have to hack to keep
// the legacy code working, without letting its anti-patterns bleed into the newer (and hopefully
// cleaner) 3.* API, and customer app. The self-retention madness in this class is an example of this.
// So without further ado...
- (void)goRetainYourself {
    if (!_isSelfRetained) {
        [self retain];
        _isSelfRetained = YES;
    }
}

- (void)releaseSelfIfNeeded {
    self.handler = nil; // insurance
    self.delegate = nil; // insurance
    self.dialog = nil;
    if (_isSelfRetained) {
        [self autorelease];
        _isSelfRetained = NO;
    }
}

- (void)completeWithResult:(FBWebDialogResult)result
                       url:(NSURL *)url
                     error:(NSError *)error {
    
    // optional delegate invocation
    if ([self.delegate respondsToSelector:@selector(webDialogsWillDismissDialog:parameters:session:result:url:error:)]) {
        [self.delegate webDialogsWillDismissDialog:self.dialogMethod
                                        parameters:self.parameters
                                           session:self.session
                                            result:&result       // may mutate
                                               url:&url          // may mutate
                                             error:&error];      // may mutate
        
        // important! we must nil the delegate before nil'ing the handler, to preserve
        // the case where the calling app is using a block to retain the delegate
        self.delegate = nil;
    }
    
    if (self.handler) {
        self.handler(result, url, error);
        self.handler = nil;
    }
}

// non-terminal delegate methods

- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url {
    BOOL result = YES;
    // optional delegate invocation
    if ([self.delegate respondsToSelector:@selector(webDialogsDialog:parameters:session:shouldAutoHandleURL:)]) {
        result = [self.delegate webDialogsDialog:self.dialogMethod
                                      parameters:self.parameters
                                         session:self.session
                             shouldAutoHandleURL:url];
    }
    return result;
}

- (void)dialogCompleteWithUrl:(NSURL *)url {
    [self completeWithResult:FBWebDialogResultDialogCompleted
                         url:url
                       error:nil];
}

- (void)dialogDidNotCompleteWithUrl:(NSURL *)url {
    [self completeWithResult:FBWebDialogResultDialogNotCompleted
                         url:url
                       error:nil];
}

// terminal delegate methods

- (void)dialogDidComplete:(FBDialog *)dialog {
    [self completeWithResult:FBWebDialogResultDialogCompleted
                         url:nil
                       error:nil];
    [self releaseSelfIfNeeded];
}

- (void)dialogDidNotComplete:(FBDialog *)dialog {
    [self completeWithResult:FBWebDialogResultDialogNotCompleted
                         url:nil
                       error:nil];
    [self releaseSelfIfNeeded];
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    [self completeWithResult:FBWebDialogResultDialogNotCompleted
                         url:nil
                       error:error];
    [self releaseSelfIfNeeded];
}

@end

@implementation FBWebDialogs

+ (void)presentDialogModallyWithSession:(FBSession *)session
                                 dialog:(NSString *)dialog
                             parameters:(NSDictionary *)parameters
                                handler:(FBWebDialogHandler)handler {
    [FBWebDialogs presentDialogModallyWithSession:session
                                           dialog:dialog
                                       parameters:parameters
                                          handler:handler
                                         delegate:nil];
}

+ (void)presentDialogModallyWithSession:(FBSession *)session
                                 dialog:(NSString *)dialog
                             parameters:(NSDictionary *)parameters
                                handler:(FBWebDialogHandler)handler
                               delegate:(id<FBWebDialogsDelegate>)delegate {
    
    NSString *dialogURL = [dialogBaseURL stringByAppendingString:dialog];
    
    NSMutableDictionary *parametersImpl = [NSMutableDictionary dictionary];

    // start with built-in parameters
    [parametersImpl setObject:@"touch" forKey:@"display"];
    [parametersImpl setObject:FB_IOS_SDK_VERSION_STRING forKey:@"sdk"];
    [parametersImpl setObject:@"fbconnect://success" forKey:@"redirect_uri"];
    [parametersImpl setObject:[FBSettings defaultAppID] ? : @"" forKey:@"app_id"];
    
    // then roll in developer provided parameters
    if (parameters) {
        [parametersImpl addEntriesFromDictionary:parameters];
    }
   
    // if a session isn't specified, fall back to active session when available
    if (!session) {
        session = [FBSession activeSessionIfOpen];
    }
    
    // if we have a session, then we set app_id and access_token, otherwise
    // caller must pass parameters to meet the requirements of the dialog
    if (session) {
        // set access_token and app_id
        [parametersImpl setObject:session.accessTokenData.accessToken ? : @""
                          forKey:@"access_token"];
        [parametersImpl setObject:session.appID ? : @""
                           forKey:@"app_id"];
    }
    
    NSString *app_id = [parametersImpl objectForKey:@"app_id"];
    if ([app_id length] == 0) {
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                            logEntry:@"You must specify an app_id via an FBSession, the parameters, or the plist"];
    }

    BOOL isViewInvisible = NO;
    FBFrictionlessRequestSettings *frictionlessSettings = nil;
    
    // optional delegate invocation
    if ([delegate respondsToSelector:@selector(webDialogsWillPresentDialog:parameters:session:)]) {
        [delegate webDialogsWillPresentDialog:dialog
                                   parameters:parametersImpl
                                      session:session];

        // Important! Per the spec of the internal protocol, calls to FBFrictionlessDialogSupportDelegate
        // methods must be made after the base delegate call to webDialogsWillPresentDialog
        if ([delegate conformsToProtocol:@protocol(FBFrictionlessDialogSupportDelegate)]) {
            id<FBFrictionlessDialogSupportDelegate> supportDelegate = (id<FBFrictionlessDialogSupportDelegate>)delegate;
            isViewInvisible = supportDelegate.frictionlessShouldMakeViewInvisible;
            frictionlessSettings = supportDelegate.frictionlessSettings;
        }
    }
    
    FBWebDialogInternalDelegate *innerDelegate = [[[FBWebDialogInternalDelegate alloc] init] autorelease];
    innerDelegate.dialogMethod = dialog;
    innerDelegate.parameters = parametersImpl;
    innerDelegate.session = session;
    innerDelegate.handler = handler;
    innerDelegate.delegate = delegate;
    [innerDelegate goRetainYourself];
    
    FBDialog *d = [[FBDialog alloc] initWithURL:dialogURL
                                         params:parametersImpl
                                isViewInvisible:isViewInvisible
                           frictionlessSettings:frictionlessSettings
                                       delegate:innerDelegate];
    
    // this reference keeps the dialog alive as needed
    innerDelegate.dialog = d;
    [d show];
    [d release];
}

+ (void)presentRequestsDialogModallyWithSession:(FBSession *)session
                                        message:(NSString *)message
                                          title:(NSString *)title
                                     parameters:(NSDictionary *)parameters
                                        handler:(FBWebDialogHandler)handler {
    [FBWebDialogs presentRequestsDialogModallyWithSession:session
                                                  message:message
                                                    title:title
                                               parameters:parameters
                                                  handler:handler
                                              friendCache:nil];
}

+ (void)presentRequestsDialogModallyWithSession:(FBSession *)session
                                        message:(NSString *)message
                                          title:(NSString *)title
                                     parameters:(NSDictionary *)parameters
                                        handler:(FBWebDialogHandler)handler
                                    friendCache:(FBFrictionlessRecipientCache *)friendCache {
    
    NSMutableDictionary *parametersImpl = [NSMutableDictionary dictionary];
    
    // start with developer provided parameters
    if (parameters) {
        [parametersImpl addEntriesFromDictionary:parameters];
    }
    
    // then roll in argument parameters
    if (message) {
        [parametersImpl setObject:message forKey:@"message"];
    }
    
    if (title) {
        [parametersImpl setObject:title forKey:@"title"];
    }
        
    [FBWebDialogs presentDialogModallyWithSession:session
                                           dialog:@"apprequests"
                                       parameters:parametersImpl
                                          handler:handler
                                         delegate:friendCache];
}

+ (void)presentFeedDialogModallyWithSession:(FBSession *)session
                                 parameters:(NSDictionary *)parameters
                                    handler:(FBWebDialogHandler)handler {
    [FBWebDialogs presentDialogModallyWithSession:session
                                           dialog:@"feed"
                                       parameters:parameters
                                          handler:handler];
}

@end
