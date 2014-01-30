/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

@interface FBCrypto : NSObject

/**
 * Generate numOfBytes random data
 * This calls the system-provided function SecRandomCopyBytes, based on /dev/random.
 */
+ (NSData *)randomBytes:(NSUInteger)numOfBytes;

/**
 * Generate a fresh master key using SecRandomCopyBytes, the result is encoded in base64
 */
+ (NSString *)makeMasterKey;

/**
 * Initialize with a base64-encoded master key.
 * This key and the current derivation function will be used to generate the encryption key and the mac key.
 */
- (instancetype)initWithMasterKey:(NSString *)masterKey;

/**
 * Initialize with base64-encoded encryption key and mac key
 */
- (instancetype)initWithEncryptionKey:(NSString *)encryptionKey macKey:(NSString *)macKey;

/**
 * Encrypt plainText and return the base64 encoded result. MAC computation involves additionalDataToSign
 */
- (NSString *)encrypt:(NSData *)plainText additionalDataToSign:(NSData *)additionalDataToSign;

/**
 * Decrypt base64EncodedCipherText. MAC computation involves additionalSignedData
 */
- (NSData *)decrypt:(NSString *)base64EncodedCipherText additionalSignedData:(NSData *)additionalSignedData;

@end
