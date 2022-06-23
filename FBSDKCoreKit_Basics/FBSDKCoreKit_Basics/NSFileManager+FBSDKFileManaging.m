//
//  FBSDKFileManaging.m
//  FBSDKCoreKit_Basics-Dynamic
//
//  Created by Sam Odom on 6/21/22.
//  Copyright © 2022 Facebook. All rights reserved.
//

#import <FBSDKCoreKit_Basics/FBSDKFileManaging.h>

#import <Foundation/Foundation.h>

@implementation NSFileManager (FBSDKFileManaging)

- (BOOL)fb_createDirectoryAtPath:(NSString *)path
     withIntermediateDirectories:(BOOL)createIntermediates
                      attributes:(NSDictionary<NSFileAttributeKey,id> *)attributes
                           error:(NSError * _Nullable __autoreleasing *)error
{
  return [self createDirectoryAtPath:path
         withIntermediateDirectories:createIntermediates
                          attributes:attributes
                               error:error];
}

- (BOOL)fb_fileExistsAtPath:(NSString *)path
{
  return [self fileExistsAtPath:path];
}

- (BOOL)fb_removeItemAtPath:(NSString *)path
                      error:(NSError * _Nullable __autoreleasing *)error
{
  return [self removeItemAtPath:path error:error];
}

- (NSArray<NSString *> *)fb_contentsOfDirectoryAtPath:(NSString *)path
                                                error:(NSError * _Nullable __autoreleasing *)error
{
  return [self contentsOfDirectoryAtPath:path error:error];
}

@end
