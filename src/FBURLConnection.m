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
#import "FBSession.h"
#import "FBLogger.h"
#import "FBUtility.h"
#import "FBSettings.h"
#import "FBSettings+Internal.h"

static NSArray* _cdnHosts;

@interface FBURLConnection ()

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, copy) FBURLConnectionHandler handler;
@property (nonatomic, retain) NSURLResponse *response;
@property (nonatomic) unsigned long requestStartTime;
@property (nonatomic, readonly) NSUInteger loggerSerialNumber;
@property (nonatomic) BOOL skipRoundtripIfCached;

- (BOOL)isCDNURL:(NSURL *)url;

- (void)invokeHandler:(FBURLConnectionHandler)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData;

@end

@implementation FBURLConnection

@synthesize connection = _connection;
@synthesize data = _data;
@synthesize handler = _handler;
@synthesize loggerSerialNumber = _loggerSerialNumber;
@synthesize requestStartTime = _requestStartTime;
@synthesize response = _response;
@synthesize skipRoundtripIfCached = _skipRoundtripIfCached;

#pragma mark - Lifecycle

+ (void)initialize {
    if (_cdnHosts == nil) {
        _cdnHosts = [[NSArray arrayWithObjects:
            @"akamaihd.net", 
            @"fbcdn.net", 
            nil] retain];
    }
}

- (FBURLConnection *)initWithURL:(NSURL *)url
               completionHandler:(FBURLConnectionHandler)handler {
    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL:url] autorelease];
    return [self initWithRequest:request
           skipRoundTripIfCached:YES
               completionHandler:handler];
}

- (FBURLConnection *)initWithRequest:(NSURLRequest *)request
               skipRoundTripIfCached:(BOOL)skipRoundtripIfCached
                   completionHandler:(FBURLConnectionHandler)handler {
    if (self = [super init]) {
        self.skipRoundtripIfCached = skipRoundtripIfCached;
        
        // Check if this url is cached
        NSURL* url = request.URL;
        NSData* cachedData = skipRoundtripIfCached ? [[FBDataDiskCache sharedCache] dataForURL:url] : nil;
        
        if (cachedData) {
            [FBLogger singleShotLogEntry:FBLoggingBehaviorFBURLConnections
                            formatString:@"FBUrlConnection: <#%d>.  Cached response %d kB\n", 
             [url absoluteString],
             [cachedData length] / 1024];
            
            // TODO: It seems wrong to call this within init.  There are cases
            // with UI where this is not ideal.  We should talk about this.
            handler(self, nil, nil, cachedData);

        } else {    
        
            _requestStartTime = [FBUtility currentTimeInMilliseconds];
            _loggerSerialNumber = [FBLogger newSerialNumber];
            _connection = [[NSURLConnection alloc] 
                initWithRequest:request 
                delegate:self];
            _data = [[NSMutableData alloc] init];
                     
            [FBLogger singleShotLogEntry:FBLoggingBehaviorFBURLConnections
                            formatString:@"FBURLConnection <#%d>:\n  URL: '%@'\n\n",
                _loggerSerialNumber,
                [url absoluteString]];
            
            self.handler = handler;
        }

        // always attempt to autoPublish.  this function internally
        // handles only executing once.
        [FBSettings autoPublishInstall:nil];
    }
    return self;
}

- (void)invokeHandler:(FBURLConnectionHandler)handler 
                error:(NSError *)error 
             response:(NSURLResponse *)response 
         responseData:(NSData *)responseData {
    NSString *logEntry;
    
    if (error) {
        
        logEntry = [NSString 
                    stringWithFormat:@"FBURLConnection <#%d>:\n  Error: '%@'",
                    _loggerSerialNumber,
                    [error localizedDescription]];
        
    } else {            
        
        // Basic FBURLConnection logging just prints out the URL.  FBRequest logging provides more details.                        
        NSString *mimeType = [response MIMEType];
        NSMutableString *mutableLogEntry = [NSMutableString stringWithFormat:@"FBURLConnection <#%d>:\n  Duration: %lu msec\nResponse Size: %d kB\n  MIME type: %@\n", 
                                            _loggerSerialNumber,
                                            [FBUtility currentTimeInMilliseconds] - _requestStartTime,
                                            [responseData length] / 1024,
                                            mimeType];
        
        if ([mimeType isEqualToString:@"text/javascript"]) {
            NSString *responseUTF8 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            [mutableLogEntry appendFormat:@"  Response:\n%@\n\n", responseUTF8];
            [responseUTF8 release];
        }
        
        logEntry = mutableLogEntry;
    }
    
    [FBLogger singleShotLogEntry:FBLoggingBehaviorFBURLConnections
                        logEntry:logEntry]; 
    
    if (handler) {
        handler(self, error, response, responseData);
    }
}

- (void)dealloc {
    [_response release];
    [_connection release];
    [_data release];
    [_handler release];
    [super dealloc];
}

- (void)cancel {
    [self.connection cancel];
    if (self.handler == nil) {
        return;
    }

    NSError *error = [[NSError alloc] initWithDomain:FacebookSDKDomain
                                                code:FBErrorOperationCancelled
                                            userInfo:nil];

    // We are retaining ourselves (and releasing explicitly) because unlike the
    // other cases where we call the handler, we are not being held by anyone
    // else.
    [self retain];
    FBURLConnectionHandler handler = [self.handler retain];
    self.handler = nil;
    @try {
        [self invokeHandler:handler error:error response:nil responseData:nil];
    } @finally {
        [handler release];
        [self release];
        [error release];
    }
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
    self.response = response;
    [self.data setLength:0];
}

- (void)connection:(NSURLResponse *)connection
    didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
    @try {
        [self invokeHandler:self.handler error:error response:nil responseData:nil];
    } @finally {
        self.handler = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSURL* dataURL = self.response.URL;
    if ([self isCDNURL:dataURL]) {
        // Cache this data
        [[FBDataDiskCache sharedCache] setData:self.data forURL:dataURL];
    }

    @try {
        [self invokeHandler:self.handler error:nil response:self.response responseData:self.data];
    } @finally {
        self.handler = nil;
    }
}

-(NSURLRequest *)connection:(NSURLConnection *)connection
            willSendRequest:(NSURLRequest *)request
           redirectResponse:(NSURLResponse *)redirectResponse {
    if (redirectResponse && self.skipRoundtripIfCached) {
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
                [self invokeHandler:self.handler error:nil response:cacheResponse responseData:cachedData];
                [cacheResponse release];
            } @finally {
                self.handler = nil;
            }

            return nil;
        }
    }
    
    return request;
}

- (BOOL)isCDNURL:(NSURL *)url {
    NSString* urlHost = url.host;
    for (NSString* host in _cdnHosts) {
        if ([urlHost hasSuffix:host]) {
            return YES;
        }
    }

    return NO;
}

@end
