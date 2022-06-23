//
//  NSURLSession+NSURLSession_FBSDKSessionProviding.h
//  FBSDKCoreKit_Basics
//
//  Created by Sam Odom on 6/21/22.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import <FBSDKCoreKit_Basics/FBSDKURLSessionProviding.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSURLSession (URLSessionProviding)

- (id<FBSDKNetworkTask>)fb_dataTaskWithRequest:(NSURLRequest *)request
                             completionHandler:(void (^)(NSData * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
{
  return [self dataTaskWithRequest:request completionHandler:completionHandler];
}

@end

NS_ASSUME_NONNULL_END
