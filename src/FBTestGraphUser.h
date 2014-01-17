//
//  FBTestGraphUser.h
//  WithBuddiesCore
//
//  Created by odyth on 9/5/13.
//  Copyright (c) 2013 WithBuddies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBGraphObject.h"

@protocol FBTestGraphUser <FBGraphObject>

@property (nonatomic, readonly) NSString *id;
@property (nonatomic, readonly) NSString *access_token;
@property (nonatomic, readonly) NSString *login_url;
@property (nonatomic, readonly) NSString *email;
@property (nonatomic, readonly) NSString *password;
@property (nonatomic, retain) NSArray *friends;

@end