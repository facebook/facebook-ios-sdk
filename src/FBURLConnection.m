/*
 * Copyright 2012 Facebook
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

#import "FBURLConnection.h"
#import "FBError.h"
#import "FBDataDiskCache.h"

static NSArray* _cdnHosts;

@interface FBURLConnection ()

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, copy) FBURLConnectionHandler handler;
@property (nonatomic, retain) NSURLResponse *response;

- (BOOL)isCDNURL:(NSURL *)url;

@end

@implementation FBURLConnection

@synthesize connection = _connection;
@synthesize data = _data;
@synthesize handler = _handler;
@synthesize response = _response;

#pragma mark - Lifecycle

+ (void)initialize
{
    if (_cdnHosts == nil) {
        _cdnHosts = [[NSArray arrayWithObjects:
            @"akamaihd.net", 
            @"fbcdn.net", 
            nil] retain];
    }
}

- (FBURLConnection *)initWithURL:(NSURL *)url
               completionHandler:(FBURLConnectionHandler)handler
{
    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL:url] autorelease];
    return [self initWithRequest:request completionHandler:handler];
}

- (FBURLConnection *)initWithRequest:(NSURLRequest *)request
                   completionHandler:(FBURLConnectionHandler)handler
{
    if (self = [super init]) {
        // Check if this url is cached
        NSURL* url = request.URL;
        NSData* cachedData = [[FBDataDiskCache sharedCache] dataForURL:url];
        if (cachedData) {
            // TODO: It seems wrong to call this within init.  There are cases
            // with UI where this is not ideal.  We should talk about this.
            handler(self, nil, nil, cachedData);  
        } else {    
            _connection = [[NSURLConnection alloc] 
                initWithRequest:request 
                delegate:self];
            _data = [[NSMutableData alloc] init];
            
            self.handler = handler;
        }
    }
    return self;
}

- (void)dealloc
{
    [_connection release];
    [_data release];
    [_handler release];
    [super dealloc];
}

- (void)cancel
{
    [self.connection cancel];
    if (self.handler == nil) {
        return;
    }

    NSError *error = [[NSError alloc] initWithDomain:FBiOSSDKDomain
                                                code:FBErrorOperationCancelled
                                            userInfo:nil];

    // We are retaining ourselves (and releasing explicitly) because unlike the
    // other cases where we call the handler, we are not being held by anyone
    // else.
    [self retain];
    FBURLConnectionHandler handler = [self.handler retain];
    self.handler = nil;
    @try {
        handler(self, error, nil, nil);
    } @finally {
        [handler release];
        [self release];
        [error release];
    }
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    self.response = response;
    [self.data setLength:0];
}

- (void)connection:(NSURLResponse *)connection
    didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // TODO: translate well-known errors
    @try {
        self.handler(self, error, nil, nil);
    } @finally {
        self.handler = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSURL* dataURL = self.response.URL;
    if ([self isCDNURL:dataURL]) {
        // Cache this data
        [[FBDataDiskCache sharedCache] setData:self.data forURL:dataURL];
    }

    @try {
        self.handler(self, nil, self.response, self.data);
    } @finally {
        self.handler = nil;
    }
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse
{
    if (redirectResponse) {
        NSURL* redirectURL = request.URL;
        
        // Check for cache and short-circuit
        NSData* cachedData = 
            [[FBDataDiskCache sharedCache] dataForURL:redirectURL];
        if (cachedData) {
            @try {
                // Fake a response
                NSURLResponse* cacheResponse = 
                    [[NSURLResponse alloc] initWithURL:redirectURL
                        MIMEType:@"application/octet-stream" 
                        expectedContentLength:cachedData.length 
                        textEncodingName:@"utf8"];
                self.handler(self, nil, cacheResponse, cachedData);
            } @finally {
                self.handler = nil;
            }

            [connection cancel];
            return nil;
        }
    }
    
    return request;
}

- (BOOL)isCDNURL:(NSURL *)url
{
    NSString* urlHost = url.host;
    for (NSString* host in _cdnHosts) {
        if ([urlHost hasSuffix:host]) {
            return YES;
        }
    }

    return NO;
}

@end
