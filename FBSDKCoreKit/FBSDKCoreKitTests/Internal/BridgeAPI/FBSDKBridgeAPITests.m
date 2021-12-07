/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKBridgeAPITests.h"

@implementation FBSDKBridgeAPITests

- (void)setUp
{
  [super setUp];

  [FBSDKLoginManager resetTestEvidence];

  self.appURLSchemeProvider = [TestInternalUtility new];
  self.logger = [[TestLogger alloc] initWithLoggingBehavior:FBSDKLoggingBehaviorDeveloperErrors];
  self.urlOpener = [[TestInternalURLOpener alloc] initWithCanOpenUrl:YES];
  self.bridgeAPIResponseFactory = [TestBridgeAPIResponseFactory new];
  self.errorFactory = [TestErrorFactory new];

  [self configureSDK];

  self.api = [[FBSDKBridgeAPI alloc] initWithProcessInfo:[TestProcessInfo new]
                                                  logger:self.logger
                                               urlOpener:self.urlOpener
                                bridgeAPIResponseFactory:self.bridgeAPIResponseFactory
                                         frameworkLoader:self.frameworkLoader
                                    appURLSchemeProvider:self.appURLSchemeProvider
                                            errorFactory:self.errorFactory];
}

- (void)tearDown
{
  [FBSDKLoginManager resetTestEvidence];
  [TestLogger reset];

  [super tearDown];
}

- (void)configureSDK
{
  TestBackgroundEventLogger *backgroundEventLogger = [[TestBackgroundEventLogger alloc] initWithInfoDictionaryProvider:[TestBundle new]
                                                                                                           eventLogger:[TestAppEvents new]];
  TestServerConfigurationProvider *serverConfigurationProvider = [[TestServerConfigurationProvider alloc]
                                                                  initWithConfiguration:ServerConfigurationFixtures.defaultConfig];
  FBSDKApplicationDelegate *delegate = [[FBSDKApplicationDelegate alloc] initWithNotificationCenter:[TestNotificationCenter new]
                                                                                        tokenWallet:TestAccessTokenWallet.class
                                                                                           settings:[TestSettings new]
                                                                                     featureChecker:[TestFeatureManager new]
                                                                                          appEvents:[TestAppEvents new]
                                                                        serverConfigurationProvider:serverConfigurationProvider
                                                                                              store:[UserDefaultsSpy new]
                                                                          authenticationTokenWallet:TestAuthenticationTokenWallet.class
                                                                                    profileProvider:TestProfileProvider.class
                                                                              backgroundEventLogger:backgroundEventLogger
                                                                                    paymentObserver:[TestPaymentObserver new]];
  [delegate initializeSDKWithLaunchOptions:@{}];
}

// MARK: - Helpers

- (NSURL *)sampleUrl
{
  return [NSURL URLWithString:@"http://example.com"];
}

- (NSError *)sampleError
{
  return [NSError errorWithDomain:self.name code:0 userInfo:nil];
}

NSString *const sampleSource = @"com.example";
NSString *const sampleAnnotation = @"foo";

@end
