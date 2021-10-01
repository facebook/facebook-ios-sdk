// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

@protocol FBSDKURLSessionProxying;
@protocol FBSDKURLSessionProxyProviding;
@protocol FBSDKErrorConfigurationProviding;
@protocol FBSDKURLSessionProxying;
@protocol FBSDKURLSessionProxyProviding;
@protocol FBSDKGraphRequestPiggybackManagerProviding;
@protocol FBSDKSettings;
@protocol FBSDKGraphRequestConnectionFactory;
@protocol FBSDKEventLogging;
@protocol FBSDKAccessTokenProviding;
@protocol FBSDKAccessTokenSetting;
@protocol FBSDKOperatingSystemVersionComparing;
@protocol FBSDKMacCatalystDetermining;
@class FBSDKGraphRequestBody;
@class FBSDKGraphRequestMetadata;
@class FBSDKLogger;

#import <FBSDKCoreKit/FBSDKGraphRequestConnection.h>

#import "FBSDKGraphRequestMetadata.h"
NS_ASSUME_NONNULL_BEGIN

// ----------------------------------------------------------------------------
// FBSDKGraphRequestConnectionState

typedef NS_ENUM(NSUInteger, FBSDKGraphRequestConnectionState) {
  kStateCreated,
  kStateSerialized,
  kStateStarted,
  kStateCompleted,
  kStateCancelled,
};

@interface FBSDKGraphRequestConnection () <FBSDKGraphRequestConnecting>

@property (nonatomic, retain) NSMutableArray<FBSDKGraphRequestMetadata *> *requests;
@property (nonatomic, assign) FBSDKGraphRequestConnectionState state;
@property (nonatomic, strong) FBSDKLogger *logger;
@property (nonatomic, assign) uint64_t requestStartTime;
@property (nonatomic, strong) id<FBSDKURLSessionProxying> session;
@property (nonatomic, strong) id<FBSDKURLSessionProxyProviding> sessionProxyFactory;
@property (nonatomic, strong) id<FBSDKErrorConfigurationProviding> errorConfigurationProvider;
@property (nonatomic, strong) Class<FBSDKGraphRequestPiggybackManagerProviding> piggybackManagerProvider;
@property (nonatomic, strong) id<FBSDKSettings> settings;
@property (nonatomic, strong) id<FBSDKGraphRequestConnectionFactory> graphRequestConnectionFactory;
@property (nonatomic, strong) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, strong) id<FBSDKOperatingSystemVersionComparing> operatingSystemVersionComparer;
@property (nonatomic, strong) id<FBSDKMacCatalystDetermining> macCatalystDeterminator;
@property (nonatomic, strong) Class<FBSDKAccessTokenProviding> accessTokenProvider;
@property (nonatomic, strong) Class<FBSDKAccessTokenSetting> accessTokenSetter;

+ (BOOL)canMakeRequests;
+ (void)setCanMakeRequests;

- (instancetype)initWithURLSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)proxyFactory
                    errorConfigurationProvider:(id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
                      piggybackManagerProvider:(id<FBSDKGraphRequestPiggybackManagerProviding>)piggybackManagerProvider
                                      settings:(id<FBSDKSettings>)settings
                 graphRequestConnectionFactory:(id<FBSDKGraphRequestConnectionFactory>)factory
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger
                operatingSystemVersionComparer:(id<FBSDKOperatingSystemVersionComparing>)operatingSystemVersionComparer
                       macCatalystDeterminator:(id<FBSDKMacCatalystDetermining>)macCatalystDeterminator
                           accessTokenProvider:(Class<FBSDKAccessTokenProviding>)accessTokenProvider
                             accessTokenSetter:(Class<FBSDKAccessTokenSetting>)accessTokenSetter;

- (NSMutableURLRequest *)requestWithBatch:(NSArray<FBSDKGraphRequestMetadata *> *)requests
                                  timeout:(NSTimeInterval)timeout;

- (void)addRequest:(FBSDKGraphRequestMetadata *)metadata
           toBatch:(NSMutableArray<id> *)batch
       attachments:(NSMutableDictionary<NSString *, id> *)attachments
        batchToken:(nullable NSString *)batchToken;

- (void)appendAttachments:(NSDictionary<NSString *, id> *)attachments
                   toBody:(FBSDKGraphRequestBody *)body
              addFormData:(BOOL)addFormData
                   logger:(FBSDKLogger *)logger;

- (nullable NSString *)accessTokenWithRequest:(id<FBSDKGraphRequest>)request;

- (nullable NSError *)errorFromResult:(id)untypedParam request:(id<FBSDKGraphRequest>)request;

- (NSArray<id> *)parseJSONResponse:(NSData *)data
                             error:(NSError **)error
                        statusCode:(NSInteger)statusCode;

- (void)processResultBody:(nullable NSDictionary<NSString *, id> *)body
                    error:(nullable NSError *)error
                 metadata:(FBSDKGraphRequestMetadata *)metadata
        canNotifyDelegate:(BOOL)canNotifyDelegate;

- (void)logRequest:(NSMutableURLRequest *)request
        bodyLength:(NSUInteger)bodyLength
        bodyLogger:(nullable FBSDKLogger *)bodyLogger
  attachmentLogger:(nullable FBSDKLogger *)attachmentLogger;

- (void)        URLSession:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
           didSendBodyData:(int64_t)bytesSent
            totalBytesSent:(int64_t)totalBytesSent
  totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;

/**
 Get the graph request url for a single graph request
 @param request The Graph Request we need the url for
 @param forBatch whether the request is a batch request.
 */
- (NSString *)urlStringForSingleRequest:(id<FBSDKGraphRequest>)request forBatch:(BOOL)forBatch;

/**
 Add the specified body as the HTTPBody of the specified request.
 @param body The FBSDKGraphRequestBody to attach to the request.
 @param request The NSURLRequest to attach the body to.
 */
- (void)addBody:(FBSDKGraphRequestBody *)body toPostRequest:(NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
