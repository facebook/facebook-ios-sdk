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
#import "FBSession+Internal.h"
#import "FBRequestConnection.h"
#import "FBRequest.h"
#import "Facebook.h"
#import "FBGraphObject.h"
#import "FBLogger.h"
#import "FBUtility.h"

// URL construction constants
NSString *const kGraphURL = @"https://graph." FB_BASE_URL;
NSString *const kGraphBaseURL = @"https://graph." FB_BASE_URL @"/";
NSString *const kRestBaseURL = @"https://api." FB_BASE_URL @"/method/";
NSString *const kBatchKey = @"batch";
NSString *const kBatchMethodKey = @"method";
NSString *const kBatchRelativeURLKey = @"relative_url";
NSString *const kBatchAttachmentKey = @"attached_files";
NSString *const kBatchFileNamePrefix = @"file";

NSString *const kAccessTokenKey = @"access_token";
NSString *const kSDK = @"ios";
NSString *const kSDKVersion = @"3";
NSString *const kUserAgentBase = @"FBiOSSDK";
NSString *const kBundleVersionKey = @"CFBundleVersion";

NSString *const kExtendTokenRestMethod = @"auth.extendSSOAccessToken";
NSString *const kBatchRestMethodBaseURL = @"method/";

// response object property/key
NSString *const FBNonJSONResponseProperty = @"FBiOSSDK_NON_JSON_RESULT";

static const int kRESTAPIAccessTokenErrorCode = 190;
static const NSTimeInterval kDefaultTimeout = 180.0;
static const int kMaximumBatchSize = 50;

typedef void (^KeyValueActionHandler)(NSString *key, id value);

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
@property (nonatomic, retain) FBLogger *logger;
@property (nonatomic) unsigned long requestStartTime;

- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout;

- (NSString *)urlStringForSingleRequest:(FBRequest *)request forBatch:(BOOL)forBatch;

- (NSString *)commonAccessToken:(NSArray *)requests;

- (void)appendJSONRequests:(NSArray *)requests
                    toBody:(FBRequestBody *)body
             includeTokens:(BOOL)includeTokens
        andNameAttachments:(NSMutableDictionary *)attachments
                    logger:(FBLogger *)logger;

- (void)addRequest:(FBRequestMetadata *)metadata
           toBatch:(NSMutableArray *)batch
      includeToken:(BOOL)includeToken
       attachments:(NSDictionary *)attachments;

- (BOOL)isAttachment:(id)item;

- (void)appendAttachments:(NSDictionary *)attachments
                   toBody:(FBRequestBody *)body
              addFormData:(BOOL)addFormData
                   logger:(FBLogger *)logger;

+ (void)processGraphObject:(id<FBGraphObject>)object
                       withAction:(KeyValueActionHandler)action;

- (void)completeWithResponse:(NSURLResponse *)response
                        data:(NSData *)data
                     orError:(NSError *)error;

- (NSArray *)parseJSONResponse:(NSData *)data
                         error:(NSError **)error
                    statusCode:(int)statusCode;

- (id)parseJSONOrOtherwise:(NSString *)utf8
                     error:(NSError **)error;

- (void)completeDeprecatedWithData:(NSData *)data
                           results:(NSArray *)results
                           orError:(NSError *)error;

- (void)completeWithResults:(NSArray *)results
                    orError:(NSError *)error;

- (NSError *)errorFromResult:(id)idResult;

- (NSError *)errorWithCode:(FBErrorCode)code
                statusCode:(int)statusCode
        parsedJSONResponse:(id)response
                innerError:(NSError *)innerError;

- (NSError *)checkConnectionError:(NSError *)innerError
                       statusCode:(int)statusCode
               parsedJSONResponse:(id)response;

- (BOOL)isInvalidSessionError:(NSError *)error
                  resultIndex:(int)index;

- (void)registerTokenToOmitFromLog:(NSString *)token; 

- (void)addPiggybackRequests;

+ (NSString *)userAgent;

+ (void)addRequestToExtendTokenForSession:(FBSession*)session connection:(FBRequestConnection*)connection;

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
@synthesize logger = _logger;
@synthesize requestStartTime = _requestStartTime;

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
        _logger = [[FBLogger alloc] initWithLoggingBehavior:FB_LOG_BEHAVIOR_FB_REQUESTS];
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
    [_logger release];
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
    [metadata release];
}

- (void)start
{
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

    if (self.internalUrlRequest == nil) {
        // If we have all Graph API calls, see if we want to piggyback any internal calls onto
        // the request to reduce round-trips. (The piggybacked calls may themselves be non-Graph
        // API calls, but must be limited to API calls which are batchable. Not all are, which is
        // why we won't piggyback on top of a REST API call.) Don't try this if the caller gave us
        // an already-formed request object, since we don't know its structure.
        BOOL safeForPiggyback = YES;
        for (FBRequestMetadata *requestMetadata in self.requests) {
            if (requestMetadata.request.restMethod) {
                safeForPiggyback = NO;
                break;
            }
        }
        if (safeForPiggyback) {
            [self addPiggybackRequests];
        }
    }
    
    NSMutableURLRequest *request = self.urlRequest;

    NSAssert((self.state == kStateCreated) || (self.state == kStateSerialized),
             @"Cannot call start again after calling start or cancel.");
    self.state = kStateStarted;
    
    _requestStartTime = [FBUtility currentTimeInMilliseconds];

    FBURLConnectionHandler handler =
        ^(FBURLConnection *connection,
          NSError *error,
          NSURLResponse *response,
          NSData *responseData) {
        [self completeWithResponse:response 
                              data:responseData 
                           orError:error];
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
}

- (void)cancel {
    // Cancelling self.connection might trigger error handlers that cause us to
    // get freed. Make sure we stick around long enough to finish this method call.
    [[self retain] autorelease];
    
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
    FBLogger *bodyLogger = [[FBLogger alloc] initWithLoggingBehavior:_logger.loggingBehavior];  
    FBLogger *attachmentLogger = [[FBLogger alloc] initWithLoggingBehavior:_logger.loggingBehavior];
    
    NSMutableURLRequest *request;
    
    if ([requests count] == 1) {
        FBRequestMetadata *metadata = [requests objectAtIndex:0];
        NSURL *url = [NSURL URLWithString:[self urlStringForSingleRequest:metadata.request forBatch:NO]];
        request = [NSMutableURLRequest requestWithURL:url
                                          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                      timeoutInterval:timeout];

        NSString *httpMethod = metadata.request.HTTPMethod;
        [request setHTTPMethod:httpMethod]; 
        [self appendAttachments:metadata.request.parameters
                         toBody:body
                    addFormData:[httpMethod isEqualToString:@"POST"]
                         logger:attachmentLogger];
        
        // if we have a post object, also roll that into the body 
        if (metadata.request.graphObject) {
            [FBRequestConnection processGraphObject:metadata.request.graphObject
                                                withAction:^(NSString *key, id value) {
                [body appendWithKey:key formValue:value logger:bodyLogger];
            }];
        }
    } else {
        NSString *commonToken = [self commonAccessToken:requests];
        if (commonToken) {
            [body appendWithKey:kAccessTokenKey formValue:commonToken logger:bodyLogger];
            [self registerTokenToOmitFromLog:commonToken];
        }

        NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
        
        [self appendJSONRequests:requests
                          toBody:body
                   includeTokens:(!commonToken)
              andNameAttachments:attachments
                          logger:bodyLogger];
        
        [self appendAttachments:attachments 
                         toBody:body 
                    addFormData:NO
                         logger:attachmentLogger];
        
        [attachments release];
        
        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kGraphURL]
                                          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                      timeoutInterval:timeout];
        [request setHTTPMethod:@"POST"];
    }

    [request setHTTPBody:[body data]];
    NSUInteger bodyLength = [[body data] length] / 1024;
    [body release];

    [request setValue:[FBRequestConnection userAgent] forHTTPHeaderField:@"User-Agent"];
    [request setValue:[FBRequestBody mimeContentType] forHTTPHeaderField:@"Content-Type"];
    
    if (_logger.isActive) {
        [_logger appendFormat:@"Request <#%d>:\n", _logger.loggerSerialNumber];
        [_logger appendKey:@"URL" value:[[request URL] absoluteString]];
        [_logger appendKey:@"Method" value:[request HTTPMethod]];
        [_logger appendKey:@"UserAgent" value:[FBRequestConnection userAgent]];
        [_logger appendKey:@"MIME" value:[FBRequestBody mimeContentType]];
        [_logger appendKey:@"Body Size" value:[NSString stringWithFormat:@"%d kB", bodyLength / 1024]];
        [_logger appendKey:@"Body (w/o attachments)" value:bodyLogger.contents];
        [_logger appendKey:@"Attachments" value:attachmentLogger.contents];
        [_logger appendString:@"\n"];
        
        [_logger emitToNSLog];
    }
    
    // Safely release now that everything's serialized into the logger.
    [bodyLogger release];
    [attachmentLogger release];
    
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
- (NSString *)urlStringForSingleRequest:(FBRequest *)request forBatch:(BOOL)forBatch
{
    [request.parameters setValue:@"json" forKey:@"format"];
    [request.parameters setValue:kSDK forKey:@"sdk"];
    [request.parameters setValue:kSDKVersion forKey:@"sdk_version"];
    NSString *token = request.session.accessToken;
    if (token) {
        [request.parameters setValue:token forKey:kAccessTokenKey];
        [self registerTokenToOmitFromLog:token];
    }

    NSString *baseURL;
    if (request.restMethod) {
        if (forBatch) {
            baseURL = [kBatchRestMethodBaseURL stringByAppendingString:request.restMethod];
        } else {
            baseURL = [kRestBaseURL stringByAppendingString:request.restMethod];
        }
    } else {
        if (forBatch) {
            baseURL = request.graphPath;
        } else {
            baseURL = [kGraphBaseURL stringByAppendingString:request.graphPath];
        }
    }

    // TODO: move serializeURL to a utility class next to isAttachment and
    // appendAttachments.  The types it ignores need to be in sync with
    // the attachment code.
    NSString *url = [FBRequest serializeURL:baseURL
                                     params:request.parameters
                                 httpMethod:request.HTTPMethod];
    return url;
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
                if (![firstToken isEqualToString:metadata.request.session.accessToken] &&
                    ![firstToken isEqual:[metadata.request.parameters objectForKey:@"access_token"]]) {
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
                    logger:(FBLogger *)logger
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

    [body appendWithKey:kBatchKey formValue:jsonBatch logger:logger];
}

//
// Adds request data to a batch in a format expected by the JsonWriter.
// Binary attachments are referenced by name in JSON and added to the
// attachments dictionary.  If includeToken is set, this will attach the
// corresponding token to each JSON request.
//
- (void)addRequest:(FBRequestMetadata *)metadata
           toBatch:(NSMutableArray *)batch
      includeToken:(BOOL)includeToken
       attachments:(NSDictionary *)attachments
{
    NSMutableDictionary *requestElement = [[[NSMutableDictionary alloc] init] autorelease];

    // TODO: error if things are not set
    [requestElement setObject:[self urlStringForSingleRequest:metadata.request forBatch:YES]
                       forKey:kBatchRelativeURLKey];
    [requestElement setObject:metadata.request.HTTPMethod forKey:kBatchMethodKey];

    if (metadata.batchEntryName) {
        [requestElement setObject:metadata.batchEntryName forKey:@"name"];
    }

    if (includeToken) {
        NSString *token = metadata.request.session.accessToken;
        if (token) {
            [metadata.request.parameters setObject:token forKey:kAccessTokenKey];
            [self registerTokenToOmitFromLog:token];
        }
    }

    NSMutableString *attachmentNames = [NSMutableString string];

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
        }
    }
    
    // if we have a post object, also roll that into the body 
    if (metadata.request.graphObject) {
        NSMutableString *bodyValue = [[[NSMutableString alloc] init] autorelease];
        __block NSString *delimeter = @"";
        [FBRequestConnection
         processGraphObject:metadata.request.graphObject
         withAction:^(NSString *key, id value) {
             // escape the value
             value = [FBUtility stringByURLEncodingString:[value description]];
             [bodyValue appendFormat:@"%@%@=%@",
              delimeter,
              key,
              value];
             delimeter = @"&";
         }];
        [requestElement setObject:bodyValue forKey:@"body"];
    }

    if ([attachmentNames length]) {
        [requestElement setObject:attachmentNames forKey:kBatchAttachmentKey];
    }

    [batch addObject:requestElement];
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
                   logger:(FBLogger *)logger
{   
    // key is name for both, first case is string which we can print, second pass grabs object
    if (addFormData) {
        for (NSString *key in [attachments keyEnumerator]) {
            NSObject *value = [attachments objectForKey:key];
            if ([value isKindOfClass:[NSString class]]) {
                [body appendWithKey:key formValue:(NSString *)value logger:logger];
            }
        }
    }

    for (NSString *key in [attachments keyEnumerator]) {
        NSObject *value = [attachments objectForKey:key];
        if ([value isKindOfClass:[UIImage class]]) {
            [body appendWithKey:key imageValue:(UIImage *)value logger:logger];
        } else if ([value isKindOfClass:[NSData class]]) {
            [body appendWithKey:key dataValue:(NSData *)value logger:logger];
        }
    }
}

+ (void)processGraphObjectPropertyKey:(NSString*)key value:(id)value action:(KeyValueActionHandler)action {
    // if we are handling a referenced object
    if ([value conformsToProtocol:@protocol(FBGraphObject)]) {
        // for referenced objects we may send a URL or an FBID
        id<FBGraphObject> refObject = (id<FBGraphObject>)value; 
        NSString *subValue;
        if ((subValue = [refObject objectForKey:@"id"])) {          // fbid
            if ([subValue isKindOfClass:[NSDecimalNumber class]]) {
                subValue = [(NSDecimalNumber*)subValue stringValue];
            }
            action(key, subValue);
            //[body appendWithKey:key formValue:subValue];
        } else if ((subValue = [refObject objectForKey:@"url"])) {  // canonical url (external)
            //[body appendWithKey:key formValue:subValue];
            action(key, subValue);
        }
        // if we are handling a string
    } else if ([value isKindOfClass:[NSString class]]) {
        //[body appendWithKey:key formValue:(NSString *)value];
        action(key, value);
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray*)value;
        int count = array.count;
        for (int i = 0; i < count; ++i) {
            NSString *subKey = [NSString stringWithFormat:@"%@[%d]", key, i];
            id subValue = [array objectAtIndex:i];
            [self processGraphObjectPropertyKey:subKey value:subValue action:action];
        }
    }
}

+ (void)processGraphObject:(id<FBGraphObject>)object withAction:(KeyValueActionHandler)action {
    for (NSString *key in [object keyEnumerator]) {
        NSObject *value = [object objectForKey:key];
        [self processGraphObjectPropertyKey:key value:value action:action];
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
    
    NSArray *results = nil;
    if (!error) {
        results = [self parseJSONResponse:data
                                    error:&error
                               statusCode:statusCode];
    }
        
    error = [self checkConnectionError:error 
                            statusCode:statusCode 
                    parsedJSONResponse:results];
    
    if (!error) {
        if ([self.requests count] != [results count]) {
            NSLog(@"Expected %d results, got %d", [self.requests count], [results count]);
            error = [self errorWithCode:FBErrorProtocolMismatch
                             statusCode:statusCode
                     parsedJSONResponse:results
                             innerError:nil];
        }
    }
    
    if (!error) {
        
        [_logger appendFormat:@"Response <#%d>\nDuration: %lu msec\nSize: %d kB\nResponse Body:\n%@\n\n",
         [_logger loggerSerialNumber],
         [FBUtility currentTimeInMilliseconds] - _requestStartTime,
         [data length],
         results];
        
    } else {
        
        [_logger appendFormat:@"Response <#%d> <Error>:\n%@\n\n",
         [_logger loggerSerialNumber],
         [error localizedDescription]];
        
    }
    [_logger emitToNSLog];
    
    if (self.deprecatedRequest) {
        [self completeDeprecatedWithData:data results:results orError:error];
    } else {
        [self completeWithResults:results orError:error];
    }

    self.connection = nil;
    self.urlResponse = (NSHTTPURLResponse *)response;
}

//
// If there is one request, the JSON is the response.
// If there are multiple requests, the JSON has an array of dictionaries whose
// body property is the response.
//   [{ "code":200,
//      "body":"JSON-response-as-a-string" },
//    { "code":200,
//      "body":"JSON-response-as-a-string" }]
//
// In both cases, this function returns an NSArray containing the results.
// The NSArray looks just like the multiple request case except the body
// value is converted from a string to parsed JSON.
//
- (NSArray *)parseJSONResponse:(NSData *)data
                         error:(NSError **)error
                    statusCode:(int)statusCode;
{
    // Graph API can return "true" or "false", which is not valid JSON.
    // Translate that before asking JSON parser to look at it.
    NSString *responseUTF8 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *results = nil;
    id response = [self parseJSONOrOtherwise:responseUTF8 error:error];

    if (*error) {
        // no-op
    } else if ([self.requests count] == 1) {
        // response is the entry, so put it in a dictionary under "body" and add
        // that to array of responses.
        NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
        [result setObject:[NSNumber numberWithInt:statusCode] forKey:@"code"];
        [result setObject:response forKey:@"body"];

        NSMutableArray *mutableResults = [[[NSMutableArray alloc] init] autorelease];
        [mutableResults addObject:result];
        results = mutableResults;
    } else if ([response isKindOfClass:[NSArray class]]) {
        // response is the array of responses, but the body element of each needs
        // to be decoded from JSON.
        NSMutableArray *mutableResults = [[[NSMutableArray alloc] init] autorelease];
        for (id item in response) {
            // Don't let errors parsing one response stop us from parsing another.
            NSError *batchResultError = nil;
            if (![item isKindOfClass:[NSDictionary class]]) {
                [mutableResults addObject:item];
            } else {
                NSDictionary *itemDictionary = (NSDictionary *)item;
                NSMutableDictionary *result = [[[NSMutableDictionary alloc] init] autorelease];
                for (NSString *key in [itemDictionary keyEnumerator]) {
                    id value = [itemDictionary objectForKey:key];
                    if ([key isEqualToString:@"body"]) {
                        id body = [self parseJSONOrOtherwise:value error:&batchResultError];
                        [result setObject:body forKey:key];
                    } else {
                        [result setObject:value forKey:key];
                    }
                }
                [mutableResults addObject:result];
            }
            if (batchResultError) {
                // We'll report back the last error we saw.
                *error = batchResultError;
            }
        }
        results = mutableResults;
    } else {
        *error = [self errorWithCode:FBErrorProtocolMismatch
                          statusCode:statusCode
                  parsedJSONResponse:results
                          innerError:nil];
    }

    [responseUTF8 release];
    return results;
}

- (id)parseJSONOrOtherwise:(NSString *)utf8
                     error:(NSError **)error
{
    id parsed = nil;
    if (!(*error)) {
        SBJSON *parser = [[SBJSON alloc] init];
        parsed = [parser objectWithString:utf8 error:error];
        // if we fail parse we attemp a reparse of a modified input to support results in the form "foo=bar", "true", etc.
        if (*error) {
            // we round-trip our hand-wired response through the parser in order to remain
            // consistent with the rest of the output of this function (note, if perf turns out
            // to be a problem -- unlikely -- we can return the following dictionary outright)
            NSDictionary *original = [NSDictionary dictionaryWithObjectsAndKeys:
                                      utf8, FBNonJSONResponseProperty,
                                      nil];
            NSString *jsonrep = [parser stringWithObject:original];
            NSError *reparseError;
            parsed = [parser objectWithString:jsonrep error:&reparseError];
            if (!reparseError) {
                *error = nil;
            }
        }
        [parser release];
    }
    return parsed;
}

- (void)completeDeprecatedWithData:(NSData *)data
                           results:(NSArray *)results
                           orError:(NSError *)error
{
    id result = [results objectAtIndex:0];
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *resultDictionary = (NSDictionary *)result;
        result = [resultDictionary objectForKey:@"body"];
    }

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
        if ([self isInvalidSessionError:error resultIndex:0]) {
            [self.deprecatedRequest setSessionDidExpire:YES];
            [self.deprecatedRequest.session close];
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

        id body = nil;
        if (!itemError && [result isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resultDictionary = (NSDictionary *)result;
            body = [FBGraphObject graphObjectWrappingDictionary:[resultDictionary objectForKey:@"body"]];
        }

        if ([self isInvalidSessionError:itemError 
                            resultIndex:error == itemError ? i : 0]) {
            [metadata.request.session close];
        } else if ([metadata.request.session shouldExtendAccessToken]) {
            // If we have not had the opportunity to piggyback a token-extension request,
            // but we need to, do so now as a separate request.
            FBRequestConnection *connection = [[FBRequestConnection alloc] init];
            [FBRequestConnection addRequestToExtendTokenForSession:metadata.request.session 
                                                        connection:connection];
            [connection start];
            [connection release];
        }

        if (metadata.completionHandler) {
            metadata.completionHandler(self, body, itemError);
        }
    }
}

- (NSError *)errorFromResult:(id)idResult
{
    if ([idResult isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)idResult;

        if ([dictionary objectForKey:@"error"] ||
            [dictionary objectForKey:@"error_code"] ||
            [dictionary objectForKey:@"error_msg"] ||
            [dictionary objectForKey:@"error_reason"]) {

            // TODO: align errors between batch items and single item
            NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] init] autorelease];
            [userInfo addEntriesFromDictionary:dictionary];
            return [self errorWithCode:FBErrorRequestConnectionApi
                            statusCode:200
                    parsedJSONResponse:idResult
                            innerError:nil];
        }

        NSNumber *code = [dictionary valueForKey:@"code"];
        if (code) {
            return [self checkConnectionError:nil
                                   statusCode:[code intValue]
                           parsedJSONResponse:idResult];
        }
    }

    return nil;
}

- (NSError *)errorWithCode:(FBErrorCode)code
                statusCode:(int)statusCode
        parsedJSONResponse:(id)response
                innerError:(NSError*)innerError {
    NSMutableDictionary *userInfo = [[[NSMutableDictionary alloc] init] autorelease];
    [userInfo setObject:[NSNumber numberWithInt:statusCode] forKey:FBErrorHTTPStatusCodeKey];
    
    if (response) {
        [userInfo setObject:response forKey:FBErrorParsedJSONResponseKey];
    }
    
    if (innerError) {
        [userInfo setObject:innerError forKey:FBErrorInnerErrorKey];
    }
    
    NSError *error = [[[NSError alloc]
                       initWithDomain:FBiOSSDKDomain
                       code:code
                       userInfo:userInfo]
                      autorelease];
    
    return error;
}

- (NSError *)checkConnectionError:(NSError *)innerError
                       statusCode:(int)statusCode
               parsedJSONResponse:response
{
    // We don't want to re-wrap our own errors.
    if (innerError &&
        [innerError.domain isEqualToString:FBiOSSDKDomain]) {
        return innerError;
    }
    NSError *result = nil;
    if (innerError || ((statusCode < 200) || (statusCode >= 300))) {
        NSLog(@"Error: HTTP status code: %d", statusCode);
        result = [self errorWithCode:FBErrorHTTPError
                          statusCode:statusCode
                  parsedJSONResponse:response
                          innerError:innerError];
    }
    return result;
}

- (BOOL)isInvalidSessionError:(NSError *)error
                  resultIndex:(int)index {
    
    // does this error have a response? that is an array?
    id response = [error.userInfo objectForKey:FBErrorParsedJSONResponseKey];
    if (response && [response isKindOfClass:[NSArray class]]) {
        
        // spelunking a JSON array & nested objects (eg. response[index].body.error.code)
        id  item, body, error, code;
        if ((item = [response objectAtIndex:index]) &&      // response[index]
            [item isKindOfClass:[NSDictionary class]] &&
            (body = [item objectForKey:@"body"]) &&         // response[index].body
            [body isKindOfClass:[NSDictionary class]] &&
            (error = [body objectForKey:@"error"]) &&       // response[index].body.error
            [error isKindOfClass:[NSDictionary class]] &&
            (code = [error objectForKey:@"code"]) &&        // response[index].body.error.code
            [code isKindOfClass:[NSNumber class]]) {
            // is it a 190 packaged in the original response, then YES
            return [code intValue] == kRESTAPIAccessTokenErrorCode;
        }
    }
    // else NO
    return NO;
}

- (void)registerTokenToOmitFromLog:(NSString *)token 
{
    if (![[FBSession loggingBehavior] containsObject:FB_LOG_BEHAVIOR_INCLUDE_ACCESS_TOKENS]) {
        [FBLogger registerStringToReplace:token replaceWith:@"ACCESS_TOKEN_REMOVED"];
    }
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

- (void)addPiggybackRequests
{
    // Get the set of sessions used by our requests
    NSMutableSet *sessions = [[NSMutableSet alloc] init];
    for (FBRequestMetadata *requestMetadata in self.requests) {
        // Have we seen this session yet? If not, assume we'll extend its token if it wants us to.
        if (requestMetadata.request.session) {
            [sessions addObject:requestMetadata.request.session];
        }
    }
    
    for (FBSession *session in sessions) {
        if (self.requests.count >= kMaximumBatchSize) {
            break;
        }
        if ([session shouldExtendAccessToken]) {
            [FBRequestConnection addRequestToExtendTokenForSession:session connection:self];
        }
    }
    
    [sessions release];
}

+ (void)addRequestToExtendTokenForSession:(FBSession*)session connection:(FBRequestConnection*)connection
{
    FBRequest *request = [[FBRequest alloc] initWithSession:session
                                                 restMethod:kExtendTokenRestMethod
                                                 parameters:nil
                                                 HTTPMethod:nil];
    [connection addRequest:request
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             // extract what we care about
             id token = [result objectForKey:@"access_token"];
             id expireTime = [result objectForKey:@"expires_at"];
             
             // if we have a token and it is not a string (?) punt
             if (token && ![token isKindOfClass:[NSString class]]) {
                 expireTime = nil;
             }
             
             // get a date if possible
             NSDate *expirationDate = nil;
             if (expireTime) {
                 NSTimeInterval timeInterval = [expireTime doubleValue];
                 if (timeInterval != 0) {
                     expirationDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                 }
             }
             
             // if we ended up with at least a date (and maybe a token) refresh the session token
             if (expirationDate) {
                 [session refreshAccessToken:token
                              expirationDate:expirationDate];
             }
         }];            
    [request release];
}

#pragma mark Debugging helpers

- (NSString*)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, %d request(s): (\n",
                               NSStringFromClass([self class]), 
                               self,
                               self.requests.count];
    BOOL comma = NO;
    for (FBRequestMetadata *metadata in self.requests) {
        FBRequest *request = metadata.request;
        if (comma) {
            [result appendString:@",\n"];
        }
        [result appendString:[request description]];
        comma = YES;
    }
    [result appendString:@"\n)>"];
    return result;
    
}

#pragma mark -

@end
