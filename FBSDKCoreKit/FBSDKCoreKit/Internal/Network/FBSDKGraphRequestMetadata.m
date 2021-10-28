/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKGraphRequestMetadata.h"

#import "FBSDKGraphRequestProtocol.h"

@implementation FBSDKGraphRequestMetadata

- (instancetype)initWithRequest:(id<FBSDKGraphRequest>)request
              completionHandler:(FBSDKGraphRequestCompletion)handler
                batchParameters:(NSDictionary<NSString *, id> *)batchParameters
{
  if ((self = [super init])) {
    _request = request;
    _batchParameters = [batchParameters copy];
    _completionHandler = [handler copy];
  }
  return self;
}

- (void)invokeCompletionHandlerForConnection:(id<FBSDKGraphRequestConnecting>)connection
                                 withResults:(id)results
                                       error:(nullable NSError *)error
{
  if (self.completionHandler) {
    self.completionHandler(connection, results, error);
  }
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: %p, batchParameters: %@, completionHandler: %@, request: %@>",
          NSStringFromClass(self.class),
          self,
          self.batchParameters,
          self.completionHandler,
          self.request.formattedDescription];
}

@end
