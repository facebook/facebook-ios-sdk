/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIImage.h>

NS_ASSUME_NONNULL_BEGIN

@class FBSDKGraphRequestDataAttachment;
@class FBSDKLogger;

NS_SWIFT_NAME(GraphRequestBody)
@interface FBSDKGraphRequestBody : NSObject

@property (nonatomic, readonly, retain) NSData *data;

/**
  Determines whether to use multipart/form-data or application/json as the Content-Type.
  If binary attachments are added, this will default to YES.
 */
@property (nonatomic, assign) BOOL requiresMultipartDataFormat;

- (void)appendWithKey:(NSString *)key
            formValue:(NSString *)value
               logger:(nullable FBSDKLogger *)logger;

- (void)appendWithKey:(NSString *)key
           imageValue:(UIImage *)image
               logger:(nullable FBSDKLogger *)logger;

- (void)appendWithKey:(NSString *)key
            dataValue:(NSData *)data
               logger:(nullable FBSDKLogger *)logger;

- (void)appendWithKey:(NSString *)key
  dataAttachmentValue:(FBSDKGraphRequestDataAttachment *)dataAttachment
               logger:(nullable FBSDKLogger *)logger;

- (NSString *)mimeContentType;

- (nullable NSData *)compressedData;

@end

NS_ASSUME_NONNULL_END
