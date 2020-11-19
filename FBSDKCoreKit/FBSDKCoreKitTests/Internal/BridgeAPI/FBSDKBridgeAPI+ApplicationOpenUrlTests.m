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

#import "FBSDKBridgeAPITests.h"

@implementation FBSDKBridgeAPITests (ApplicationOpenURLTests)

// MARK: - Url Opening

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:YES
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:YES
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:NO
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:YES
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_ShouldStopPropagationPendingUrlCannotOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:YES
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:YES
                   isDismissingSafariViewController:NO
                 authSessionCompletionHandlerExists:YES
                         canHandleBridgeApiResponse:NO
                expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:YES
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
                      hasSafariViewController:NO
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                  expectedAuthCancelCallCount:1
                 expectedIsDismissingSafariVc:NO
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:YES
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:NO
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:NO];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:YES
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCanOpenUrlWithSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenUrlWithPendingUrlCanOpenUrl:YES
             isDismissingSafariViewController:NO
           authSessionCompletionHandlerExists:YES
                   canHandleBridgeApiResponse:NO
                 expectedIsDismissingSafariVc:YES
          expectedAuthSessionCompletionExists:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:YES
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhileDismissingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:YES
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:YES
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithoutAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:NO
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerAbleToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:YES
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:YES];
}

- (void)testOpenUrl_PendingUrlCannotOpenUrlWithoutSafariVcWhilePresentingSafariVcWithAuthSessionCompletionHandlerUnableToHandleBridgeApiResponse
{
  [self verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:NO
                                     authSessionCompletionHandlerExists:YES
                                             canHandleBridgeApiResponse:NO
                                           expectedIsDismissingSafariVc:NO
                                    expectedAuthSessionCompletionExists:NO
                                                    expectedReturnValue:NO];
}

// MARK: - Helpers

/// Assumes should not stop propagation of url
/// Assumes SafariViewController is not nil
- (void)verifyOpenUrlWithPendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
             isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
           authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                 expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
          expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:NO
                               pendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                            hasSafariViewController:YES
                   isDismissingSafariViewController:isDismissingSafariViewController
                 authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:canHandleBridgeApiResponse
            expectedAuthSessionCompletionHandlerUrl:nil
          expectedAuthSessionCompletionHandlerError:nil
          expectAuthSessionCompletionHandlerInvoked:NO
                        expectedAuthCancelCallCount:0
                          expectedAuthSessionExists:YES
                expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                              expectedCanOpenUrlUrl:self.sampleUrl
                           expectedCanOpenUrlSource:sampleSource
                       expectedCanOpenUrlAnnotation:sampleAnnotation
                                 expectedOpenUrlUrl:nil
                              expectedOpenUrlSource:nil
                          expectedOpenUrlAnnotation:nil
                       expectedPendingUrlOpenExists:YES
                       expectedIsDismissingSafariVc:expectedIsDismissingSafariVc
                             expectedSafariVcExists:NO
                                expectedReturnValue:YES];
}

/// Assumes should not stop propagation of url
/// Assumes Pending Url cannot open
/// Assumes SafariViewController is nil
- (void)verifyOpenURLWithoutSafariVcWhileDismissingSafariViewController:(BOOL)isDismissingSafariViewController
                                     authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                                             canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                                           expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
                                    expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
                                                    expectedReturnValue:(BOOL)expectedReturnValue
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:NO
                               pendingUrlCanOpenUrl:NO
                            hasSafariViewController:NO
                   isDismissingSafariViewController:isDismissingSafariViewController
                 authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:canHandleBridgeApiResponse
            expectedAuthSessionCompletionHandlerUrl:self.sampleUrl
          expectedAuthSessionCompletionHandlerError:self.loginInterruptionError
          expectAuthSessionCompletionHandlerInvoked:YES
                        expectedAuthCancelCallCount:1
                          expectedAuthSessionExists:NO
                expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                              expectedCanOpenUrlUrl:self.sampleUrl
                           expectedCanOpenUrlSource:sampleSource
                       expectedCanOpenUrlAnnotation:sampleAnnotation
                                 expectedOpenUrlUrl:self.sampleUrl
                              expectedOpenUrlSource:sampleSource
                          expectedOpenUrlAnnotation:sampleAnnotation
                       expectedPendingUrlOpenExists:NO
                       expectedIsDismissingSafariVc:expectedIsDismissingSafariVc
                             expectedSafariVcExists:NO
                                expectedReturnValue:expectedReturnValue];
}

/// Assumes should not stop propagation of url
- (void)verifyOpenUrlWithPendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                      hasSafariViewController:(BOOL)hasSafariViewController
             isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
           authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                   canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                  expectedAuthCancelCallCount:(int)expectedAuthCancelCallCount
                 expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
          expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:NO
                               pendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                            hasSafariViewController:hasSafariViewController
                   isDismissingSafariViewController:isDismissingSafariViewController
                 authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:canHandleBridgeApiResponse
            expectedAuthSessionCompletionHandlerUrl:nil
          expectedAuthSessionCompletionHandlerError:nil
          expectAuthSessionCompletionHandlerInvoked:NO
                        expectedAuthCancelCallCount:expectedAuthCancelCallCount
                          expectedAuthSessionExists:NO
                expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                              expectedCanOpenUrlUrl:self.sampleUrl
                           expectedCanOpenUrlSource:sampleSource
                       expectedCanOpenUrlAnnotation:sampleAnnotation
                                 expectedOpenUrlUrl:self.sampleUrl
                              expectedOpenUrlSource:sampleSource
                          expectedOpenUrlAnnotation:sampleAnnotation
                       expectedPendingUrlOpenExists:NO
                       expectedIsDismissingSafariVc:expectedIsDismissingSafariVc
                             expectedSafariVcExists:hasSafariViewController
                                expectedReturnValue:YES];
}

- (void)verifyOpenUrlWithShouldStopPropagationOfUrl:(BOOL)shouldStopPropagationOfURL
                               pendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                            hasSafariViewController:(BOOL)hasSafariViewController
                   isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
                 authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:shouldStopPropagationOfURL
                               pendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                            hasSafariViewController:hasSafariViewController
                   isDismissingSafariViewController:isDismissingSafariViewController
                 authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:canHandleBridgeApiResponse
            expectedAuthSessionCompletionHandlerUrl:nil
          expectedAuthSessionCompletionHandlerError:nil
          expectAuthSessionCompletionHandlerInvoked:NO
                        expectedAuthCancelCallCount:0
                          expectedAuthSessionExists:YES
                expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                              expectedCanOpenUrlUrl:nil
                           expectedCanOpenUrlSource:nil
                       expectedCanOpenUrlAnnotation:nil
                                 expectedOpenUrlUrl:nil
                              expectedOpenUrlSource:nil
                          expectedOpenUrlAnnotation:nil
                       expectedPendingUrlOpenExists:YES
                       expectedIsDismissingSafariVc:isDismissingSafariViewController // Should not change the value
                             expectedSafariVcExists:hasSafariViewController
                                expectedReturnValue:YES];
}

/// Assumes SafariViewController is nil
- (void)verifyOpenUrlWithShouldStopPropagationOfUrl:(BOOL)shouldStopPropagationOfURL
                               pendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                   isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
                 authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
                expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
{
  [self verifyOpenUrlWithShouldStopPropagationOfUrl:shouldStopPropagationOfURL
                               pendingUrlCanOpenUrl:pendingUrlCanOpenUrl
                            hasSafariViewController:NO
                   isDismissingSafariViewController:isDismissingSafariViewController
                 authSessionCompletionHandlerExists:authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:canHandleBridgeApiResponse
            expectedAuthSessionCompletionHandlerUrl:nil
          expectedAuthSessionCompletionHandlerError:nil
          expectAuthSessionCompletionHandlerInvoked:NO
                        expectedAuthCancelCallCount:0
                          expectedAuthSessionExists:YES
                expectedAuthSessionCompletionExists:expectedAuthSessionCompletionExists
                              expectedCanOpenUrlUrl:nil
                           expectedCanOpenUrlSource:nil
                       expectedCanOpenUrlAnnotation:nil
                                 expectedOpenUrlUrl:nil
                              expectedOpenUrlSource:nil
                          expectedOpenUrlAnnotation:nil
                       expectedPendingUrlOpenExists:YES
                       expectedIsDismissingSafariVc:isDismissingSafariViewController // Should not change this value
                             expectedSafariVcExists:NO
                                expectedReturnValue:YES];
}

- (void)verifyOpenUrlWithShouldStopPropagationOfUrl:(BOOL)shouldStopPropagationOfURL
                               pendingUrlCanOpenUrl:(BOOL)pendingUrlCanOpenUrl
                            hasSafariViewController:(BOOL)hasSafariViewController
                   isDismissingSafariViewController:(BOOL)isDismissingSafariViewController
                 authSessionCompletionHandlerExists:(BOOL)authSessionCompletionHandlerExists
                         canHandleBridgeApiResponse:(BOOL)canHandleBridgeApiResponse
            expectedAuthSessionCompletionHandlerUrl:(NSURL *)expectedAuthSessionCompletionHandlerUrl
          expectedAuthSessionCompletionHandlerError:(NSError *)expectedAuthSessionCompletionHandlerError
          expectAuthSessionCompletionHandlerInvoked:(BOOL)expectAuthSessionCompletionHandlerInvoked
                        expectedAuthCancelCallCount:(int)expectedAuthCancelCallCount
                          expectedAuthSessionExists:(BOOL)expectedAuthSessionExists
                expectedAuthSessionCompletionExists:(BOOL)expectedAuthSessionCompletionExists
                              expectedCanOpenUrlUrl:(NSURL *)expectedCanOpenUrlCalledWithUrl
                           expectedCanOpenUrlSource:(NSString *)expectedCanOpenUrlSource
                       expectedCanOpenUrlAnnotation:(NSString *)expectedCanOpenUrlAnnotation
                                 expectedOpenUrlUrl:(NSURL *)expectedOpenUrlUrl
                              expectedOpenUrlSource:(NSString *)expectedOpenUrlSource
                          expectedOpenUrlAnnotation:(NSString *)expectedOpenUrlAnnotation
                       expectedPendingUrlOpenExists:(BOOL)expectedPendingUrlOpenExists
                       expectedIsDismissingSafariVc:(BOOL)expectedIsDismissingSafariVc
                             expectedSafariVcExists:(BOOL)expectedSafariVcExists
                                expectedReturnValue:(BOOL)expectedReturnValue
{
  FBSDKLoginManager *urlOpener = [FBSDKLoginManager new];
  AuthenticationSessionSpy *authSessionSpy = [[AuthenticationSessionSpy alloc] initWithURL:self.sampleUrl
                                                                         callbackURLScheme:nil
                                                                         completionHandler:^(NSURL *_Nullable callbackURL, NSError *_Nullable error) {
                                                                           XCTFail("Should not invoke the completion for the authentication session");
                                                                         }];
  [urlOpener stubShouldStopPropagationOfURL:self.sampleUrl withValue:shouldStopPropagationOfURL];
  urlOpener.stubbedCanOpenUrl = pendingUrlCanOpenUrl;

  self.api.pendingUrlOpen = urlOpener;

  if (hasSafariViewController) {
    ViewControllerSpy *viewControllerSpy = ViewControllerSpy.makeDefaultSpy;
    self.api.safariViewController = viewControllerSpy;
  }
  self.api.isDismissingSafariViewController = isDismissingSafariViewController;
  self.api.authenticationSessionState = FBSDKAuthenticationSessionNone;
  self.api.pendingRequest = self.sampleBridgeApiRequest;
  self.api.authenticationSession = authSessionSpy;
  if (authSessionCompletionHandlerExists) {
    self.api.authenticationSessionCompletionHandler = ^(NSURL *callbackURL, NSError *error) {
      if (!expectAuthSessionCompletionHandlerInvoked) {
        XCTFail("Should not invoke the authentication session completion handler");
      }
      XCTAssertEqualObjects(
        callbackURL,
        expectedAuthSessionCompletionHandlerUrl,
        "Should invoke the authentication session completion handler with the expected URL"
      );
      XCTAssertEqualObjects(
        error,
        expectedAuthSessionCompletionHandlerError,
        "Should invoke the authentication session completion handler with the expected error"
      );
    };
  }
  self.api.pendingRequestCompletionBlock = ^(FBSDKBridgeAPIResponse *response) {
    XCTFail("Should not invoke the pending request completion block");
  };
  [self stubHandleBridgeApiResponseAndReturn:canHandleBridgeApiResponse];

  BOOL returnValue = [self.api application:UIApplication.sharedApplication
                                   openURL:self.sampleUrl
                         sourceApplication:sampleSource
                                annotation:sampleAnnotation];
  XCTAssertEqual(
    returnValue,
    expectedReturnValue,
    "The return value for the overall method should be %@",
    StringFromBool(expectedReturnValue)
  );
  if (expectedAuthSessionExists) {
    XCTAssertNotNil(self.api.authenticationSession, "The authentication session should not be nil");
  } else {
    XCTAssertNil(self.api.authenticationSession, "The authentication session should be nil");
  }
  if (expectedAuthSessionCompletionExists) {
    XCTAssertNotNil(
      self.api.authenticationSessionCompletionHandler,
      "The authentication session completion handler should not be nil"
    );
  } else {
    XCTAssertNil(
      self.api.authenticationSessionCompletionHandler,
      "The authentication session completion handler should be nil"
    );
  }
  XCTAssertEqual(
    authSessionSpy.cancelCallCount,
    expectedAuthCancelCallCount,
    "The authentication session should be cancelled the expected number of times"
  );
  XCTAssertEqual(
    self.api.authenticationSessionState,
    FBSDKAuthenticationSessionNone,
    "The authentication session state should not change"
  );
  XCTAssertEqualObjects(
    urlOpener.capturedCanOpenUrl,
    expectedCanOpenUrlCalledWithUrl,
    "The url opener's can open url method should be called with the expected URL"
  );
  XCTAssertEqualObjects(
    urlOpener.capturedCanOpenSourceApplication,
    expectedCanOpenUrlSource,
    "The url opener's can open url method should be called with the expected source application"
  );
  XCTAssertEqualObjects(
    urlOpener.capturedCanOpenAnnotation,
    expectedCanOpenUrlAnnotation,
    "The url opener's can open url method should be called with the expected annotation"
  );

  XCTAssertEqualObjects(
    FBSDKLoginManager.capturedOpenUrl,
    expectedOpenUrlUrl,
    "The url opener's open url method should be called with the expected URL"
  );
  XCTAssertEqualObjects(
    FBSDKLoginManager.capturedSourceApplication,
    expectedOpenUrlSource,
    "The url opener's open url method should be called with the expected source application"
  );
  XCTAssertEqualObjects(
    FBSDKLoginManager.capturedAnnotation,
    expectedOpenUrlAnnotation,
    "The url opener's open url method should be called with the expected annotation"
  );

  XCTAssertNotNil(self.api.pendingRequest, "The pending request should not be nil");
  XCTAssertNotNil(self.api.pendingRequestCompletionBlock, "The pending request completion block should not be nil");
  if (expectedPendingUrlOpenExists) {
    XCTAssertNotNil(self.api.pendingUrlOpen, "The reference to the url opener should not be nil");
  } else {
    XCTAssertNil(self.api.pendingUrlOpen, "The reference to the url opener should be nil");
  }
  if (expectedSafariVcExists) {
    XCTAssertNotNil(self.api.safariViewController, "Safari view controller should not be nil");
  } else {
    XCTAssertNil(self.api.safariViewController, "Safari view controller should be nil");
  }
  XCTAssertEqual(
    self.api.isDismissingSafariViewController,
    expectedIsDismissingSafariVc,
    "Should set isDismissingSafariViewController to the expected value"
  );
}

/// Stubs `FBSDKBridgeAPI`'s `_handleBridgeAPIResponseURL:sourceApplication:` method to return the provided value
- (void)stubHandleBridgeApiResponseAndReturn:(BOOL)value
{
  OCMStub([self.partialMock _handleBridgeAPIResponseURL:OCMArg.any sourceApplication:OCMArg.any]).andReturn(value);
}

- (FBSDKBridgeAPIRequest *)sampleBridgeApiRequest
{
  return [FBSDKBridgeAPIRequest bridgeAPIRequestWithProtocolType:FBSDKBridgeAPIProtocolTypeWeb
                                                          scheme:@"https"
                                                      methodName:nil
                                                   methodVersion:nil
                                                      parameters:nil
                                                        userInfo:nil];
}

- (NSError *)loginInterruptionError
{
  NSString *errorMessage = [[NSString alloc]
                            initWithFormat:@"Login attempt cancelled by alternate call to openURL from: %@",
                            self.sampleUrl];
  return [[NSError alloc]
          initWithDomain:FBSDKErrorDomain
          code:FBSDKErrorBridgeAPIInterruption
          userInfo:@{FBSDKErrorLocalizedDescriptionKey : errorMessage}];
}

static inline NSString *StringFromBool(BOOL value)
{
  return value ? @"YES" : @"NO";
}

@end
