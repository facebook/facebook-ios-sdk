/*
 * Copyright 2013 Facebook
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

static NSString* dialogBaseURL = @"https://m." FB_BASE_URL "/dialog/";

// this is an implementation detail class which acts
// as the delegate in or to map to a block 
@interface FBWebDialogDelegate : NSObject <FBDialogDelegate>
@property (nonatomic, copy) FBWebDialogHandler handler;
@property (nonatomic, retain) FBDialog *dialog;

- (void)goRetainYourself;

@end

@implementation FBWebDialogDelegate {
    BOOL _isSelfRetained;
}

@synthesize handler = _handler;
@synthesize dialog = _dialog;

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
    [super dealloc];
}

- (void)goRetainYourself {
    if (!_isSelfRetained) {
        [self retain];
        _isSelfRetained = YES;
    }
}

- (void)releaseSelfIfNeeded {
    self.dialog = nil;
    if (_isSelfRetained) {
        [self autorelease];
        _isSelfRetained = NO;
    }
}

- (void)completeWithResult:(FBWebDialogResult)result
                       url:(NSURL *)url
                     error:(NSError *)error {
    if (self.handler) {
        self.handler(result, url, error);
        self.handler = nil;
    }
}

// non-terminal delegate methods

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
    
    NSString *dialogURL = [dialogBaseURL stringByAppendingString:dialog];
    
    NSMutableDictionary *parametersImpl = [NSMutableDictionary dictionary];

    // start with built-in parameters
    [parametersImpl setObject:@"touch" forKey:@"display"];
    [parametersImpl setObject:FB_IOS_SDK_VERSION_STRING forKey:@"sdk"];
    [parametersImpl setObject:@"fbconnect://success" forKey:@"redirect_uri"];
    
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
        [parametersImpl setValue:session.accessTokenData.accessToken ? : @""
                          forKey:@"access_token"];
        [parametersImpl setObject:session.appID ? : @""
                           forKey:@"app_id"];
    }
    
    FBWebDialogDelegate *delegate = [[[FBWebDialogDelegate alloc] init] autorelease];
    delegate.handler = handler;
    [delegate goRetainYourself];
    
    FBDialog *d = [[FBDialog alloc] initWithURL:dialogURL
                                         params:parametersImpl
                                isViewInvisible:NO
                           frictionlessSettings:nil
                                       delegate:delegate];
    
    // this reference keeps the dialog alive as needed
    delegate.dialog = d;
    [d show];
    [d release];
}

+ (void)presentRequestsDialogModallyWithSession:(FBSession *)session
                                        message:(NSString *)message
                                          title:(NSString *)title
                                     parameters:(NSDictionary *)parameters
                                        handler:(FBWebDialogHandler)handler {
    
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
                                          handler:handler];
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
