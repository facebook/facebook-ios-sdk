/*
 * Copyright 2012 Facebook
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

#import <UIKit/UIImage.h>
#import "JSON.h"
#import "FBError.h"
#import "FBURLConnection.h"
#import "FBRequestBody.h"
#import "FBSession.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "Facebook.h"

// URL construction constants
NSString *const kGraphURL = @"https://graph.facebook.com";
NSString *const kGraphBaseURL = @"https://graph.facebook.com/";
NSString *const kRestBaseURL = @"https://api.facebook.com/method/";
NSString *const kBatchKey = @"batch";
NSString *const kBatchMethodKey = @"method";
NSString *const kBatchRelativeURLKey = @"relative_url";
NSString *const kBatchAttachmentKey = @"attached_files";
NSString *const kBatchFileNamePrefix = @"file";

NSString *const kAccessTokenKey = @"access_token";
NSString *const kSDK = @"ios";
NSString *const kSDKVersion = @"2";
NSString *const kUserAgentBase = @"FBiOSSDK";
NSString *const kBundleVersionKey = @"CFBundleVersion";

static const int kRESTAPIAccessTokenErrorCode = 190;
static const NSTimeInterval kDefaultTimeout = 180.0;

// ----------------------------------------------------------------------------
// Private class to store requests and their metadata.
//
@interface FBRequestMetadata : NSObject
@property (nonatomic, retain) FBRequest *request;
@property (nonatomic, copy) FBRequestHandler completionHandler;
@property (nonatomic, copy) NSString *batchEntryName;

- (id) initWithRequest:(FBRequest *)request
     completionHandler:(FBRequestHandler)handler
        batchEntryName:(NSString *)name;
@end

@implementation FBRequestMetadata
@synthesize batchEntryName = _batchEntryName;
@synthesize completionHandler = _completionHandler;
@synthesize request = _request;

- (id) initWithRequest:(FBRequest *)request
     completionHandler:(FBRequestHandler)handler
        batchEntryName:(NSString *)name {
    
    if (self = [super init]) {
        self.request = request;
        self.completionHandler = handler;
        self.batchEntryName = name;
    }
    return self;
}

- (void) dealloc {
    [_request release];
    [_completionHandler release];
    [_batchEntryName release];
    [super dealloc];
}

@end

// ----------------------------------------------------------------------------
// FBRequestConnectionState

typedef enum FBRequestConnectionState {
    kStateCreated,
    kStateSerialized,
    kStateStarted,
    kStateCompleted,
    kStateCancelled,
} FBRequestConnectionState;

// ----------------------------------------------------------------------------
// Private properties and methods

@interface FBRequestConnection ()

@property (nonatomic, retain) FBURLConnection *connection;
@property (nonatomic, retain) NSMutableArray *requests;
@property (nonatomic) FBRequestConnectionState state;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic, retain) NSMutableURLRequest *internalUrlRequest;
@property (nonatomic, retain, readwrite) NSHTTPURLResponse *urlResponse;
@property (nonatomic, retain) FBRequest *deprecatedRequest;

- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout;

- (NSURL *)urlWithSingleRequest:(FBRequest *)request;

- (NSString *)commonAccessToken:(NSArray *)requests;

- (void)appendJSONRequests:(NSArray *)requests
                    toBody:(FBRequestBody *)body
             includeTokens:(BOOL)includeTokens
        andNameAttachments:(NSMutableDictionary *)attachments;

- (void)addRequest:(FBRequestMetadata *)metadata
           toBatch:(NSArray *)batch
      includeToken:(BOOL)includeToken
       attachments:(NSDictionary *)attachments;

- (BOOL)isAttachment:(id)item;

- (void)appendAttachments:(NSDictionary *)attachments
                   toBody:(FBRequestBody *)body
              addFormData:(BOOL)addFormData;

- (void)completeWithResponse:(NSURLResponse *)response
                        data:(NSData *)data
                     orError:(NSError *)error;

- (NSArray *)parseJSONResponse:(NSData *)data
                         error:(NSError **)error;

- (void)completeDeprecatedWithData:(NSData *)data
                           results:(NSArray *)results
                           orError:(NSError *)error;

- (void)completeWithResults:(NSArray *)results
                    orError:(NSError *)error;

- (NSError *)errorFromResult:(id)idResult;

- (NSError *)errorWithCode:(FBErrorCode)code
                statusCode:(int)statusCode
        parsedJSONResponse:(id)response;

- (NSError *)checkConnectionError:(NSError *)innerError
                       statusCode:(int)statusCode
               parsedJSONResponse:(id)response;

- (NSError *)errorWithCode:(FBErrorCode)code
                  userInfo:(NSDictionary *)userInfo;

- (BOOL)isInvalidSessionError:(NSError *)error;

+ (NSString *)userAgent;

@end

// ----------------------------------------------------------------------------
// FBRequestConnection

@implementation FBRequestConnection

// ----------------------------------------------------------------------------
// Property implementations

@synthesize connection = _connection;
@synthesize requests = _requests;
@synthesize state = _state;
@synthesize timeout = _timeout;
@synthesize internalUrlRequest = _internalUrlRequest;
@synthesize urlResponse = _urlResponse;
@synthesize deprecatedRequest = _deprecatedRequest;

- (NSMutableURLRequest *)urlRequest
{
    if (self.internalUrlRequest) {
        return self.internalUrlRequest;
    } else {
        // CONSIDER: Could move to kStateSerialized here by caching result, but
        // it seems bad for a get accessor to modify state in observable manner.
        return [self requestWithBatch:self.requests timeout:_timeout];
    }
}

- (void)setUrlRequest:(NSMutableURLRequest *)request
{
    NSAssert((self.state == kStateCreated) || (self.state == kStateSerialized),
             @"Cannot set urlRequest after starting or cancelling.");
    self.state = kStateSerialized;

    self.internalUrlRequest = request;
}

// ----------------------------------------------------------------------------
// Lifetime

- (id)init
{
    return [self initWithTimeout:kDefaultTimeout];
}

- (id)initWithTimeout:(NSTimeInterval)timeout
{
    if (self = [super init]) {
        _requests = [[NSMutableArray alloc] init];
        _timeout = timeout;
        _state = kStateCreated;
    }
    return self;
}

- (void)dealloc
{
    [_connection cancel];
    [_connection release];
    [_requests release];
    [_internalUrlRequest release];
    [_urlResponse release];
    [_deprecatedRequest release];
    [super dealloc];
}

// ----------------------------------------------------------------------------
// Public messages

- (void)addRequest:(FBRequest *)request
 completionHandler:(FBRequestHandler)handler
{
    [self addRequest:request completionHandler:handler batchEntryName:nil];
}

- (void)addRequest:(FBRequest *)request
 completionHandler:(FBRequestHandler)handler
    batchEntryName:(NSString *)name
{
    NSAssert(self.state == kStateCreated,
             @"Requests must be added before starting or cancelling.");

    FBRequestMetadata *metadata = [[FBRequestMetadata alloc] initWithRequest:request
                                                           completionHandler:handler
                                                              batchEntryName:name];
    [self.requests addObject:metadata];
}

- (FBRequestConnection *)start
{
    NSAssert((self.state == kStateCreated) || (self.state == kStateSerialized),
             @"Cannot call start again after calling start or cancel.");
    self.state = kStateStarted;

    if ([self.requests count] == 1) {
        FBRequestMetadata *firstMetadata = [self.requests objectAtIndex:0];
        if ([firstMetadata.request delegate]) {
            self.deprecatedRequest = firstMetadata.request;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [self.deprecatedRequest setState:kFBRequestStateLoading];
#pragma GCC diagnostic pop
        }
    }

    NSMutableURLRequest *request = self.urlRequest;
    FBURLConnectionHandler handler =
        ^(FBURLConnection *connection,
          NSError *error,
          NSURLResponse *response,
          NSData *responseData) {
        [self completeWithResponse:response data:responseData orError:error];
    };

    id<FBRequestDelegate> deprecatedDelegate = [self.deprecatedRequest delegate];
    if ([deprecatedDelegate respondsToSelector:@selector(requestLoading:)]) {
        [deprecatedDelegate requestLoading:self.deprecatedRequest];
    }

    FBURLConnection *connection = [[FBURLConnection alloc]
                                       initWithRequest:request
                                     completionHandler:handler];
    self.connection = connection;
    [connection release];

    return self;
}

- (void)cancel {
    [self.connection cancel];
    self.connection = nil;
    self.state = kStateCancelled;
}

// ----------------------------------------------------------------------------
// Private messages

//
// Generates a NSURLRequest based on the contents of self.requests, and sets
// options on the request.  Chooses between URL-based request for a single
// request and JSON-based request for batches.
//
- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout
{
    FBRequestBody *body = [[FBRequestBody alloc] init];
    NSMutableURLRequest *request;

    if ([requests count] == 1) {
        FBRequestMetadata *metadata = [requests objectAtIndex:0];
        NSURL *url = [self urlWithSingleRequest:metadata.request];
        request = [NSMutableURLRequest requestWithURL:url
                                          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                      timeoutInterval:timeout];

        NSString *httpMethod = metadata.request.HTTPMethod;
        [request setHTTPMethod:httpMethod];
        [self appendAttachments:metadata.request.parameters
                         toBody:body
                    addFormData:[httpMethod isEqualToString:@"POST"]];
    } else {
        NSString *commonToken = [self commonAccessToken:requests];
        if (commonToken) {
            [body appendWithKey:kAccessTokenKey formValue:commonToken];
        }

        NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
        [self appendJSONRequests:requests
                          toBody:body
                   includeTokens:(!commonToken)
              andNameAttachments:attachments];

        [self appendAttachments:attachments toBody:body addFormData:NO];
        [attachments release];

        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kGraphURL]
                                          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                      timeoutInterval:timeout];
        [request setHTTPMethod:@"POST"];

    }

    [request setHTTPBody:[body data]];
    [body release];

    [request setValue:[FBRequestConnection userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[FBRequestBody mimeContentType] forHTTPHeaderField:@"Content-Type"];

    return request;
}

//
// Generates a URL for a batch containing only a single request,
// and names all attachments that need to go in the body of the
// request.
//
// The URL contains all parameters that are not body attachments,
// including the session key if present.
//
// Attachments are named and referenced by name in the URL.
//
- (NSURL *)urlWithSingleRequest:(FBRequest *)request
{
    [request.parameters setValue:@"json" forKey:@"format"];
    [request.parameters setValue:kSDK forKey:@"sdk"];
    [request.parameters setValue:kSDKVersion forKey:@"sdk_version"];
    NSString *token = request.session.accessToken;
    if (token) {
        [request.parameters setValue:token forKey:kAccessTokenKey];
    }

    NSString *baseURL;
    if (request.restMethod) {
        baseURL = [kRestBaseURL stringByAppendingString:request.restMethod];
    } else {
        baseURL = [kGraphBaseURL stringByAppendingString:request.graphPath];
    }

    // TODO: move serializeURL to a utility class next to isAttachment and
    // appendAttachments.  The types it ignores need to be in sync with
    // the attachment code.
    NSString *url = [FBRequest serializeURL:baseURL
                                     params:request.parameters
                                 httpMethod:request.HTTPMethod];
    return [NSURL URLWithString:url];
}

//
// If all requests in a batch share the same access token, this returns it,
// otherwise nil.
//
- (NSString *)commonAccessToken:(NSArray *)requests
{
    if ([requests count]) {
        FBRequestMetadata *firstMetadata = [requests objectAtIndex:0];
        NSString *firstToken = firstMetadata.request.session.accessToken;
        if (firstToken) {
            for (FBRequestMetadata *metadata in requests) {
                if (![firstToken isEqualToString:metadata.request.session.accessToken]) {
                    return nil;
                }
            }
            return firstToken;
        }
    }
    return nil;
}

//
// Serializes all requests in the batch to JSON and appends the result to
// body.  Also names all attachments that need to go as separate blocks in
// the body of the request.
//
// All the requests are serialized into JSON, with any binary attachments
// named and referenced by name in the JSON.
//
- (void)appendJSONRequests:(NSArray *)requests
                    toBody:(FBRequestBody *)body
             includeTokens:(BOOL)includeTokens
        andNameAttachments:(NSMutableDictionary *)attachments
{
    NSMutableArray *batch = [[NSMutableArray alloc] init];
    for (FBRequestMetadata *metadata in requests) {
        [self addRequest:metadata
                 toBatch:batch
            includeToken:includeTokens
             attachments:attachments];
    }

    SBJSON *writer = [[SBJSON alloc] init];
    NSString *jsonBatch = [writer stringWithObject:batch];
    [writer release];
    [batch release];

    [body appendWithKey:kBatchKey formValue:jsonBatch];
}

//
// Adds request data to a batch in a format expected by the JsonWriter.
// Binary attachments are referenced by name in JSON and added to the
// attachments dictionary.  If includeToken is set, this will attach the
// corresponding token to each JSON request.
//
- (void)addRequest:(FBRequestMetadata *)metadata
           toBatch:(NSArray *)batch
      includeToken:(BOOL)includeToken
       attachments:(NSDictionary *)attachments
{
    NSMutableDictionary *requestElement = [[[NSMutableDictionary alloc] init] autorelease];

    // TODO: error if things are not set
    [requestElement setObject:metadata.request.graphPath forKey:kBatchRelativeURLKey];
    [requestElement setObject:metadata.request.HTTPMethod forKey:kBatchMethodKey];

    if (metadata.batchEntryName) {
        [requestElement setObject:metadata.batchEntryName forKey:@"name"];
    }

    if (includeToken) {
        NSString *token = metadata.request.session.accessToken;
        if (token) {
            [metadata.request.parameters setObject:token forKey:kAccessTokenKey];
        }
    }

    NSMutableString *attachmentNames = [NSString string];

    for (id key in [metadata.request.parameters keyEnumerator]) {
        NSObject *value = [metadata.request.parameters objectForKey:key];
        if ([self isAttachment:value]) {
            NSString *name = [NSString stringWithFormat:@"%@%d",
                                       kBatchFileNamePrefix,
                                       [attachmentNames length]];
            if ([attachmentNames length]) {
                [attachmentNames appendString:@","];
            }
            [attachmentNames appendString:name];
            [attachments setValue:value forKey:name];
        } else {
            [requestElement setObject:value forKey:key];
        }
    }

    if ([attachmentNames length]) {
        [requestElement setObject:attachmentNames forKey:kBatchAttachmentKey];
    }
}

- (BOOL)isAttachment:(id)item
{
    return
        [item isKindOfClass:[UIImage class]] ||
        [item isKindOfClass:[NSData class]];
}

- (void)appendAttachments:(NSDictionary *)attachments
                   toBody:(FBRequestBody *)body
              addFormData:(BOOL)addFormData
{
    if (addFormData) {
        for (NSString *key in [attachments keyEnumerator]) {
            NSObject *value = [attachments objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                [body appendWithKey:key formValue:(NSString *)value];
            }
        }
    }

    for (NSString *key in [attachments keyEnumerator]) {
        NSObject *value = [attachments objectForKey:key];
        if ([value isKindOfClass:[UIImage class]]) {
            [body appendWithKey:key imageValue:(UIImage *)value];
        } else if ([value isKindOfClass:[NSData class]]) {
            [body appendWithKey:key dataValue:(NSData *)value];
        }
    }
}

- (void)completeWithResponse:(NSURLResponse *)response
                        data:(NSData *)data
                     orError:(NSError *)error
{
    NSAssert(self.state == kStateStarted,
             @"Unexpected state %d in completeWithResponse",
             self.state);
    self.state = kStateCompleted;

    if (response) {
        NSAssert([response isKindOfClass:[NSHTTPURLResponse class]],
                 @"Expected NSHTTPURLResponse, got %@",
                 response);
        self.urlResponse = (NSHTTPURLResponse *)response;
    } else {
        NSAssert(error, @"Expected response or error");
    }

    int statusCode = self.urlResponse.statusCode;
    error = [self checkConnectionError:error statusCode:statusCode parsedJSONResponse:nil];

    NSArray *results = nil;
    if (!error) {
        results = [self parseJSONResponse:data error:&error];
    }
    
    if (!error) {
        if ([self.requests count] != [results count]) {
            NSLog(@"Expected %d results, got %d", [self.requests count], [results count]);
            error = [self errorWithCode:FBErrorProtocolMismatch
                             statusCode:statusCode
                          parsedJSONResponse:results];
        }
    }

    if (self.deprecatedRequest) {
        [self completeDeprecatedWithData:data results:results orError:error];
    } else {
        [self completeWithResults:results orError:error];
    }

    self.connection = nil;
    self.urlResponse = (NSHTTPURLResponse *)response;
}

- (NSArray *)parseJSONResponse:(NSData *)data
                         error:(NSError **)error
{
    SBJSON *parser = [[SBJSON alloc] init];
    
    // Graph API can return "true" or "false", which is not valid JSON.
    // Translate that before asking JSON parser to look at it.
    NSString *responseUTF8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *parseUTF8;
    
    if ([responseUTF8 isEqualToString:@"false"]) {
        *error = [self errorWithCode:FBErrorRequestConnectionApi
                          statusCode:200
                  parsedJSONResponse:NO];
    } else if ([responseUTF8 isEqualToString:@"true"]) {
        parseUTF8 = @"{}";
    } else {
        parseUTF8 = responseUTF8;
    }

    id parsed = nil;
    if (!(*error)) {
        parsed = [parser objectWithString:parseUTF8 error:error];
    }

    [responseUTF8 release];
    [parser release];

    NSArray *results;
    if (*error) {
        results = nil;
    } else if ([self.requests count] == 1) {
        NSMutableArray *mutable = [[[NSMutableArray alloc] init] autorelease];
        [mutable addObject:parsed];
        results = mutable;
    } else if ([parsed isKindOfClass:[NSArray class]]) {
        results = (NSArray *)parsed;
    } else {
        results = nil;
    }

    return results;
}

- (void)completeDeprecatedWithData:(NSData *)data
                           results:(NSArray *)results
                           orError:(NSError *)error
{
    id result = [results objectAtIndex:0];
    id<FBRequestDelegate> delegate = [self.deprecatedRequest delegate];

    if (!error) {
        if ([delegate respondsToSelector:@selector(request:didReceiveResponse:)]) {
            [delegate request:self.deprecatedRequest
                     didReceiveResponse:self.urlResponse];
        }
        if ([delegate respondsToSelector:@selector(request:didLoadRawResponse:)]) {
            [delegate request:self.deprecatedRequest didLoadRawResponse:data];
        }

        error = [self errorFromResult:result];
    }

    if (!error) {
        if ([delegate respondsToSelector:@selector(request:didLoad:)]) {
            [delegate request:self.deprecatedRequest didLoad:result];
        }
    } else {
        if ([self isInvalidSessionError:error]) {
            [self.deprecatedRequest setSessionDidExpire:YES];
            [self.deprecatedRequest.session invalidate];
        }

        [self.deprecatedRequest setError:error];
        if ([delegate respondsToSelector:@selector(request:didFailWithError:)]) {
            [delegate request:self.deprecatedRequest didFailWithError:error];
        }
    }
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    [self.deprecatedRequest setState:kFBRequestStateComplete];
#pragma GCC diagnostic pop
}

- (void)completeWithResults:(NSArray *)results
                    orError:(NSError *)error
{
    int count = [self.requests count];
    for (int i = 0; i < count; i++) {
        FBRequestMetadata *metadata = [self.requests objectAtIndex:i];
        id result = error ? nil : [results objectAtIndex:i];
        NSError *itemError = error ? error : [self errorFromResult:result];

        if ([self isInvalidSessionError:itemError]) {
            [metadata.request.session invalidate];
        }

        metadata.completionHandler(self, result, itemError);
    }
}

- (NSError *)errorFromResult:(id)idResult
{
    if ([idResult isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)idResult;
        
        if ([dictionary valueForKey:@"error"] ||
            [dictionary valueForKey:@"error_code"] ||
            [dictionary valueForKey:@"error_msg"] ||
            [dictionary valueForKey:@"error_reason"]) {

            // TODO: align errors between batch items and single item
            NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] init] autorelease];
            [userInfo addEntriesFromDictionary:dictionary];
            return [self errorWithCode:FBErrorRequestConnectionApi
                            statusCode:200
                    parsedJSONResponse:idResult];

            //return [self checkConnectionError:nil statusCode:200 parsedJSONResponse:idResult];
        }
    }

    return nil;
}

- (NSError *)errorWithCode:(FBErrorCode)code
                statusCode:(int)statusCode
        parsedJSONResponse:(id)response
{
    NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] init] autorelease];
    [userInfo setValue:[NSNumber numberWithInt:statusCode] forKey:FBErrorHTTPStatusCodeKey];
    if (response) {
        [userInfo setValue:response forKey:FBErrorParsedJSONResponseKey];
    }
    return [self errorWithCode:code userInfo:userInfo];
}

- (NSError *)checkConnectionError:(NSError *)innerError
                       statusCode:(int)statusCode
               parsedJSONResponse:response
{
    if (innerError || ((statusCode < 200) || (statusCode >= 300))) {
        NSLog(@"Error: HTTP status code: %d", statusCode);

        NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] init] autorelease];
        if (innerError) {
            [userInfo setValue:innerError forKey:FBErrorInnerErrorKey];
        }
        if (response) {
            [userInfo setValue:response forKey:FBErrorParsedJSONResponseKey];
        }
        [userInfo setValue:[NSNumber numberWithInt:statusCode] forKey:FBErrorHTTPStatusCodeKey];

        return [self errorWithCode:FBErrorHTTPError userInfo:userInfo];
    }
    return nil;
}

- (NSError *)errorWithCode:(FBErrorCode)code
                  userInfo:(NSDictionary *)userInfo
{
    NSError *error = [[[NSError alloc]
                          initWithDomain:FBiOSSDKDomain
                                    code:code
                                userInfo:userInfo]
                         autorelease];

    return error;
}

- (BOOL)isInvalidSessionError:(NSError *)error
{
    id idStatusCode = [error.userInfo valueForKey:FBErrorHTTPStatusCodeKey];
    return (idStatusCode && (((int)idStatusCode) == kRESTAPIAccessTokenErrorCode));
}

+ (NSString *)userAgent
{
    static NSString *agent = nil;

    if (!agent) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *version = [bundle objectForInfoDictionaryKey:kBundleVersionKey];
        agent = [[NSString stringWithFormat:@"%@-%@", kUserAgentBase, version] retain];
    }

    return agent;
}

@end
