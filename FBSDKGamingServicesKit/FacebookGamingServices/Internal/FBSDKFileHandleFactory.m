/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "FBSDKFileHandleFactory.h"

#import "NSFileHandle+FileHandling.h"

@implementation FBSDKFileHandleFactory

- (id<FBSDKFileHandling>)fileHandleForReadingFromURL:(NSURL *)url
                                               error:(NSError *__autoreleasing _Nullable *)error
{
  return [NSFileHandle fileHandleForReadingFromURL:url error:error];
}

@end
