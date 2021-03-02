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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTestUtility.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKTestCase.h"
#import "FBSDKURLSessionProxyFactory.h"

typedef NS_ENUM(NSUInteger, FBSDKGraphRequestConnectionState) {
  kStateCreated,
  kStateSerialized,
  kStateStarted,
  kStateCompleted,
  kStateCancelled,
};

@interface FBSDKGraphRequestConnection (Testing)

@property (nonatomic, strong) id<FBSDKURLSessionProxying> session;
@property (nonatomic, strong) id<FBSDKURLSessionProxyProviding> sessionProxyFactory;
@property (nonatomic, strong) id<FBSDKErrorConfigurationProviding> errorConfigurationProvider;
@property (nonatomic, strong) id<FBSDKGraphRequestPiggybackManaging> piggybackManager;
@property (nonatomic, strong) Class<FBSDKGraphRequestPiggybackManagerProviding> piggybackManagerProvider;
@property (nonatomic, strong) Class<FBSDKSettings> settings;
@property (nonatomic, strong) id<FBSDKGraphRequestConnectionProviding> connectionFactory;
@property (nonatomic, strong) id<FBSDKEventLogging> eventLogger;
@property (nonatomic, assign) FBSDKGraphRequestConnectionState state;
@property (nonatomic, strong) FBSDKLogger *logger;

+ (BOOL)canMakeRequests;
+ (void)resetCanMakeRequests;
+ (void)resetDefaultConnectionTimeout;
- (instancetype)initWithURLSessionProxyFactory:(id<FBSDKURLSessionProxyProviding>)proxyFactory
                    errorConfigurationProvider:(id<FBSDKErrorConfigurationProviding>)errorConfigurationProvider
                      piggybackManagerProvider:(id<FBSDKGraphRequestPiggybackManagerProviding>)piggybackManagerProvider
                                      settings:(id<FBSDKSettings>)settings
                             connectionFactory:(id<FBSDKGraphRequestConnectionProviding>)factory
                                   eventLogger:(id<FBSDKEventLogging>)eventLogger;
- (NSMutableURLRequest *)requestWithBatch:(NSArray *)requests
                                  timeout:(NSTimeInterval)timeout;
- (void)addRequest:(FBSDKGraphRequestMetadata *)metadata
           toBatch:(NSMutableArray *)batch
       attachments:(NSMutableDictionary *)attachments
        batchToken:(NSString *)batchToken;
- (void)appendAttachments:(NSDictionary *)attachments
                   toBody:(FBSDKGraphRequestBody *)body
              addFormData:(BOOL)addFormData
                   logger:(FBSDKLogger *)logger;
- (NSString *)accessTokenWithRequest:(FBSDKGraphRequest *)request;
- (NSError *)errorFromResult:(id)untypedParam request:(FBSDKGraphRequest *)request;
- (NSString *)_overrideVersionPart;
- (NSArray *)parseJSONResponse:(NSData *)data
                         error:(NSError **)error
                    statusCode:(NSInteger)statusCode;
- (void)processResultBody:(NSDictionary *)body
                    error:(NSError *)error
                 metadata:(FBSDKGraphRequestMetadata *)metadata
        canNotifyDelegate:(BOOL)canNotifyDelegate;
- (void)logRequest:(NSMutableURLRequest *)request
        bodyLength:(NSUInteger)bodyLength
        bodyLogger:(FBSDKLogger *)bodyLogger
  attachmentLogger:(FBSDKLogger *)attachmentLogger;
- (void)        URLSession:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
           didSendBodyData:(int64_t)bytesSent
            totalBytesSent:(int64_t)totalBytesSent
  totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend;
@end

@interface FBSDKGraphRequestConnectionTests : XCTestCase <FBSDKGraphRequestConnectionDelegate>

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) TestURLSessionProxy *session;
@property (nonatomic, strong) TestURLSessionProxyFactory *sessionFactory;
@property (nonatomic, strong) TestErrorConfiguration *errorConfiguration;
@property (nonatomic, strong) TestErrorConfigurationProvider *errorConfigurationProvider;
@property (nonatomic, strong) FBSDKErrorRecoveryConfiguration *errorRecoveryConfiguration;
@property (nonatomic, strong) TestGraphRequestPiggybackManager *piggybackManager;
@property (nonatomic, strong) TestGraphRequestPiggybackManagerProvider *piggybackManagerProvider;
@property (nonatomic, strong) TestSettings *settings;
@property (nonatomic, strong) TestGraphRequestConnectionFactory *connectionFactory;
@property (nonatomic, strong) TestEventLogger *eventLogger;
@property (nonatomic, strong) FBSDKGraphRequestConnection *connection;

@property (nonatomic, copy) void (^requestConnectionStartingCallback)(FBSDKGraphRequestConnection *connection);
@property (nonatomic, copy) void (^requestConnectionCallback)(FBSDKGraphRequestConnection *connection, NSError *error);
@property (nonatomic) BOOL didInvokeDelegateRequestConnectionDidSendBodyData;
@end

@interface FBSDKAuthenticationToken (Testing)

- (instancetype)initWithTokenString:(NSString *)tokenString
                              nonce:(NSString *)nonce
                        graphDomain:(NSString *)graphDomain;

@end

@implementation FBSDKGraphRequestConnectionTests

- (void)setUp
{
  [super setUp];

  [FBSDKGraphRequestConnection setCanMakeRequests];

  self.appID = @"appid";
  self.session = [TestURLSessionProxy new];
  self.sessionFactory = [TestURLSessionProxyFactory createWith:self.session];
  self.errorRecoveryConfiguration = self.nonTransientErrorRecoveryConfiguration;
  self.errorConfiguration = [TestErrorConfiguration new];
  self.errorConfiguration.stubbedRecoveryConfiguration = self.errorRecoveryConfiguration;
  self.errorConfigurationProvider = [[TestErrorConfigurationProvider alloc] initWithConfiguration:self.errorConfiguration];
  self.piggybackManager = [TestGraphRequestPiggybackManager new];
  self.piggybackManagerProvider = TestGraphRequestPiggybackManagerProvider.self;
  TestSettings.appID = self.appID;
  self.settings = TestSettings.self;
  self.connectionFactory = [TestGraphRequestConnectionFactory new];
  self.eventLogger = [TestEventLogger new];
  self.connection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:self.sessionFactory
                                                             errorConfigurationProvider:self.errorConfigurationProvider
                                                               piggybackManagerProvider:self.piggybackManagerProvider
                                                                               settings:self.settings
                                                                      connectionFactory:self.connectionFactory
                                                                            eventLogger:self.eventLogger];
  self.connectionFactory.stubbedConnection = self.connection;
}

- (void)tearDown
{
  [FBSDKGraphRequestConnection resetDefaultConnectionTimeout];
  [FBSDKGraphRequestConnection resetCanMakeRequests];
  [TestGraphRequestPiggybackManager reset];
  [TestLogger reset];
  [TestSettings reset];

  [super tearDown];
}

// MARK: - FBSDKGraphRequestConnectionDelegate

- (void)requestConnection:(FBSDKGraphRequestConnection *)connection didFailWithError:(NSError *)error
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, error);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionDidFinishLoading:(FBSDKGraphRequestConnection *)connection
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, nil);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionWillBeginLoading:(FBSDKGraphRequestConnection *)connection
{
  if (self.requestConnectionStartingCallback) {
    self.requestConnectionStartingCallback(connection);
    self.requestConnectionStartingCallback = nil;
  }
}

- (void)  requestConnection:(FBSDKGraphRequestConnection *)connection
            didSendBodyData:(NSInteger)bytesWritten
          totalBytesWritten:(NSInteger)totalBytesWritten
  totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
  self.didInvokeDelegateRequestConnectionDidSendBodyData = YES;
}

// MARK: - Dependencies

- (void)testCreatingWithDefaultUrlSessionProxyFactory
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  NSObject *sessionProvider = (NSObject *)connection.sessionProxyFactory;
  XCTAssertEqualObjects(
    sessionProvider.class,
    FBSDKURLSessionProxyFactory.class,
    "A graph request connection should have the correct concrete session provider by default"
  );
}

- (void)testCreatingWithCustomUrlSessionProxyFactory
{
  NSObject *sessionProvider = (NSObject *)self.connection.sessionProxyFactory;

  XCTAssertEqualObjects(
    sessionProvider.class,
    TestURLSessionProxyFactory.class,
    "A graph request connection should persist the session provider it was created with"
  );
}

- (void)testDerivingSessionFromSessionProvider
{
  NSObject *session = (NSObject *)self.connection.session;

  XCTAssertEqualObjects(
    session,
    self.session,
    "A graph request connection should derive sessions from the session provider"
  );
}

- (void)testCreatingWithDefaultErrorConfigurationProvider
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  NSObject *errorConfigurationProvider = (NSObject *)connection.errorConfigurationProvider;
  XCTAssertEqualObjects(
    errorConfigurationProvider.class,
    FBSDKErrorConfigurationProvider.class,
    "A graph request connection should have the correct error configuration provider by default"
  );
}

- (void)testCreatingWithCustomErrorConfigurationProvider
{
  NSObject *errorConfigurationProvider = (NSObject *)self.connection.errorConfigurationProvider;

  XCTAssertEqualObjects(
    errorConfigurationProvider.class,
    TestErrorConfigurationProvider.class,
    "A graph request connection should persist the error configuration provider it was created with"
  );
}

- (void)testCreatingWithDefaultPiggybackManagerProvider
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  NSObject *piggybackManager = (NSObject *)connection.piggybackManagerProvider;
  XCTAssertEqualObjects(
    piggybackManager.class,
    FBSDKGraphRequestPiggybackManagerProvider.class,
    "A graph request connection should have the correct piggyback manager provider by default"
  );
}

- (void)testCreatingWithCustomPiggybackManager
{
  NSObject *provider = (NSObject *)self.connection.piggybackManagerProvider;

  XCTAssertEqualObjects(
    provider,
    self.piggybackManagerProvider,
    "A graph request connection should persist the piggyback manager provider it was created with"
  );
}

- (void)testCreatingWithDefaultSettings
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  NSObject *settings = (NSObject *)connection.settings;
  XCTAssertEqualObjects(
    settings.class,
    FBSDKSettings.class,
    "A graph request connection should have the correct settings type by default"
  );
}

- (void)testCreatingWithCustomSettings
{
  NSObject *settings = (NSObject *)self.connection.settings;

  XCTAssertEqualObjects(
    settings,
    self.settings,
    "A graph request connection should persist the settings it was created with"
  );
}

- (void)testCreatingWithDefaultConnectionFactory
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  NSObject *factory = (NSObject *)connection.connectionFactory;
  XCTAssertEqualObjects(
    factory.class,
    FBSDKGraphRequestConnectionFactory.class,
    "A graph request connection should have the correct connection factory by default"
  );
}

- (void)testCreatingWithCustomConnectionFactory
{
  NSObject *factory = (NSObject *)self.connection.connectionFactory;

  XCTAssertEqualObjects(
    factory,
    self.connectionFactory,
    "A graph request connection should persist the connection factory it was created with"
  );
}

- (void)testCreatingWithDefaultEventsLogger
{
  FBSDKGraphRequestConnection *connection = [FBSDKGraphRequestConnection new];
  NSObject *logger = (NSObject *)connection.eventLogger;
  XCTAssertEqualObjects(
    logger.class,
    FBSDKEventLogger.class,
    "A graph request connection should have the correct events logger by default"
  );
}

- (void)testCreatingWithCustomEventsLogger
{
  NSObject *logger = (NSObject *)self.connection.eventLogger;

  XCTAssertEqualObjects(
    logger,
    self.eventLogger,
    "A graph request connection should persist the events logger it was created with"
  );
}

// MARK: - Properties

- (void)testDefaultConnectionTimeout
{
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    60,
    "Should have a default connection timeout of 60 seconds"
  );
}

- (void)testOverridingDefaultConnectionTimeoutWithInvalidTimeout
{
  [FBSDKGraphRequestConnection setDefaultConnectionTimeout:-1];
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    60,
    "Should not be able to override the default connection timeout with an invalid timeout"
  );
}

- (void)testOverridingDefaultConnectionTimeoutWithValidTimeout
{
  [FBSDKGraphRequestConnection setDefaultConnectionTimeout:100];
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    100,
    "Should be able to override the default connection timeout"
  );
}

- (void)testDefaultOverriddenVersionPart
{
  XCTAssertNil(
    [self.connection _overrideVersionPart],
    "There should not be an overridden version part by default"
  );
}

- (void)testOverridingVersionPartWithInvalidVersions
{
  NSArray *strings = @[@"", @"abc", @"-5", @"1.1.1.1.1", @"v1.1.1.1"];
  for (NSString *string in strings) {
    [self.connection overrideGraphAPIVersion:string];
    XCTAssertEqualObjects(
      [self.connection _overrideVersionPart],
      string,
      "Should not be able to override the graph api version with %@ but you can",
      string
    );
  }
}

- (void)testOverridingVersionPartWithValidVersions
{
  NSArray *strings = @[@"1", @"1.1", @"1.1.1", @"v1", @"v1.1", @"v1.1.1"];
  for (NSString *string in strings) {
    [self.connection overrideGraphAPIVersion:string];
    XCTAssertEqualObjects(
      [self.connection _overrideVersionPart],
      string,
      "Should be able to override the graph api version with a valid version string"
    );
  }
}

- (void)testOverridingVersionCopies
{
  NSString *version = @"v1.0";
  [self.connection overrideGraphAPIVersion:version];
  version = @"foo";

  XCTAssertNotEqual(
    version,
    [self.connection _overrideVersionPart],
    "Should copy the version so that changes to the original string do not affect the stored value"
  );
}

- (void)testDefaultCanMakeRequests
{
  [FBSDKGraphRequestConnection resetCanMakeRequests];
  XCTAssertFalse(
    [FBSDKGraphRequestConnection canMakeRequests],
    "Should not be able to make requests by default"
  );
}

- (void)testDelegateQueue
{
  XCTAssertNil(self.connection.delegateQueue, "Should not have a delegate queue by default");
}

- (void)testSettingDelegateQueue
{
  self.connection.delegateQueue = NSOperationQueue.currentQueue;
  XCTAssertEqualObjects(
    self.connection.delegateQueue,
    NSOperationQueue.currentQueue,
    "Should be able to set the delegate queue"
  );
  XCTAssertEqualObjects(
    self.session.delegateQueue,
    NSOperationQueue.currentQueue,
    "Should set the session's delegate queue when setting the connnection's delegate queue"
  );
}

// MARK: - Adding Requests

- (void)testAddingRequestWithoutBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}];
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertNil(
    metadata.batchParameters,
    "Adding a request without a batch entry name should not store batch parameters"
  );
}

- (void)testAddingRequestWithEmptyBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
               batchEntryName:@""
            completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}];
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertNil(
    metadata.batchParameters,
    "Should not store batch parameters for a request with an empty batch entry name"
  );
}

- (void)testAddingRequestWithValidBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
               batchEntryName:@"foo"
            completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}];
  NSDictionary *expectedParameters = @{ @"name" : @"foo" };
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertEqualObjects(
    metadata.batchParameters,
    expectedParameters,
    "Should create and store batch parameters for a request with a non-empty batch entry name"
  );
}

- (void)testAddingRequestWithBatchParameters
{
  NSArray *states = @[@(kStateStarted), @(kStateCancelled), @(kStateCompleted), @(kStateSerialized)];

  for (NSNumber *state in states) {
    self.connection.state = state.intValue;
    XCTAssertThrowsSpecificNamed(
      [self.connection addRequest:self.requestForMeWithEmptyFields
                  batchParameters:@{}
                completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}],
      NSException,
      NSInternalInconsistencyException,
      "Should throw error on request addition when state has raw value: %@",
      state
    );
  }
  self.connection.state = kStateCreated;

  XCTAssertNoThrow(
    [self.connection addRequest:self.requestForMeWithEmptyFields
                batchParameters:@{}
              completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}],
    "Should not throw an error on request addition when state is 'created'"
  );
}

- (void)testAddingRequestToBatchWithBatchParameters
{
  NSDictionary *batchParameters = @{
    self.name : @"Foo",
    @"Bar" : @"Baz"
  };
  FBSDKGraphRequestMetadata *metadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:self.sampleRequest
                                                                         completionHandler:nil
                                                                           batchParameters:batchParameters];
  NSMutableArray *batch = [NSMutableArray array];
  [self.connection addRequest:metadata
                      toBatch:batch
                  attachments:[NSMutableDictionary dictionary]
                   batchToken:nil];

  NSDictionary *first = batch.firstObject;
  XCTAssertEqualObjects(
    first[self.name],
    @"Foo",
    "Should add the batch parameters to the from the request to the batch"
  );
  XCTAssertEqualObjects(
    first[@"Bar"],
    @"Baz",
    "Should add the batch parameters to the from the request to the batch"
  );
}

- (void)testAddingRequestToBatchSetsMethod
{
  FBSDKGraphRequest *postRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                     HTTPMethod:FBSDKHTTPMethodPOST];
  FBSDKGraphRequestMetadata *metadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:postRequest
                                                                         completionHandler:nil
                                                                           batchParameters:@{}];
  NSMutableArray *batch = [NSMutableArray array];
  [self.connection addRequest:metadata
                      toBatch:batch
                  attachments:[NSMutableDictionary dictionary]
                   batchToken:nil];
  XCTAssertEqualObjects(
    batch.firstObject[@"method"],
    FBSDKHTTPMethodPOST,
    "Should include the http method from the graph request in the batch"
  );
}

- (void)testAddingRequestToBatchWithToken
{
  NSString *token = self.name;
  NSURLQueryItem *expectedItem = [[NSURLQueryItem alloc] initWithName:@"access_token" value:token];
  FBSDKGraphRequestMetadata *metadata = [[FBSDKGraphRequestMetadata alloc] initWithRequest:self.sampleRequest
                                                                         completionHandler:nil
                                                                           batchParameters:@{}];
  NSMutableArray *batch = [NSMutableArray array];
  [self.connection addRequest:metadata
                      toBatch:batch
                  attachments:[NSMutableDictionary dictionary]
                   batchToken:token];
  NSString *urlString = batch.firstObject[@"relative_url"];
  NSURLComponents *components = [NSURLComponents componentsWithString:urlString];
  XCTAssertTrue(
    [components.queryItems containsObject:expectedItem],
    "Should include the batch token in the url for the batch request"
  );
}

- (void)testAddingRequestToBatchWithAttachments
{
  NSData *data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
  NSData *data2 = [@"bar" dataUsingEncoding:NSUTF8StringEncoding];

  FBSDKGraphRequest *request = [self sampleRequestWithParameters:@{ self.name : data }];
  FBSDKGraphRequest *request2 = [self sampleRequestWithParameters:@{ self.name : data2 }];
  FBSDKGraphRequestMetadata *metadata1 = [self metadataWithRequest:request];
  FBSDKGraphRequestMetadata *metadata2 = [self metadataWithRequest:request2];

  NSMutableArray *batch = [NSMutableArray array];
  NSMutableDictionary *attachments = [NSMutableDictionary dictionary];
  [self.connection addRequest:metadata1
                      toBatch:batch
                  attachments:attachments
                   batchToken:nil];
  [self.connection addRequest:metadata2
                      toBatch:batch
                  attachments:attachments
                   batchToken:nil];
  [batch enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *expectedFileName = [NSString stringWithFormat:@"file%@", @(idx)];
    XCTAssertEqualObjects(
      obj[@"attached_files"],
      expectedFileName,
      "Should store retrieval keys for the attachments taken from the graph requests"
    );
  }];
  NSDictionary *expectedAttachments = @{
    @"file0" : data,
    @"file1" : data2
  };
  XCTAssertEqualObjects(
    expectedAttachments,
    attachments,
    "Should add attachments from the graph requests"
  );
}

// MARK: - Attachments

- (void)testAppendingNonFormStringAttachment
{
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  [self.connection appendAttachments:@{ self.name : @"foo" }
                              toBody:body
                         addFormData:NO
                              logger:nil];
  XCTAssertNil(
    body.capturedKey,
    "Should not append strings if the attachment type is not form data"
  );
  XCTAssertNil(
    body.capturedFormValue,
    "Should not append strings if the attachment type is not form data"
  );
}

- (void)testAppendingFormStringAttachment
{
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  [self.connection appendAttachments:@{ self.name : @"foo" }
                              toBody:body
                         addFormData:YES
                              logger:nil];
  XCTAssertEqualObjects(
    body.capturedKey,
    self.name,
    "Should append strings when the attachment type is form data"
  );
  XCTAssertEqualObjects(body.capturedFormValue, @"foo", "Should pass through whether or not to use form data");
}

- (void)testAppendingImageData
{
  UIImage *image = [UIImage new];
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  [self.connection appendAttachments:@{ self.name : image }
                              toBody:body
                         addFormData:NO
                              logger:nil];
  XCTAssertEqualObjects(
    body.capturedImage,
    image,
    "Should always append images"
  );

  body.capturedImage = nil;
  [self.connection appendAttachments:@{ self.name : image }
                              toBody:body
                         addFormData:YES
                              logger:nil];
  XCTAssertEqualObjects(
    body.capturedImage,
    image,
    "Should always append images"
  );
}

- (void)testAppendingData
{
  NSData *data = [self.name dataUsingEncoding:NSUTF8StringEncoding];
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  [self.connection appendAttachments:@{ self.name : data }
                              toBody:body
                         addFormData:NO
                              logger:nil];
  XCTAssertEqualObjects(
    body.capturedData,
    data,
    "Should always append data"
  );

  body.capturedData = nil;
  [self.connection appendAttachments:@{ self.name : data }
                              toBody:body
                         addFormData:YES
                              logger:nil];
  XCTAssertEqualObjects(
    body.capturedData,
    data,
    "Should always append data"
  );
}

- (void)testAppendingDataAttachments
{
  NSData *data = [self.name dataUsingEncoding:NSUTF8StringEncoding];
  FBSDKGraphRequestDataAttachment *attachment = [[FBSDKGraphRequestDataAttachment alloc] initWithData:data
                                                                                             filename:@"fooFile"
                                                                                          contentType:@"application/json"];
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  [self.connection appendAttachments:@{ self.name : attachment }
                              toBody:body
                         addFormData:NO
                              logger:nil];
  XCTAssertEqualObjects(
    body.capturedAttachment,
    attachment,
    "Should always append data attachments"
  );

  body.capturedAttachment = nil;
  [self.connection appendAttachments:@{ self.name : attachment }
                              toBody:body
                         addFormData:YES
                              logger:nil];
  XCTAssertEqualObjects(
    body.capturedAttachment,
    attachment,
    "Should always append data attachments"
  );
}

- (void)testAppendingUnknownAttachmentTypeWithoutLogger
{
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  [self.connection appendAttachments:@{ self.name : UIColor.grayColor }
                              toBody:body
                         addFormData:NO
                              logger:nil];
  // Expect a noop
}

- (void)testAppendingUnknownAttachmentTypeWithLogger
{
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  TestLogger *logger = [TestLogger new];
  [self.connection appendAttachments:@{ self.name : UIColor.grayColor }
                              toBody:body
                         addFormData:NO
                              logger:logger];
  XCTAssertEqual(
    TestLogger.capturedLoggingBehavior,
    FBSDKLoggingBehaviorDeveloperErrors,
    "Should log an error when an unsupported type is attached"
  );
  XCTAssertEqualObjects(
    TestLogger.capturedLogEntry,
    @"Unsupported FBSDKGraphRequest attachment:UIExtendedGrayColorSpace 0.5 1, skipping.",
    "Should log an error when an unsupported type is attached"
  );
}

// MARK: - Cancelling

- (void)testCancellingConnection
{
  NSArray *states = @[@(kStateCreated), @(kStateStarted), @(kStateCancelled), @(kStateCompleted), @(kStateSerialized)];

  int expectedInvalidationCallCount = 0;
  for (NSNumber *state in states) {
    self.connection.state = state.intValue;
    expectedInvalidationCallCount++;

    [self.connection cancel];

    XCTAssertEqual(
      self.connection.state,
      kStateCancelled,
      "Cancelling a connection should set the state to the expected value"
    );
    XCTAssertEqual(
      self.session.invalidateAndCancelCallCount,
      expectedInvalidationCallCount,
      "Cancelling a connetion should invalidate and cancel the session"
    );
  }
}

// MARK: - Starting

- (void)testStartingConnectionWithUninitializedSDK
{
  [FBSDKGraphRequestConnection resetCanMakeRequests];
  NSString *msg = @"FBSDKGraphRequestConnection cannot be started before Facebook SDK initialized.";
  NSError *expectedError = [FBSDKError unknownErrorWithMessage:msg];
  self.connection.logger = [TestLogger new];

  __block BOOL completionWasCalled = NO;
  __weak typeof(self) weakSelf = self;
  [self.connection addRequest:self.sampleRequest
            completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
              XCTAssertEqualObjects(
                error,
                expectedError,
                "Starting a graph request before the SDK is initialized should return an error"
              );
              XCTAssertEqual(
                weakSelf.connection.state,
                kStateCancelled,
                "Starting a graph request before the SDK is initialized should update the connection state"
              );
              completionWasCalled = YES;
            }];
  [self.connection start];

  XCTAssertEqualObjects(
    TestLogger.capturedLogEntry,
    msg,
    "Starting a graph request before the SDK is initialized should log a warning"
  );
  XCTAssertEqual(
    TestLogger.capturedLoggingBehavior,
    FBSDKLoggingBehaviorDeveloperErrors,
    "Starting a graph request before the SDK is initialized should log a warning"
  );
  XCTAssertTrue(completionWasCalled);
}

- (void)testStartingWithInvalidStates
{
  self.connection.logger = [TestLogger new];

  NSArray *states = @[@(kStateStarted), @(kStateCancelled), @(kStateCompleted)];
  for (NSNumber *state in states) {
    self.connection.state = kStateCreated;
    [self.connection addRequest:self.sampleRequest
              completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                XCTFail("Should not be called");
              }];
    self.connection.state = state.intValue;
    [self.connection start];
    XCTAssertEqual(
      self.connection.state,
      state.intValue,
      "Should not change the connection state when starting in an invalid state"
    );
    XCTAssertEqualObjects(
      TestLogger.capturedLogEntry,
      @"FBSDKGraphRequestConnection cannot be started again.",
      "Starting a connection in an invalid state"
    );
    XCTAssertEqual(
      TestLogger.capturedLoggingBehavior,
      FBSDKLoggingBehaviorDeveloperErrors,
      "Starting a connection in an invalid state"
    );
    XCTAssertNil(self.session.capturedRequest, "Should not start a request for a connection in an invalid state");
  }
}

- (void)testStartingWithValidStates
{
  NSArray *states = @[@(kStateCreated), @(kStateSerialized)];

  for (NSNumber *state in states) {
    self.connection.state = kStateCreated;
    [self.connection addRequest:self.sampleRequest
              completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                XCTFail("Should not be called");
              }];
    self.connection.state = state.intValue;
    [self.connection start];
    XCTAssertEqual(
      self.connection.state,
      kStateStarted,
      "Should change the connection state to 'started' when starting in an valid state"
    );
    XCTAssertNotNil(self.session.capturedRequest, "Should start a request for a connection in an valid state");
  }
}

- (void)testStartingWithDelegateQueue
{
  self.connection.delegate = self;
  TestOperationQueue *queue = [TestOperationQueue new];
  self.connection.delegateQueue = queue;
  [self.connection addRequest:self.sampleRequest
            completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
              XCTFail("Should not be called");
            }];
  [self.connection start];
  XCTAssertTrue(
    queue.addOperationWithBlockWasCalled,
    "Starting a connection should add the request to the delegate queue when one exists"
  );

  queue.capturedOperationBlock();
}

- (void)testStartingInvokesPiggybackManager
{
  [self.connection addRequest:self.sampleRequest
            completionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {}];
  [self.connection start];

  XCTAssertEqualObjects(
    self.connection,
    TestGraphRequestPiggybackManager.capturedConnection,
    "Starting a request should invoke the piggyback manager"
  );
}

// MARK: - Errors From Results

- (void)testErrorFromResultWithNonDictionaryInput
{
  NSArray *inputs = @[@"foo", @123, @YES, NSNull.null, NSData.data, @[]];

  for (id input in inputs) {
    XCTAssertNil(
      [self.connection errorFromResult:input request:self.sampleRequest],
      "Should not create an error from %@",
      input
    );
  }
}

- (void)testErrorFromResultWithMissingBodyInInput
{
  XCTAssertNil(
    [self.connection errorFromResult:@{} request:self.sampleRequest],
    "Should not create an error from an empty dictionary"
  );
}

- (void)testErrorFromResultWithMissingErrorInInputBody
{
  NSDictionary *result = @{
    @"body" : @{}
  };

  XCTAssertNil(
    [self.connection errorFromResult:result request:self.sampleRequest],
    "Should not create an error from a dictionary with a missing error key"
  );
}

- (void)testErrorFromResultWithFuzzyInput
{
  for (int i = 1; i < 100; i++) {
    [self.connection errorFromResult:[Fuzzer randomizeWithJson:self.sampleErrorDictionary]
                             request:self.sampleRequest];
  }
}

- (void)testErrorFromResultDependsOnErrorConfiguration
{
  [self.connection errorFromResult:self.sampleErrorDictionary request:self.sampleRequest];
  FBSDKGraphRequest *capturedRequest = (FBSDKGraphRequest *)self.errorConfiguration.capturedGraphRequest;

  XCTAssertNotNil(capturedRequest.graphPath, "Should capture the graph request from the result");
  XCTAssertEqualObjects(
    self.errorConfiguration.capturedRecoveryConfigurationCode,
    @"1",
    "Should capture the error code from the result"
  );
  XCTAssertEqualObjects(
    self.errorConfiguration.capturedRecoveryConfigurationSubcode,
    @"2",
    "Should capture the error subcode from the result"
  );
}

- (void)testErrorFromResult
{
  NSError *error = [self.connection errorFromResult:self.sampleErrorDictionary request:self.sampleRequest];
  XCTAssertEqualObjects(
    error.userInfo[NSLocalizedRecoverySuggestionErrorKey],
    self.errorRecoveryConfiguration.localizedRecoveryDescription,
    "Should derive the recovery description from the recovery configuration"
  );
  XCTAssertEqualObjects(
    error.userInfo[NSLocalizedRecoveryOptionsErrorKey],
    self.errorRecoveryConfiguration.localizedRecoveryOptionDescriptions,
    "Should derive the recovery options from the recovery configuration"
  );
  XCTAssertNil(
    error.userInfo[NSRecoveryAttempterErrorKey],
    "A non transient error should not provide a recovery attempter"
  );
}

- (void)testErrorFromResultMessagePriority
{
  NSDictionary *response = @{
    @"body" : @{
      @"error" : @{ @"error_msg" : @"error_msg" }
    }
  };
  NSError *error = [self.connection errorFromResult:response request:self.sampleRequest];
  XCTAssertEqualObjects(
    error.userInfo[FBSDKErrorDeveloperMessageKey],
    @"error_msg",
    "Should use the 'error_msg' if it's the only message available"
  );
  response = @{
    @"body" : @{
      @"error" : @{
        @"error_msg" : @"error_msg",
        @"error_reason" : @"error_reason"
      }
    }
  };
  error = [self.connection errorFromResult:response request:self.sampleRequest];
  XCTAssertEqualObjects(
    error.userInfo[FBSDKErrorDeveloperMessageKey],
    @"error_reason",
    "Should prefer the 'error_reason' to the 'error_msg'"
  );

  response = @{
    @"body" : @{
      @"error" : @{
        @"error_msg" : @"error_msg",
        @"error_reason" : @"error_reason",
        @"message" : @"message"
      }
    }
  };
  error = [self.connection errorFromResult:response request:self.sampleRequest];
  XCTAssertEqualObjects(
    error.userInfo[FBSDKErrorDeveloperMessageKey],
    @"message",
    "Should prefer the 'message' key to other error message keys"
  );
}

// MARK: - Client Token

- (void)testClientToken
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];

  self.errorConfigurationProvider.configuration = nil;
  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
              // make sure there is no recovery info for client token failures.
              XCTAssertNil(error.localizedRecoverySuggestion);
              [expectation fulfill];
            }];
  [self.connection start];

  NSData *data = [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463, \"type\":\"OAuthException\"}}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);
  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testClientTokenSkipped
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];

  self.errorConfigurationProvider.configuration = nil;
  [self.connection addRequest:self.requestForMeWithEmptyFields completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
    // make sure there is no recovery info for client token failures.
    XCTAssertNil(error.localizedRecoverySuggestion);
    [expectation fulfill];
  }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);
  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testConnectionDelegate
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  __block int actualCallbacksCount = 0;
  [self.connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
              XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
            }];
  [self.connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
              XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
            }];
  self.requestConnectionStartingCallback = ^(FBSDKGraphRequestConnection *conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  self.connection.delegate = self;
  [self.connection start];

  NSString *meResponse = [@"{ \"id\":\"userid\"}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": \"%@\" }, {\"code\":200,\"body\": \"%@\" } ]", meResponse, meResponse];
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testNonErrorEmptyDictionaryOrNullResponse
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  __block int actualCallbacksCount = 0;
  [self.connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
              XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
            }];
  [self.connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {
              XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
            }];
  self.requestConnectionStartingCallback = ^(FBSDKGraphRequestConnection *conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  self.connection.delegate = self;
  [self.connection start];

  NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": null }, {\"code\":200,\"body\": {} } ]"];
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testConnectionDelegateWithNetworkError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self.connection addRequest:[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
            completionHandler:^(FBSDKGraphRequestConnection *conn, id result, NSError *error) {}];
  self.requestConnectionCallback = ^(FBSDKGraphRequestConnection *conn, NSError *error) {
    NSCAssert(error != nil, @"didFinishLoading shouldn't have been called");
    [expectation fulfill];
  };
  self.connection.delegate = self;
  [self.connection start];

  self.session.capturedCompletion(nil, nil, [NSError errorWithDomain:@"NSURLErrorDomain" code:-1009 userInfo:nil]);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testUnsettingAccessToken
{
  __block int tokenChangeCount = 0;
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  XCTestExpectation *notificationExpectation = [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                                                                         object:nil
                                                                        handler:^BOOL (NSNotification *notification) {
                                                                          if (++tokenChangeCount == 2) {
                                                                            XCTAssertNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                                                                            XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeOldKey]);
                                                                            return YES;
                                                                          }
                                                                          return NO;
                                                                        }];

  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:accessToken];

  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
              XCTAssertNil(result);
              XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
              [expectation fulfill];
            }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation, notificationExpectation] timeout:1];

  XCTAssertNil([FBSDKAccessToken currentAccessToken]);
}

- (void)testUnsettingAccessTokenSkipped
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  XCTestExpectation *notificationExpectation = [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                                                                         object:nil
                                                                        handler:^BOOL (NSNotification *notification) {
                                                                          XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                                                                          return YES;
                                                                        }];

  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];

  [FBSDKAccessToken setCurrentAccessToken:accessToken];

  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                 parameters:@{@"fields" : @""}
                                                                tokenString:@"notCurrentToken"
                                                                    version:nil
                                                                 HTTPMethod:@""];
  [self.connection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
    [expectation fulfill];
  }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation, notificationExpectation] timeout:1];

  XCTAssertNotNil([FBSDKAccessToken currentAccessToken]);
}

- (void)testUnsettingAccessTokenFlag
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  XCTestExpectation *notificationExpectation = [self expectationForNotification:FBSDKAccessTokenDidChangeNotification
                                                                         object:nil
                                                                        handler:^BOOL (NSNotification *notification) {
                                                                          XCTAssertNotNil(notification.userInfo[FBSDKAccessTokenChangeNewKey]);
                                                                          return YES;
                                                                        }];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
  [FBSDKAccessToken setCurrentAccessToken:accessToken];

  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""} flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError];
  [self.connection addRequest:request completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
    XCTAssertNil(result);
    XCTAssertEqualObjects(@"Token is broke", error.userInfo[FBSDKErrorDeveloperMessageKey]);
    [expectation fulfill];
  }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation, notificationExpectation] timeout:1];

  XCTAssertNotNil([FBSDKAccessToken currentAccessToken]);
}

- (void)testRequestWithUserAgentSuffix
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  TestSettings.userAgentSuffix = @"UnitTest.1.0.0";

  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {}];
  [self.connection start];

  NSString *userAgent = [self.session.capturedRequest valueForHTTPHeaderField:@"User-Agent"];
  XCTAssertTrue([userAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", userAgent);
}

- (void)testRequestWithoutUserAgentSuffix
{
  [FBSDKAccessToken setCurrentAccessToken:nil];
  TestSettings.userAgentSuffix = nil;

  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {}];
  [self.connection start];

  NSString *userAgent = [self.session.capturedRequest valueForHTTPHeaderField:@"User-Agent"];
  XCTAssertFalse([userAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", userAgent);
}

- (void)testNonDictionaryInError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
              // should not crash when receiving something other than a dictionary within the response.
              [expectation fulfill];
            }];
  [self.connection start];

  NSData *data = [@"{\"error\": \"a-non-dictionary\"}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:200 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRequestWithBatchConstructionWithSingleGetRequest
{
  FBSDKGraphRequest *singleRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"with_suffix"}];
  [self.connection addRequest:singleRequest completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {}];
  NSURLRequest *request = [self.connection requestWithBatch:self.connection.requests timeout:0];

  NSURLComponents *urlComponents = [NSURLComponents componentsWithString:request.URL.absoluteString];
  XCTAssertEqualObjects(urlComponents.host, @"graph.facebook.com");
  XCTAssertTrue([urlComponents.path containsString:@"me"]);
  XCTAssertEqualObjects(request.HTTPMethod, @"GET");
  XCTAssertTrue(request.HTTPBody.length == 0);
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
}

- (void)testRequestWithBatchConstructionWithSinglePostRequest
{
  NSDictionary *parameters = @{
    @"first_key" : @"first_value",
  };
  FBSDKGraphRequest *singleRequest = [[FBSDKGraphRequest alloc] initWithGraphPath:@"activities" parameters:parameters HTTPMethod:FBSDKHTTPMethodPOST];
  [self.connection addRequest:singleRequest completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {}];
  NSURLRequest *request = [self.connection requestWithBatch:self.connection.requests timeout:0];

  NSURLComponents *urlComponents = [NSURLComponents componentsWithString:request.URL.absoluteString];
  XCTAssertEqualObjects(urlComponents.host, @"graph.facebook.com");
  XCTAssertTrue([urlComponents.path containsString:@"activities"]);
  XCTAssertEqualObjects(request.HTTPMethod, @"POST");
  XCTAssertTrue(request.HTTPBody.length > 0);
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Encoding"], @"gzip");
  XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
}

#pragma mark - accessTokenWithRequest

- (void)testAccessTokenWithRequest
{
  NSString *expectedToken = @"fake_token";
  FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                 parameters:@{@"fields" : @""}
                                                                tokenString:expectedToken
                                                                 HTTPMethod:FBSDKHTTPMethodGET
                                                                      flags:FBSDKGraphRequestFlagNone];
  NSString *token = [self.connection accessTokenWithRequest:request];
  XCTAssertEqualObjects(token, expectedToken);
}

- (void)testAccessTokenWithRequestWithFacebookClientToken
{
  NSString *clientToken = @"client_token";
  TestSettings.clientToken = clientToken;
  NSString *token = [self.connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  NSString *expectedToken = [NSString stringWithFormat:@"%@|%@", self.appID, clientToken];
  XCTAssertEqualObjects(token, expectedToken);
}

- (void)testAccessTokenWithRequestWithGamingClientToken
{
  NSString *clientToken = @"client_token";
  TestSettings.clientToken = clientToken;
  FBSDKAuthenticationToken *authToken = [[FBSDKAuthenticationToken alloc] initWithTokenString:@"token_string"
                                                                                        nonce:@"nonce"
                                                                                  graphDomain:@"gaming"];
  [FBSDKAuthenticationToken setCurrentAuthenticationToken:authToken];
  NSString *token = [self.connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  NSString *expectedToken = [NSString stringWithFormat:@"GG|%@|%@", self.appID, clientToken];
  XCTAssertEqualObjects(token, expectedToken);

  [FBSDKAuthenticationToken setCurrentAuthenticationToken:nil];
}

#pragma mark - Error recovery.

- (void)testRetryWithTransientError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  FBSDKSettings.graphErrorRecoveryEnabled = YES;

  TestURLSessionProxy *fakeSession = [TestURLSessionProxy new];
  TestURLSessionProxyFactory *fakeProxyFactory = [TestURLSessionProxyFactory createWithSessions:@[fakeSession]];

  self.errorRecoveryConfiguration = self.transientErrorRecoveryConfiguration;
  self.errorConfiguration.stubbedRecoveryConfiguration = self.errorRecoveryConfiguration;
  self.errorConfigurationProvider.configuration = self.errorConfiguration;
  FBSDKGraphRequestConnection *retryConnection = [[FBSDKGraphRequestConnection alloc] initWithURLSessionProxyFactory:fakeProxyFactory
                                                                                          errorConfigurationProvider:self.errorConfigurationProvider
                                                                                            piggybackManagerProvider:self.piggybackManagerProvider
                                                                                                            settings:self.settings
                                                                                                   connectionFactory:self.connectionFactory
                                                                                                         eventLogger:self.eventLogger];
  self.connectionFactory.stubbedConnection = retryConnection;
  __block int completionCallCount = 0;
  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
              completionCallCount++;
              XCTAssertEqual(completionCallCount, 1, "The completion should only be called once");
              XCTAssertEqual(
                2,
                [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue],
                "The completion should be called with the expected error code"
              );
              [expectation fulfill];
            }];

  [self.connection start];

  NSData *data = [@"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  // The first captured completion will be invoked and cause the retry
  self.session.capturedCompletion(data, response, nil);

  // It's necessary to dispatch async to avoid the completion from being invoked before it is captured
  dispatch_async(dispatch_get_main_queue(), ^{
    NSData *secondData = [@"{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
    fakeSession.capturedCompletion(secondData, response, nil);
  });

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRetryDisabled
{
  FBSDKSettings.graphErrorRecoveryEnabled = NO;

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  __block int completionCallCount = 0;
  [self.connection addRequest:self.requestForMeWithEmptyFields
            completionHandler:^(FBSDKGraphRequestConnection *potentialConnection, id result, NSError *error) {
              completionCallCount++;
              XCTAssertEqual(completionCallCount, 1, "The completion should only be called once");
              XCTAssertEqual(
                1,
                [error.userInfo[FBSDKGraphRequestErrorGraphErrorCodeKey] integerValue],
                "The completion should be called with the expected error code"
              );

              [expectation fulfill];
            }];

  [self.connection start];

  NSData *data = [@"{\"error\": {\"message\": \"Server is busy\",\"code\": 1,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:NSURL.new statusCode:400 HTTPVersion:nil headerFields:nil];

  // The first captured completion will be invoked and cause the retry
  self.session.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

// MARK: - Response Parsing

- (void)testParsingJsonResponseWithInvalidData
{
  uint16_t value = 0xb70f;
  NSData *data = [NSData dataWithBytes:&value length:2];
  NSError *error;
  [self.connection parseJSONResponse:data error:&error statusCode:0];

  XCTAssertEqualObjects(
    self.eventLogger.capturedEventName,
    @"fb_response_invalid_utf8",
    "Should log the correct event name"
  );
  XCTAssertTrue(
    self.eventLogger.capturedIsImplicitlyLogged,
    "Should implicitly log an event indicating a json parsing failure"
  );
}

- (void)testProcessingResultBodyWithDebugDictionary
{
  self.connection.logger = [TestLogger new];
  NSArray *entries = @[
    @"message1 Link: link1",
    @"message2 Link: link2"
  ];
  [self.connection processResultBody:self.debugResponse error:nil metadata:nil canNotifyDelegate:NO];
  XCTAssertEqualObjects(
    TestLogger.capturedLogEntries,
    entries,
    "Should log entries from the debug dictionary"
  );
}

- (void)testProcessingResultBodyWithRandomizedDebugDictionary
{
  for (int i = 1; i < 100; i++) {
    NSDictionary *body = [Fuzzer randomizeWithJson:self.debugResponse];
    [self.connection processResultBody:body error:nil metadata:nil canNotifyDelegate:NO];
  }
}

- (void)testLogRequestWithInactiveLogger
{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.sampleUrl];
  TestLogger *logger = [TestLogger new];
  TestLogger *bodyLogger = [TestLogger new];
  TestLogger *attachmentLogger = [TestLogger new];
  self.connection.logger = logger;
  [self.connection logRequest:request bodyLength:1024 bodyLogger:bodyLogger attachmentLogger:attachmentLogger];

  XCTAssertEqualObjects(logger.capturedAppendedKeys, @[]);
  XCTAssertEqualObjects(logger.capturedAppendedValues, @[]);
}

- (void)testLogRequestWithActiveLogger
{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.sampleUrl];
  TestLogger *logger = [TestLogger new];
  TestLogger *bodyLogger = [TestLogger new];
  TestLogger *attachmentLogger = [TestLogger new];

  bodyLogger.contents = @"bodyContents";
  attachmentLogger.contents = @"attachmentLoggerContents";
  logger.stubbedIsActive = YES;
  self.connection.logger = logger;

  [self.connection logRequest:request bodyLength:1024 bodyLogger:bodyLogger attachmentLogger:attachmentLogger];

  NSArray *expectedKeys = @[
    @"URL",
    @"Method",
    @"UserAgent",
    @"MIME",
    @"Body Size",
    @"Body (w/o attachments)",
    @"Attachments"
  ];

  NSArray *expectedValues = @[
    @"https://example.com",
    @"GET",
    @"",
    @"",
    @"1 kB",
    @"bodyContents",
    @"attachmentLoggerContents"
  ];

  XCTAssertEqualObjects(
    logger.capturedAppendedKeys,
    expectedKeys,
    "Should append the expected key value pairs to log"
  );
  XCTAssertEqualObjects(
    logger.capturedAppendedValues,
    expectedValues,
    "Should append the expected key value pairs to log"
  );
}

- (void)testInvokesDelegate
{
  self.connection.delegate = self;
  [self.connection URLSession:nil task:nil didSendBodyData:0 totalBytesSent:0 totalBytesExpectedToSend:0];
  XCTAssertTrue(
    self.didInvokeDelegateRequestConnectionDidSendBodyData,
    "The url session data delegate should pass through to the graph request connection delegate"
  );
}

// MARK: - Helpers

- (FBSDKGraphRequest *)sampleRequest
{
  return self.requestForMeWithEmptyFields;
}

- (FBSDKGraphRequest *)sampleRequestWithParameters:(NSDictionary *)parameters
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters];
}

- (FBSDKGraphRequest *)requestForMeWithEmptyFields
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}];
}

- (FBSDKGraphRequest *)requestForMeWithEmptyFieldsNoTokenString
{
  return [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""} tokenString:nil HTTPMethod:FBSDKHTTPMethodGET flags:FBSDKGraphRequestFlagNone];
}

- (FBSDKGraphRequestMetadata *)metadataWithRequest:(FBSDKGraphRequest *)request
{
  return [[FBSDKGraphRequestMetadata alloc] initWithRequest:request
                                          completionHandler:nil
                                            batchParameters:@{}];
}

- (NSData *)missingTokenData
{
  return [@"{\"error\": {\"message\": \"Token is broke\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)sampleErrorDictionary
{
  return @{
    @"code" : @200,
    @"body" : @{
      @"error" : @{
        @"is_transient" : @1,
        @"code" : @1,
        @"error_subcode" : @2,
        @"error_msg" : @"error_msg",
        @"error_reason" : @"error_reason",
        @"message" : @"message",
        @"error_user_title" : @"error_user_title",
        @"error_user_msg" : @"error_user_msg",
        @"error_user_msg" : @"error_user_msg",
      }
    }
  };
}

- (FBSDKErrorRecoveryConfiguration *)transientErrorRecoveryConfiguration
{
  return [[FBSDKErrorRecoveryConfiguration alloc] initWithRecoveryDescription:@"Recovery Description"
                                                           optionDescriptions:@[@"Option1", @"Option2"]
                                                                     category:FBSDKGraphRequestErrorTransient
                                                           recoveryActionName:@"Recovery Action"];
}

- (FBSDKErrorRecoveryConfiguration *)nonTransientErrorRecoveryConfiguration
{
  return [[FBSDKErrorRecoveryConfiguration alloc] initWithRecoveryDescription:@"Recovery Description"
                                                           optionDescriptions:@[@"Option1", @"Option2"]
                                                                     category:FBSDKGraphRequestErrorOther
                                                           recoveryActionName:@"Recovery Action"];
}

- (NSDictionary *)debugResponse
{
  return @{
    @"__debug__" : @{
      @"messages" : @[
        @{
          @"message" : @"message1",
          @"type" : @"type1",
          @"link" : @"link1"
        },
        @{
          @"message" : @"message2",
          @"type" : @"warning",
          @"link" : @"link2"
        }
      ]
    }
  };
}

- (NSURL *)sampleUrl
{
  return [NSURL URLWithString:@"https://example.com"];
}

@end
