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

#import "FBURLConnection.h"

#import "FBDataDiskCache.h"
#import "FBError.h"
#import "FBInternalSettings.h"
#import "FBLogger.h"
#import "FBSession.h"
#import "FBSettings+Internal.h"
#import "FBUtility.h"

static NSArray *_cdnHosts;

@interface FBURLConnection () <NSURLConnectionDataDelegate>

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
    if ((self = [super init])) {
        self.skipRoundtripIfCached = skipRoundtripIfCached;

        // Check if this url is cached
        NSURL *url = request.URL;
        FBDataDiskCache *cache = [self getCache];
        NSData *cachedData = skipRoundtripIfCached ? [cache dataForURL:url] : nil;

        if (cachedData) {
            // TODO: It seems wrong to call this within init.  There are cases
            // with UI where this is not ideal.  We should talk about this.
            [self logAndInvokeHandler:handler cachedData:cachedData forURL:url];
        } else {

            _requestStartTime = [FBUtility currentTimeInMilliseconds];
            _loggerSerialNumber = [FBLogger newSerialNumber];
            _connection = [[NSURLConnection alloc]
                           initWithRequest:request
                           delegate:self];
            _data = [[NSMutableData alloc] init];

            [self logMessage:[NSString stringWithFormat:@"FBURLConnection <#%lu>:\n  URL: '%@'\n\n",
                              (unsigned long)self.loggerSerialNumber,
                              url.absoluteString]];

            self.handler = handler;
        }

        // always attempt to autoPublish.  this function internally
        // handles only executing once.
        [FBSettings autoPublishInstall:nil];
    }
    return self;
}

- (void)logAndInvokeHandler:(FBURLConnectionHandler)handler
                      error:(NSError *)error {
    if (error) {
        NSString *logEntry = [NSString
                              stringWithFormat:@"FBURLConnection <#%lu>:\n  Error: '%@'\n%@\n",
                              (unsigned long)self.loggerSerialNumber,
                              [error localizedDescription],
                              [error userInfo]];

        [self logMessage:logEntry];
    }

    [self invokeHandler:handler error:error response:nil responseData:nil];
}

- (void)logAndInvokeHandler:(FBURLConnectionHandler)handler
                   response:(NSURLResponse *)response
               responseData:(NSData *)responseData {
    // Basic FBURLConnection logging just prints out the URL.  FBRequest logging provides more details.
    NSString *mimeType = [response MIMEType];
    NSMutableString *mutableLogEntry = [NSMutableString stringWithFormat:@"FBURLConnection <#%lu>:\n  Duration: %lu msec\nResponse Size: %lu kB\n  MIME type: %@\n",
                                        (unsigned long)self.loggerSerialNumber,
                                        [FBUtility currentTimeInMilliseconds] - self.requestStartTime,
                                        (unsigned long)[responseData length] / 1024,
                                        mimeType];

    if ([mimeType isEqualToString:@"text/javascript"]) {
        NSString *responseUTF8 = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        [mutableLogEntry appendFormat:@"  Response:\n%@\n\n", responseUTF8];
        [responseUTF8 release];
    }

    [self logMessage:mutableLogEntry];

    [self invokeHandler:handler error:nil response:response responseData:responseData];
}

- (void)logAndInvokeHandler:(FBURLConnectionHandler)handler
                 cachedData:(NSData *)cachedData
                     forURL:(NSURL *)url {
    [self logMessage:[NSString stringWithFormat:@"FBUrlConnection: <#%lu>.  Cached response %lu kB\n",
                      (unsigned long)self.loggerSerialNumber,
                      (unsigned long)cachedData.length / 1024]];

    [self invokeHandler:handler error:nil response:nil responseData:cachedData];
}

- (void)invokeHandler:(FBURLConnectionHandler)handler
                error:(NSError *)error
             response:(NSURLResponse *)response
         responseData:(NSData *)responseData {
    if (handler != nil) {
        handler(self, error, response, responseData);
    }
}

- (void)logMessage:(NSString *)message {
    [FBLogger singleShotLogEntry:FBLoggingBehaviorFBURLConnections formatString:@"%@", message];
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
        [self logAndInvokeHandler:handler error:error];
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
        [self logAndInvokeHandler:self.handler error:error];
    } @finally {
        self.handler = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSURL *dataURL = self.response.URL;
    if ([self isCDNURL:dataURL]) {
        // Cache this data
        FBDataDiskCache *cache = [self getCache];
        [cache setData:self.data forURL:dataURL];
    }

    @try {
        [self logAndInvokeHandler:self.handler response:self.response responseData:self.data];
    } @finally {
        self.handler = nil;
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection
             willSendRequest:(NSURLRequest *)request
            redirectResponse:(NSURLResponse *)redirectResponse {
    if ([self shouldShortCircuitRedirectResponse:redirectResponse]) {
        NSURL *redirectURL = request.URL;

        // Check for cache and short-circuit
        FBDataDiskCache *cache = [self getCache];
        NSData *cachedData = [cache dataForURL:redirectURL];
        if (cachedData) {
            @try {
                // Fake a response
                NSURLResponse *cacheResponse =
                [[NSURLResponse alloc] initWithURL:redirectURL
                                          MIMEType:@"application/octet-stream"
                             expectedContentLength:cachedData.length
                                  textEncodingName:@"utf8"];
                [self logAndInvokeHandler:self.handler response:cacheResponse responseData:cachedData];
                [cacheResponse release];
            } @finally {
                self.handler = nil;
            }

            return nil;
        }
    }

    return request;
}

- (void)       connection:(NSURLConnection *)connection
          didSendBodyData:(NSInteger)bytesWritten
        totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    id<FBURLConnectionDelegate> delegate = self.delegate;

    if ([delegate respondsToSelector:@selector(facebookURLConnection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [delegate facebookURLConnection:self
                        didSendBodyData:bytesWritten
                      totalBytesWritten:totalBytesWritten
              totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

- (BOOL)shouldShortCircuitRedirectResponse:(NSURLResponse *)redirectResponse {
    return redirectResponse && self.skipRoundtripIfCached;
}

- (BOOL)isCDNURL:(NSURL *)url {
    NSString *urlHost = url.host;
    for (NSString *host in _cdnHosts) {
        if ([urlHost hasSuffix:host]) {
            return YES;
        }
    }

    return NO;
}

- (FBDataDiskCache *)getCache {
    return [FBDataDiskCache sharedCache];
}

@end
