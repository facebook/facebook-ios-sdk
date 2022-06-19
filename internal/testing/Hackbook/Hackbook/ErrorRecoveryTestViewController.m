// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ErrorRecoveryTestViewController.h"

#import <OHHTTPStubs/OHHTTPStubs.h>

#import "Console.h"

@interface ErrorRecoveryTestViewController ()
@end

@implementation ErrorRecoveryTestViewController

- (IBAction)loginRecoverableRequest:(id)sender
{
  [self markTestIncompleteWithSender:sender];
  [self ensureReadPermission:@"public_profile" usingBlock:^{
    [HTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 if ([request.URL.query rangeOfString:@"fields=middle_name,id"].location != NSNotFound) {
                   return YES;
                 }
                 return NO;
               } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"simulated expired token\",\"code\": 190,\"error_subcode\": 463}}" dataUsingEncoding:NSUTF8StringEncoding];
                 dispatch_async(dispatch_get_main_queue(), ^{
                   [HTTPStubs removeAllStubs];
                 });
                 return [HTTPStubsResponse responseWithData:data
                                                 statusCode:400
                                                    headers:nil];
               }];

    FBSDKGraphRequest *requestMe = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=middle_name,id" parameters:@{}];
    [requestMe startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
      if (result) {
        ConsoleLog(@"retry request fetched %@", result);
        [self markTestCompleteWithSender:sender];
      } else {
        ConsoleError(error, @"Error encountred - this is okay if you declined the login; otherwise it's a bug.");
      }
    }];
  }];
}

- (IBAction)retriableRequest:(id)sender
{
  [self markTestIncompleteWithSender:sender];
  [self ensureReadPermission:@"public_profile" usingBlock:^{
    [HTTPStubs stubRequestsPassingTest:^BOOL (NSURLRequest *request) {
                 if ([request.URL.query rangeOfString:@"fields=middle_name,id"].location != NSNotFound) {
                   return YES;
                 }
                 return NO;
               } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
                 NSData *data = [@"{\"error\": {\"message\": \"simulated server throttling\",\"code\": 1}}" dataUsingEncoding:NSUTF8StringEncoding];
                 dispatch_async(dispatch_get_main_queue(), ^{
                   [HTTPStubs removeAllStubs];
                 });
                 return [HTTPStubsResponse responseWithData:data
                                                 statusCode:400
                                                    headers:nil];
               }];

    FBSDKGraphRequest *requestMe = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me?fields=middle_name,id" parameters:@{}];
    [requestMe startWithCompletion:^(id<FBSDKGraphRequestConnecting> connection, id result, NSError *error) {
      if (result) {
        ConsoleLog(@"retry request fetched %@", result);
        [self markTestCompleteWithSender:sender];
      } else {
        ConsoleError(error, @"Unexpected Error.");
      }
    }];
  }];
}

@end
