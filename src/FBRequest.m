/*
 * Copyright 2010 Facebook
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

#import "Facebook.h"
#import "JSON.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kUserAgent = @"FacebookConnect";
static NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
static const int kGeneralErrorCode = 10000;
static const int kRESTAPIAccessTokenErrorCode = 190;

static const NSTimeInterval kTimeoutInterval = 180.0;

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface FBRequest ()
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic,readwrite) FBRequestState state;
#pragma GCC diagnostic pop
@property (nonatomic,readwrite) BOOL sessionDidExpire;
@end

@implementation FBRequest

//////////////////////////////////////////////////////////////////////////////////////////////////
// class public

+ (FBRequest *)getRequestWithParams:(NSMutableDictionary *) params
                         httpMethod:(NSString *) httpMethod
                           delegate:(id<FBRequestDelegate>) delegate
                         requestURL:(NSString *) url {
    
    FBRequest* request = [[[FBRequest alloc] init] autorelease];
    request.delegate = delegate;
    request.url = url;
    request.httpMethod = httpMethod;
    request.params = params;
    request.connection = nil;
    request.responseText = nil;
    
    return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public property impls (deprecated)

//@property(nonatomic,assign) id<FBRequestDelegate> delegate;
- (id<FBRequestDelegate>)delegate {
    return _delegate;
}

- (void)setDelegate:(id<FBRequestDelegate>)newValue {
    _delegate = newValue;
}

//@property(nonatomic,copy) NSString* url;
- (NSString*)url {
    return _url;
}

- (void)setUrl:(NSString*)newValue {
    if (_url != newValue) {
        [_url release];
        _url = [newValue copy];
    }
}

//@property(nonatomic,copy) NSString* httpMethod;
- (NSString*)httpMethod {
    return _httpMethod;
}

- (void)setHttpMethod:(NSString*)newValue {
    if (_httpMethod != newValue) {
        [_httpMethod release];
        _httpMethod = [newValue copy];
    }
}

//@property(nonatomic,retain) NSMutableDictionary* params;
- (NSMutableDictionary*)params {
    return _params;
}

- (void)setParams:(NSMutableDictionary*)newValue {
    if (_params != newValue) {
        [_params release];
        _params = [newValue retain];
    }
}

//@property(nonatomic,retain) NSURLConnection*  connection;
- (NSURLConnection*)connection {
    return _connection;
}

- (void)setConnection:(NSURLConnection*)newValue {
    if (_connection != newValue) {
        [_connection release];
        _connection = [newValue retain];
    }
}

//@property(nonatomic,retain) NSMutableData* responseText;
- (NSMutableData*)responseText {
    return _responseText;
}

- (void)setResponseText:(NSMutableData*)newValue {
    if (_responseText != newValue) {
        [_responseText release];
        _responseText = [newValue retain];
    }
}

//@property(nonatomic,retain) NSError* error;
- (NSError*)error {
    return _error;
}

- (void)setError:(NSError*)newValue {
    if (_error != newValue) {
        [_error release];
        _error = [newValue retain];
    }
}

//@property(nonatomic,readonly+readwrite) FBRequestState state;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (FBRequestState)state {
    return _state;
}

- (void)setState:(FBRequestState)newValue {
    _state = newValue;
}
#pragma GCC diagnostic pop

//@property(nonatomic,readonly+readwrite) BOOL sessionDidExpire;
- (BOOL)sessionDidExpire {
    return _sessionDidExpire;
}

- (void)setSessionDidExpire:(BOOL)newValue {
    _sessionDidExpire = newValue;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

+ (NSString *)serializeURL:(NSString *)baseUrl
                    params:(NSDictionary *)params {
    return [self serializeURL:baseUrl params:params httpMethod:@"GET"];
}

/**
 * Generate get URL
 */
+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
               httpMethod:(NSString *)httpMethod {
    
    NSURL* parsedURL = [NSURL URLWithString:baseUrl];
    NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        if (([[params objectForKey:key] isKindOfClass:[UIImage class]])
            ||([[params objectForKey:key] isKindOfClass:[NSData class]])) {
            if ([httpMethod isEqualToString:@"GET"]) {
                NSLog(@"can not use GET to upload a file");
            }
            continue;
        }
        
        NSString* escaped_value = (NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                      NULL, /* allocator */
                                                                                      (CFStringRef)[params objectForKey:key],
                                                                                      NULL, /* charactersToLeaveUnescaped */
                                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                      kCFStringEncodingUTF8);
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
        [escaped_value release];
    }
    NSString* query = [pairs componentsJoinedByString:@"&"];
    
    return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

/**
 * Body append for POST method
 */
- (void)utfAppendBody:(NSMutableData *)body data:(NSString *)data {
    [body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

/**
 * Generate body for POST method
 */
- (NSMutableData *)generatePostBody {
    NSMutableData *body = [NSMutableData data];
    NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    
    [self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]];
    
    for (id key in [_params keyEnumerator]) {
        
        if (([[_params objectForKey:key] isKindOfClass:[UIImage class]])
            ||([[_params objectForKey:key] isKindOfClass:[NSData class]])) {
            
            [dataDictionary setObject:[_params objectForKey:key] forKey:key];
            continue;
            
        }
        
        [self utfAppendBody:body
                       data:[NSString
                             stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
                             key]];
        [self utfAppendBody:body data:[_params objectForKey:key]];
        
        [self utfAppendBody:body data:endLine];
    }
    
    if ([dataDictionary count] > 0) {
        for (id key in dataDictionary) {
            NSObject *dataParam = [dataDictionary objectForKey:key];
            if ([dataParam isKindOfClass:[UIImage class]]) {
                NSData* imageData = UIImagePNGRepresentation((UIImage*)dataParam);
                [self utfAppendBody:body
                               data:[NSString stringWithFormat:
                                     @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
                [self utfAppendBody:body
                               data:[NSString stringWithString:@"Content-Type: image/png\r\n\r\n"]];
                [body appendData:imageData];
            } else {
                NSAssert([dataParam isKindOfClass:[NSData class]],
                         @"dataParam must be a UIImage or NSData");
                [self utfAppendBody:body
                               data:[NSString stringWithFormat:
                                     @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
                [self utfAppendBody:body
                               data:[NSString stringWithString:@"Content-Type: content/unknown\r\n\r\n"]];
                [body appendData:(NSData*)dataParam];
            }
            [self utfAppendBody:body data:endLine];
            
        }
    }
    
    return body;
}

/**
 * Formulate the NSError
 */
- (id)formError:(NSInteger)code userInfo:(NSDictionary *) errorData {
    return [NSError errorWithDomain:@"facebookErrDomain" code:code userInfo:errorData];
    
}

/**
 * parse the response data
 */
- (id)parseJsonResponse:(NSData *)data error:(NSError **)error {
    
    NSString* responseString = [[[NSString alloc] initWithData:data
                                                      encoding:NSUTF8StringEncoding]
                                autorelease];
    if ([responseString isEqualToString:@"true"]) {
        return [NSDictionary dictionaryWithObject:@"true" forKey:@"result"];
    } else if ([responseString isEqualToString:@"false"]) {
        if (error != nil) {
            *error = [self formError:kGeneralErrorCode
                            userInfo:[NSDictionary
                                      dictionaryWithObject:@"This operation can not be completed"
                                      forKey:@"error_msg"]];
        }
        return nil;
    }
    
    
    SBJSON *jsonParser = [[SBJSON alloc] init];
    id result = [jsonParser objectWithString:responseString];
    [jsonParser release];

    if (result == nil) {
        return responseString;
    }

    if ([result isKindOfClass:[NSDictionary class]]) {
        if ([result objectForKey:@"error"] != nil) {
            if (error != nil) {
                *error = [self formError:kGeneralErrorCode
                                userInfo:result];
            }
            return nil;
        }
        
        if ([result objectForKey:@"error_code"] != nil) {
            if (error != nil) {
                *error = [self formError:[[result objectForKey:@"error_code"] intValue] userInfo:result];
            }
            return nil;
        }
        
        if ([result objectForKey:@"error_msg"] != nil) {
            if (error != nil) {
                *error = [self formError:kGeneralErrorCode userInfo:result];
            }
        }
        
        if ([result objectForKey:@"error_reason"] != nil) {
            if (error != nil) {
                *error = [self formError:kGeneralErrorCode userInfo:result];
            }
        }
    }
    
    return result;
    
}

/*
 * private helper function: call the delegate function when the request
 *                          fails with error
 */
- (void)failWithError:(NSError *)error {
    if ([error code] == kRESTAPIAccessTokenErrorCode) {
        self.sessionDidExpire = YES;
    }
    if ([_delegate respondsToSelector:@selector(request:didFailWithError:)]) {
        [_delegate request:self didFailWithError:error];
    }
}

/*
 * private helper function: handle the response data
 */
- (void)handleResponseData:(NSData *)data {
    if ([_delegate respondsToSelector:
         @selector(request:didLoadRawResponse:)]) {
        [_delegate request:self didLoadRawResponse:data];
    }
    
    NSError* error = nil;
    id result = [self parseJsonResponse:data error:&error];
    self.error = error;  
    
    if ([_delegate respondsToSelector:@selector(request:didLoad:)] ||
        [_delegate respondsToSelector:
         @selector(request:didFailWithError:)]) {
            
            if (error) {
                [self failWithError:error];
            } else if ([_delegate respondsToSelector:
                        @selector(request:didLoad:)]) {
                [_delegate request:self didLoad:result];
            }
            
        }
    
}



//////////////////////////////////////////////////////////////////////////////////////////////////
// public

/**
 * @return boolean - whether this request is processing
 */
- (BOOL)loading {
    return !!_connection;
}

/**
 * make the Facebook request
 */
- (void)connect {
    
    if ([_delegate respondsToSelector:@selector(requestLoading:)]) {
        [_delegate requestLoading:self];
    }
    
    NSString* url = [[self class] serializeURL:_url params:_params httpMethod:_httpMethod];
    NSMutableURLRequest* request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:kTimeoutInterval];
    [request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];


    [request setHTTPMethod:self.httpMethod];
    if ([self.httpMethod isEqualToString: @"POST"]) {
        NSString* contentType = [NSString
                             stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];

        [request setHTTPBody:[self generatePostBody]];
    }

    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.state = kFBRequestStateLoading;
    self.sessionDidExpire = NO;
}

/**
 * Free internal structure
 */
- (void)dealloc {
    [_connection cancel];
    [_connection release];
    [_responseText release];
    [_url release];
    [_httpMethod release];
    [_params release];
    [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _responseText = [[NSMutableData alloc] init];
    
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    if ([_delegate respondsToSelector:
         @selector(request:didReceiveResponse:)]) {
        [_delegate request:self didReceiveResponse:httpResponse];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseText appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self handleResponseData:_responseText];

    self.responseText = nil;
    self.connection = nil;
    self.state = kFBRequestStateComplete;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self failWithError:error];

    self.responseText = nil;
    self.connection = nil;
    self.state = kFBRequestStateComplete;
}

@end
