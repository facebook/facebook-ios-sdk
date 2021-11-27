/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <TestTools/TestTools-Swift.h>

#import "FBSDKCoreKit.h"
#import "FBSDKCoreKitTests-Swift.h"
#import "FBSDKFeatureManager.h"
#import "FBSDKGraphRequest+Internal.h"
#import "FBSDKGraphRequestConnection+Internal.h"
#import "FBSDKSettings+Internal.h"
#import "FBSDKSettingsProtocol.h"
#import "FBSDKURLSessionProxyFactory.h"

@interface FBSDKGraphRequestConnectionTests : XCTestCase <FBSDKGraphRequestConnectionDelegate>

@property (nonatomic) NSString *appID;
@property (nonatomic) TestURLSessionProxy *session;
@property (nonatomic) TestURLSessionProxy *secondSession;
@property (nonatomic) TestURLSessionProxyFactory *sessionFactory;
@property (nonatomic) TestErrorConfiguration *errorConfiguration;
@property (nonatomic) TestErrorConfigurationProvider *errorConfigurationProvider;
@property (nonatomic) FBSDKErrorRecoveryConfiguration *errorRecoveryConfiguration;
@property (nonatomic) TestSettings *settings;
@property (nonatomic) TestGraphRequestConnectionFactory *graphRequestConnectionFactory;
@property (nonatomic) TestEventLogger *eventLogger;
@property (nonatomic) TestProcessInfo *processInfo;
@property (nonatomic) TestMacCatalystDeterminator *macCatalystDeterminator;
@property (nonatomic) TestLogger *logger;
@property (nonatomic) FBSDKGraphRequestConnection *connection;
@property (nonatomic) TestErrorFactory *errorFactory;

@property (nonatomic, copy) void (^requestConnectionStartingCallback)(id<FBSDKGraphRequestConnecting> connection);
@property (nonatomic, copy) void (^requestConnectionCallback)(id<FBSDKGraphRequestConnecting> connection, NSError *error);
@property (nonatomic) BOOL didInvokeDelegateRequestConnectionDidSendBodyData;
@property (nonatomic) FBSDKGraphRequestMetadata *metadata;

@end

@implementation FBSDKGraphRequestConnectionTests

- (void)setUp
{
  [super setUp];

  self.metadata = [self createSampleMetadata];
  [TestAccessTokenWallet reset];
  [FBSDKGraphRequestConnection setCanMakeRequests];

  self.appID = @"appid";
  self.session = [TestURLSessionProxy new];
  self.secondSession = [TestURLSessionProxy new];
  self.sessionFactory = [TestURLSessionProxyFactory createWithSessions:@[self.session, self.secondSession]];
  self.errorRecoveryConfiguration = self.nonTransientErrorRecoveryConfiguration;
  self.errorConfiguration = [TestErrorConfiguration new];
  self.errorConfiguration.stubbedRecoveryConfiguration = self.errorRecoveryConfiguration;
  self.errorConfigurationProvider = [[TestErrorConfigurationProvider alloc] initWithConfiguration:self.errorConfiguration];
  self.settings = [TestSettings new];
  self.settings.appID = self.appID;
  self.graphRequestConnectionFactory = [TestGraphRequestConnectionFactory new];
  self.eventLogger = [TestEventLogger new];
  self.macCatalystDeterminator = [TestMacCatalystDeterminator new];
  self.logger = [[TestLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
  self.errorFactory = [TestErrorFactory new];
  [FBSDKGraphRequestConnection configureWithURLSessionProxyFactory:self.sessionFactory
                                        errorConfigurationProvider:self.errorConfigurationProvider
                                                  piggybackManager:TestGraphRequestPiggybackManager.self
                                                          settings:self.settings
                                     graphRequestConnectionFactory:self.graphRequestConnectionFactory
                                                       eventLogger:self.eventLogger
                                    operatingSystemVersionComparer:self.processInfo
                                           macCatalystDeterminator:self.macCatalystDeterminator
                                               accessTokenProvider:TestAccessTokenWallet.class
                                                 accessTokenSetter:TestAccessTokenWallet.class
                                                      errorFactory:self.errorFactory
                                       authenticationTokenProvider:TestAuthenticationTokenWallet.class];
  self.connection = [FBSDKGraphRequestConnection new];
  self.graphRequestConnectionFactory.stubbedConnection = self.connection;
}

- (void)tearDown
{
  [FBSDKGraphRequestConnection resetClassDependencies];
  [FBSDKGraphRequestConnection resetDefaultConnectionTimeout];
  [FBSDKGraphRequestConnection resetCanMakeRequests];
  [TestGraphRequestPiggybackManager reset];
  [TestLogger reset];
  [self.settings reset];

  [super tearDown];
}

// MARK: - FBSDKGraphRequestConnectionDelegate

- (void)requestConnection:(id<FBSDKGraphRequestConnecting>)connection didFailWithError:(NSError *)error
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, error);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionDidFinishLoading:(id<FBSDKGraphRequestConnecting>)connection
{
  if (self.requestConnectionCallback) {
    self.requestConnectionCallback(connection, nil);
    self.requestConnectionCallback = nil;
  }
}

- (void)requestConnectionWillBeginLoading:(id<FBSDKGraphRequestConnecting>)connection
{
  if (self.requestConnectionStartingCallback) {
    self.requestConnectionStartingCallback(connection);
    self.requestConnectionStartingCallback = nil;
  }
}

- (void)  requestConnection:(id<FBSDKGraphRequestConnecting>)connection
            didSendBodyData:(NSInteger)bytesWritten
          totalBytesWritten:(NSInteger)totalBytesWritten
  totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
  self.didInvokeDelegateRequestConnectionDidSendBodyData = YES;
}

// MARK: - Dependencies

- (void)testDefaultDependencies
{
  [FBSDKGraphRequestConnection resetClassDependencies];

  XCTAssertNil(
    FBSDKGraphRequestConnection.sessionProxyFactory,
    @"A graph request connection should not have a session provider by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.errorConfigurationProvider,
    @"A graph request connection should not have a error configuration provider by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.piggybackManager,
    @"A graph request connection should not have a piggyback manager by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.settings,
    @"A graph request connection should not have a settings type by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.graphRequestConnectionFactory,
    @"A graph request connection should not have a connection factory by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.eventLogger,
    @"A graph request connection should not have an events logger by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.operatingSystemVersionComparer,
    @"A graph request connection should not have an operating system version comparer by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.macCatalystDeterminator,
    @"A graph request connection should not have a Mac Catalyst determinator by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.accessTokenProvider,
    @"A graph request connection should not an access token provider by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.accessTokenSetter,
    @"A graph request connection should not have an access token setter by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.errorFactory,
    @"A graph request connection should not have an error factory by default"
  );
  XCTAssertNil(
    FBSDKGraphRequestConnection.authenticationTokenProvider,
    @"A graph request connection should not have an authentication token provider by default"
  );
}

- (void)testCreatingWithCustomDependencies
{
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.sessionProxyFactory,
    self.sessionFactory,
    @"A graph request connection should persist the session provider it was created with"
  );
  XCTAssertEqualObjects(
    self.connection.session,
    self.session,
    @"A graph request connection should derive sessions from the session provider"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.errorConfigurationProvider,
    self.errorConfigurationProvider,
    @"A graph request connection should persist the error configuration provider it was created with"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.piggybackManager,
    TestGraphRequestPiggybackManager.self,
    @"A graph request connection should persist the piggyback manager it was created with"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.settings,
    self.settings,
    @"A graph request connection should persist the settings it was created with"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.graphRequestConnectionFactory,
    self.graphRequestConnectionFactory,
    @"A graph request connection should persist the connection factory it was created with"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.eventLogger,
    self.eventLogger,
    @"A graph request connection should persist the events logger it was created with"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.operatingSystemVersionComparer,
    self.processInfo,
    @"A graph request connection should persist the operating system comparer it was created with"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.macCatalystDeterminator,
    self.macCatalystDeterminator,
    @"A graph request connection should persist the Mac Catalyst determinator it was created with"
  );
  XCTAssertEqual(
    FBSDKGraphRequestConnection.accessTokenProvider,
    TestAccessTokenWallet.class,
    @"A graph request connection should persist the access token provider it was created with"
  );
  XCTAssertEqual(
    FBSDKGraphRequestConnection.accessTokenSetter,
    TestAccessTokenWallet.class,
    @"A graph request connection should persist the access token setter it was created with"
  );
  XCTAssertEqualObjects(
    FBSDKGraphRequestConnection.errorFactory,
    self.errorFactory,
    @"A graph request connection should persist the error factory it was created with"
  );
  XCTAssertEqual(
    FBSDKGraphRequestConnection.authenticationTokenProvider,
    TestAuthenticationTokenWallet.class,
    @"A graph request connection should persist the authentication token provider it was created with"
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
  FBSDKGraphRequestConnection.defaultConnectionTimeout = -1;
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    60,
    "Should not be able to override the default connection timeout with an invalid timeout"
  );
}

- (void)testOverridingDefaultConnectionTimeoutWithValidTimeout
{
  FBSDKGraphRequestConnection.defaultConnectionTimeout = 100;
  XCTAssertEqual(
    FBSDKGraphRequestConnection.defaultConnectionTimeout,
    100,
    "Should be able to override the default connection timeout"
  );
}

- (void)testDefaultOverriddenVersionPart
{
  XCTAssertNil(
    self.connection.overriddenVersionPart,
    "There should not be an overridden version part by default"
  );
}

- (void)testOverridingVersionPartWithInvalidVersions
{
  NSArray *strings = @[@"", @"abc", @"-5", @"1.1.1.1.1", @"v1.1.1.1"];
  for (NSString *string in strings) {
    [self.connection overrideGraphAPIVersion:string];
    XCTAssertEqualObjects(
      self.connection.overriddenVersionPart,
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
      self.connection.overriddenVersionPart,
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
    self.connection.overriddenVersionPart,
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
                   completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}];
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertNil(
    metadata.batchParameters,
    "Adding a request without a batch entry name should not store batch parameters"
  );
}

- (void)testAddingRequestWithEmptyBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
                         name:@""
                   completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}];
  FBSDKGraphRequestMetadata *metadata = self.connection.requests.firstObject;
  XCTAssertNil(
    metadata.batchParameters,
    "Should not store batch parameters for a request with an empty batch entry name"
  );
}

- (void)testAddingRequestWithValidBatchEntryName
{
  [self.connection addRequest:self.requestForMeWithEmptyFields
                         name:@"foo"
                   completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}];
  NSDictionary<NSString *, id> *expectedParameters = @{ @"name" : @"foo" };
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
                       parameters:@{}
                       completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}],
      NSException,
      NSInternalInconsistencyException,
      "Should throw error on request addition when state has raw value: %@",
      state
    );
  }
  self.connection.state = kStateCreated;

  XCTAssertNoThrow(
    [self.connection addRequest:self.requestForMeWithEmptyFields
                     parameters:@{}
                     completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}],
    "Should not throw an error on request addition when state is 'created'"
  );
}

- (void)testAddingRequestToBatchWithBatchParameters
{
  NSDictionary<NSString *, id> *batchParameters = @{
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

  NSDictionary<NSString *, id> *first = batch.firstObject;
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
  id<FBSDKGraphRequest> postRequest = [[TestGraphRequest alloc] initWithGraphPath:@"me"
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

  id<FBSDKGraphRequest> request = [self sampleRequestWithParameters:@{ self.name : data }];
  id<FBSDKGraphRequest> request2 = [self sampleRequestWithParameters:@{ self.name : data2 }];
  FBSDKGraphRequestMetadata *metadata1 = [self metadataWithRequest:request];
  FBSDKGraphRequestMetadata *metadata2 = [self metadataWithRequest:request2];

  NSMutableArray *batch = [NSMutableArray array];
  NSMutableDictionary<NSString *, id> *attachments = [NSMutableDictionary dictionary];
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
  NSDictionary<NSString *, id> *expectedAttachments = @{
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
                              logger:self.logger];
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
                              logger:self.logger];
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
                              logger:self.logger];
  XCTAssertEqualObjects(
    body.capturedImage,
    image,
    "Should always append images"
  );

  body.capturedImage = nil;
  [self.connection appendAttachments:@{ self.name : image }
                              toBody:body
                         addFormData:YES
                              logger:self.logger];
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
                              logger:self.logger];
  XCTAssertEqualObjects(
    body.capturedData,
    data,
    "Should always append data"
  );

  body.capturedData = nil;
  [self.connection appendAttachments:@{ self.name : data }
                              toBody:body
                         addFormData:YES
                              logger:self.logger];
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
                              logger:self.logger];
  XCTAssertEqualObjects(
    body.capturedAttachment,
    attachment,
    "Should always append data attachments"
  );

  body.capturedAttachment = nil;
  [self.connection appendAttachments:@{ self.name : attachment }
                              toBody:body
                         addFormData:YES
                              logger:self.logger];
  XCTAssertEqualObjects(
    body.capturedAttachment,
    attachment,
    "Should always append data attachments"
  );
}

- (void)testAppendingUnknownAttachmentTypeWithLogger
{
  TestGraphRequestBody *body = [TestGraphRequestBody new];
  TestLogger *logger = [self createLogger];
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
  self.connection.logger = [self createLogger];

  NSString *expectedMessage = @"FBSDKGraphRequestConnection cannot be started before Facebook SDK initialized.";
  __block BOOL completionWasCalled = NO;
  __weak typeof(self) weakSelf = self;
  [self.connection addRequest:self.sampleRequest
                   completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
                     TestSDKError *testError = (TestSDKError *)error;
                     XCTAssertEqual(
                       testError.type,
                       ErrorTypeUnknown,
                       @"Starting a graph request before the SDK is initialized should return an unknown-type error"
                     );
                     XCTAssertEqualObjects(
                       testError.message,
                       expectedMessage,
                       @"Starting a graph request before the SDK is initialized should return an error with the appropriate mesage"
                     );
                     XCTAssertEqual(
                       weakSelf.connection.state,
                       kStateCancelled,
                       @"Starting a graph request before the SDK is initialized should update the connection state"
                     );
                     completionWasCalled = YES;
                   }];
  [self.connection start];

  XCTAssertEqualObjects(
    TestLogger.capturedLogEntry,
    expectedMessage,
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
  self.connection.logger = [self createLogger];

  NSArray *states = @[@(kStateStarted), @(kStateCancelled), @(kStateCompleted)];
  for (NSNumber *state in states) {
    self.connection.state = kStateCreated;
    [self.connection addRequest:self.sampleRequest
                     completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
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
                     completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
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
                   completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
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
                   completion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {}];
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
  NSDictionary<NSString *, id> *result = @{
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
  id<FBSDKGraphRequest> capturedRequest = (id<FBSDKGraphRequest>)self.errorConfiguration.capturedGraphRequest;

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
  NSDictionary<NSString *, id> *response = @{
    @"body" : @{
      @"error" : @{ @"error_msg" : @"error_msg" }
    }
  };
  TestSDKError *error = (TestSDKError *)[self.connection errorFromResult:response request:self.sampleRequest];
  XCTAssertEqualObjects(
    error.message,
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
  error = (TestSDKError *)[self.connection errorFromResult:response request:self.sampleRequest];
  XCTAssertEqualObjects(
    error.message,
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
  error = (TestSDKError *)[self.connection errorFromResult:response request:self.sampleRequest];
  XCTAssertEqualObjects(
    error.message,
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
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
                     // make sure there is no recovery info for client token failures.
                     XCTAssertNil(error.localizedRecoverySuggestion);
                     [expectation fulfill];
                   }];
  [self.connection start];

  NSData *data = [@"{\"error\": {\"message\": \"Token is broken\",\"code\": 190,\"error_subcode\": 463, \"type\":\"OAuthException\"}}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);
  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testClientTokenSkipped
{
  XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:self.name];

  self.errorConfigurationProvider.configuration = nil;
  [self.connection addRequest:self.requestForMeWithEmptyFields completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
    // make sure there is no recovery info for client token failures.
    XCTAssertNil(error.localizedRecoverySuggestion);
    [expectation fulfill];
  }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);
  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testConnectionDelegate
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  __block int actualCallbacksCount = 0;
  [self.connection addRequest:[[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
                   completion:^(id<FBSDKGraphRequestConnecting> conn, id result, NSError *error) {
                     XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
                   }];
  [self.connection addRequest:[[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
                   completion:^(id<FBSDKGraphRequestConnecting> conn, id result, NSError *error) {
                     XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
                   }];
  self.requestConnectionStartingCallback = ^(id<FBSDKGraphRequestConnecting> conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(id<FBSDKGraphRequestConnecting> conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  self.connection.delegate = self;
  [self.connection start];

  NSString *meResponse = [@"{ \"id\":\"userid\"}" stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
  NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": \"%@\" }, {\"code\":200,\"body\": \"%@\" } ]", meResponse, meResponse];
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:200 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testNonErrorEmptyDictionaryOrNullResponse
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  __block int actualCallbacksCount = 0;
  [self.connection addRequest:[[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
                   completion:^(id<FBSDKGraphRequestConnecting> conn, id result, NSError *error) {
                     XCTAssertEqual(1, actualCallbacksCount++, @"this should have been the second callback");
                   }];
  [self.connection addRequest:[[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
                   completion:^(id<FBSDKGraphRequestConnecting> conn, id result, NSError *error) {
                     XCTAssertEqual(2, actualCallbacksCount++, @"this should have been the third callback");
                   }];
  self.requestConnectionStartingCallback = ^(id<FBSDKGraphRequestConnecting> conn) {
    NSCAssert(0 == actualCallbacksCount++, @"this should have been the first callback");
  };
  self.requestConnectionCallback = ^(id<FBSDKGraphRequestConnecting> conn, NSError *error) {
    NSCAssert(error == nil, @"unexpected error:%@", error);
    NSCAssert(3 == actualCallbacksCount++, @"this should have been the fourth callback");
    [expectation fulfill];
  };
  self.connection.delegate = self;
  [self.connection start];

  NSString *responseString = [NSString stringWithFormat:@"[ {\"code\":200,\"body\": null }, {\"code\":200,\"body\": {} } ]"];
  NSData *data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:200 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testConnectionDelegateWithNetworkError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self.connection addRequest:[[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}]
                   completion:^(id<FBSDKGraphRequestConnecting> conn, id result, NSError *error) {}];
  self.requestConnectionCallback = ^(id<FBSDKGraphRequestConnecting> conn, NSError *error) {
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
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
  TestAccessTokenWallet.currentAccessToken = accessToken;

  [self.connection addRequest:[self requestWithTokenString:accessToken.tokenString]
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
                     XCTAssertNil(result);
                     TestSDKError *testError = (TestSDKError *)error;
                     XCTAssertEqualObjects(@"Token is broken", testError.message);
                     XCTAssertNil(
                       TestAccessTokenWallet.currentAccessToken,
                       "Should clear the current stored access token"
                     );
                     [expectation fulfill];
                   }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testUnsettingAccessTokenSkipped
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];

  TestAccessTokenWallet.currentAccessToken = accessToken;

  id<FBSDKGraphRequest> request = [[TestGraphRequest alloc] initWithGraphPath:@"me"
                                                                   parameters:@{@"fields" : @""}
                                                                  tokenString:@"notCurrentToken"];
  [self.connection addRequest:request completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
    XCTAssertNil(result);
    TestSDKError *testError = (TestSDKError *)error;
    XCTAssertEqualObjects(@"Token is broken", testError.message);
    XCTAssertNotNil(TestAccessTokenWallet.currentAccessToken);
    [expectation fulfill];
  }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testUnsettingAccessTokenFlag
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];
  FBSDKAccessToken *accessToken = [[FBSDKAccessToken alloc] initWithTokenString:@"token"
                                                                    permissions:@[@"public_profile"]
                                                            declinedPermissions:@[]
                                                             expiredPermissions:@[]
                                                                          appID:@"appid"
                                                                         userID:@"userid"
                                                                 expirationDate:nil
                                                                    refreshDate:nil
                                                       dataAccessExpirationDate:nil];
  TestAccessTokenWallet.currentAccessToken = accessToken;

  id<FBSDKGraphRequest> request = [[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""} flags:FBSDKGraphRequestFlagDoNotInvalidateTokenOnError];
  [self.connection addRequest:request completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
    XCTAssertNil(result);
    TestSDKError *testError = (TestSDKError *)error;
    XCTAssertEqualObjects(@"Token is broken", testError.message);
    XCTAssertNotNil(TestAccessTokenWallet.currentAccessToken);
    [expectation fulfill];
  }];
  [self.connection start];

  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(self.missingTokenData, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRequestWithUserAgentSuffix
{
  self.settings.userAgentSuffix = @"UnitTest.1.0.0";

  [self.connection addRequest:self.requestForMeWithEmptyFields
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {}];
  [self.connection start];

  NSString *userAgent = [self.session.capturedRequest valueForHTTPHeaderField:@"User-Agent"];
  XCTAssertTrue([userAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", userAgent);
}

- (void)testRequestWithoutUserAgentSuffix
{
  self.settings.userAgentSuffix = nil;

  [self.connection addRequest:self.requestForMeWithEmptyFields
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {}];
  [self.connection start];

  NSString *userAgent = [self.session.capturedRequest valueForHTTPHeaderField:@"User-Agent"];
  XCTAssertFalse([userAgent hasSuffix:@"/UnitTest.1.0.0"], @"unexpected user agent %@", userAgent);
}

- (void)testRequestWithMacCatalystUserAgent
{
  self.macCatalystDeterminator.stubbedIsMacCatalystApp = YES;
  self.settings.userAgentSuffix = nil;

  [self.connection addRequest:self.requestForMeWithEmptyFields
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {}];
  [self.connection start];

  NSString *userAgent = [self.session.capturedRequest valueForHTTPHeaderField:@"User-Agent"];
  XCTAssertTrue([userAgent hasSuffix:@"/macOS"], @"unexpected user agent %@", userAgent);
}

- (void)testNonDictionaryInError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  [self.connection addRequest:self.requestForMeWithEmptyFields
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
                     // should not crash when receiving something other than a dictionary within the response.
                     [expectation fulfill];
                   }];
  [self.connection start];

  NSData *data = [@"{\"error\": \"a-non-dictionary\"}" dataUsingEncoding:NSUTF8StringEncoding];
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:200 HTTPVersion:nil headerFields:nil];

  self.session.capturedCompletion(data, response, nil);

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRequestWithBatchConstructionWithSingleGetRequest
{
  id<FBSDKGraphRequest> singleRequest = [[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"with_suffix"}];
  [self.connection addRequest:singleRequest completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {}];
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
  NSDictionary<NSString *, id> *parameters = @{
    @"first_key" : @"first_value",
  };
  id<FBSDKGraphRequest> singleRequest = [[TestGraphRequest alloc] initWithGraphPath:@"activities" parameters:parameters HTTPMethod:FBSDKHTTPMethodPOST];
  [self.connection addRequest:singleRequest completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {}];
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
  id<FBSDKGraphRequest> request = [[TestGraphRequest alloc] initWithGraphPath:@"me"
                                                                   parameters:@{@"fields" : @""}
                                                                  tokenString:expectedToken
                                                                   HTTPMethod:FBSDKHTTPMethodGET
                                                                        flags:FBSDKGraphRequestFlagNone];
  NSString *token = [self.connection accessTokenWithRequest:request];
  XCTAssertEqualObjects(token, expectedToken);
}

- (void)testAccessTokenWithRequestWithoutFacebookClientToken
{
  self.connection.logger = [self createLogger];
  [self.connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  XCTAssertEqual(
    TestLogger.capturedLoggingBehavior,
    FBSDKLoggingBehaviorDeveloperErrors,
    "Should log a developer error when a request is started with no client token set"
  );
  XCTAssertEqualObjects(
    TestLogger.capturedLogEntry,
    @"Starting with v13 of the SDK, a client token must be embedded in your client code before making Graph API calls. Visit https://developers.facebook.com/docs/ios/getting-started#step-3---configure-your-project to learn how to implement this change.",
    "Should log the expected error message when a request is started with no client token set"
  );

  [TestLogger reset];

  [self.connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  XCTAssertEqual(
    TestLogger.capturedLoggingBehavior,
    FBSDKLoggingBehaviorDeveloperErrors,
    "Should log consistently for requests started with no client token set"
  );
}

- (void)testAccessTokenWithRequestWithFacebookClientToken
{
  self.connection.logger = [self createLogger];
  NSString *clientToken = @"client_token";
  self.settings.clientToken = clientToken;
  NSString *token = [self.connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  NSString *expectedToken = [NSString stringWithFormat:@"%@|%@", self.appID, clientToken];
  XCTAssertEqualObjects(token, expectedToken);

  XCTAssertNil(
    TestLogger.capturedLoggingBehavior,
    "Should not log a developer error when a request is started with a client token set"
  );
}

- (void)testAccessTokenWithRequestWithGamingClientToken
{
  NSString *clientToken = @"client_token";
  self.settings.clientToken = clientToken;
  FBSDKAuthenticationToken *authToken = [[FBSDKAuthenticationToken alloc] initWithTokenString:@"token_string"
                                                                                        nonce:@"nonce"
                                                                                  graphDomain:@"gaming"];
  TestAuthenticationTokenWallet.currentAuthenticationToken = authToken;
  NSString *token = [self.connection accessTokenWithRequest:self.requestForMeWithEmptyFieldsNoTokenString];

  NSString *expectedToken = [NSString stringWithFormat:@"GG|%@|%@", self.appID, clientToken];
  XCTAssertEqualObjects(token, expectedToken);

  FBSDKAuthenticationToken.currentAuthenticationToken = nil;
}

#pragma mark - Error recovery.

- (void)testRetryWithTransientError
{
  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  FBSDKSettings.sharedSettings.isGraphErrorRecoveryEnabled = YES;

  self.errorRecoveryConfiguration = self.transientErrorRecoveryConfiguration;
  self.errorConfiguration.stubbedRecoveryConfiguration = self.errorRecoveryConfiguration;
  self.errorConfigurationProvider.configuration = self.errorConfiguration;
  id<FBSDKGraphRequestConnecting> retryConnection = [FBSDKGraphRequestConnection new];
  self.graphRequestConnectionFactory.stubbedConnection = retryConnection;

  __block int completionCallCount = 0;
  [self.connection addRequest:self.requestForMeWithEmptyFields
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
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
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

  // The first captured completion will be invoked and cause the retry
  self.session.capturedCompletion(data, response, nil);

  // It's necessary to dispatch async to avoid the completion from being invoked before it is captured
  dispatch_async(dispatch_get_main_queue(), ^{
    NSData *secondData = [@"{\"error\": {\"message\": \"Server is busy\",\"code\": 2,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
    self.secondSession.capturedCompletion(secondData, response, nil);
  });

  [self waitForExpectations:@[expectation] timeout:1];
}

- (void)testRetryDisabled
{
  FBSDKSettings.sharedSettings.isGraphErrorRecoveryEnabled = NO;

  XCTestExpectation *expectation = [self expectationWithDescription:self.name];

  __block int completionCallCount = 0;
  [self.connection addRequest:self.requestForMeWithEmptyFields
                   completion:^(id<FBSDKGraphRequestConnecting> potentialConnection, id result, NSError *error) {
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
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL new] statusCode:400 HTTPVersion:nil headerFields:nil];

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
  self.connection.logger = [self createLogger];
  NSArray *entries = @[
    @"message1 Link: link1",
    @"message2 Link: link2"
  ];
  [self.connection processResultBody:self.debugResponse error:nil metadata:self.metadata canNotifyDelegate:NO];
  XCTAssertEqualObjects(
    TestLogger.capturedLogEntries,
    entries,
    "Should log entries from the debug dictionary"
  );
}

- (void)testProcessingResultBodyWithRandomizedDebugDictionary
{
  for (int i = 1; i < 100; i++) {
    NSDictionary<NSString *, id> *body = [Fuzzer randomizeWithJson:self.debugResponse];
    [self.connection processResultBody:body error:nil metadata:self.metadata canNotifyDelegate:NO];
  }
}

- (void)testLogRequestWithInactiveLogger
{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.sampleUrl];
  TestLogger *logger = [self createLogger];
  TestLogger *bodyLogger = [self createLogger];
  TestLogger *attachmentLogger = [self createLogger];
  self.connection.logger = logger;
  [self.connection logRequest:request bodyLength:1024 bodyLogger:bodyLogger attachmentLogger:attachmentLogger];

  XCTAssertEqualObjects(logger.capturedAppendedKeys, @[]);
  XCTAssertEqualObjects(logger.capturedAppendedValues, @[]);
}

- (void)testLogRequestWithActiveLogger
{
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.sampleUrl];
  [request addValue:@"user agent" forHTTPHeaderField:@"User-Agent"];
  [request addValue:@"content type" forHTTPHeaderField:@"Content-Type"];
  TestLogger *logger = [self createLogger];
  TestLogger *bodyLogger = [self createLogger];
  TestLogger *attachmentLogger = [self createLogger];

  // Start with some previously 'logged' contents
  bodyLogger.capturedContents = @"bodyContents";
  attachmentLogger.capturedContents = @"attachmentLoggerContents";
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
    @"user agent",
    @"content type",
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
  [self.connection URLSession:NSURLSession.sharedSession
                         task:[NSURLSessionDataTask new]
              didSendBodyData:0
               totalBytesSent:0
     totalBytesExpectedToSend:0];

  XCTAssertTrue(
    self.didInvokeDelegateRequestConnectionDidSendBodyData,
    "The url session data delegate should pass through to the graph request connection delegate"
  );
}

// MARK: - Helpers

- (TestLogger *)createLogger
{
  return [[TestLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
}

- (id<FBSDKGraphRequest>)sampleRequest
{
  return self.requestForMeWithEmptyFields;
}

- (id<FBSDKGraphRequest>)sampleRequestWithParameters:(NSDictionary<NSString *, id> *)parameters
{
  return [[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters];
}

- (id<FBSDKGraphRequest>)requestForMeWithEmptyFields
{
  return [[TestGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @""}];
}

- (id<FBSDKGraphRequest>)requestForMeWithEmptyFieldsNoTokenString
{
  return [[TestGraphRequest alloc] initWithGraphPath:@"me"
                                          parameters:@{@"fields" : @""}
                                               flags:FBSDKGraphRequestFlagNone];
}

- (id<FBSDKGraphRequest>)requestWithTokenString:(NSString *)tokenString
{
  return [[TestGraphRequest alloc] initWithGraphPath:@"me"
                                          parameters:@{@"fields" : @""}
                                         tokenString:tokenString];
}

- (FBSDKGraphRequestMetadata *)metadataWithRequest:(id<FBSDKGraphRequest>)request
{
  return [[FBSDKGraphRequestMetadata alloc] initWithRequest:request
                                          completionHandler:nil
                                            batchParameters:@{}];
}

- (NSData *)missingTokenData
{
  return [@"{\"error\": {\"message\": \"Token is broken\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary<NSString *, id> *)sampleErrorDictionary
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

- (NSDictionary<NSString *, id> *)debugResponse
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

- (FBSDKGraphRequestMetadata *)createSampleMetadata
{
  return [[FBSDKGraphRequestMetadata alloc] initWithRequest:self.sampleRequest
                                          completionHandler:nil
                                            batchParameters:nil];
}

@end
