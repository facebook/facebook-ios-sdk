/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if TARGET_OS_TV

#import "FBSDKDeviceUtilities.h"

@implementation FBSDKDeviceUtilities

+ (UIImage *)buildQRCodeWithAuthorizationCode:(nullable NSString *)authorizationCode
{
  NSString *authorizationUri = @"https://facebook.com/device";
  if (authorizationCode.length > 0) {
    authorizationUri = [NSString stringWithFormat:@"https://facebook.com/device?user_code=%@&qr=1", authorizationCode];
  }
  NSData *qrCodeData = [authorizationUri dataUsingEncoding:NSISOLatin1StringEncoding];

  CIFilter *qrCodeFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
  [qrCodeFilter setValue:qrCodeData forKey:@"inputMessage"];
  [qrCodeFilter setValue:@"M" forKey:@"inputCorrectionLevel"];

  CIImage *qrCodeImage = qrCodeFilter.outputImage;
  CGRect qrImageSize = CGRectIntegral(qrCodeImage.extent);
  CGSize qrOutputSize = CGSizeMake(200, 200);

  CIImage *resizedImage =
  [qrCodeImage imageByApplyingTransform:CGAffineTransformMakeScale(
    qrOutputSize.width / CGRectGetWidth(qrImageSize),
    qrOutputSize.height / CGRectGetHeight(qrImageSize)
   )];

  return [UIImage imageWithCIImage:resizedImage];
}

@end

#endif
