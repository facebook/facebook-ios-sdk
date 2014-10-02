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

#import "FBDialogConfig.h"

@interface FBDialogConfig ()
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSURL *URL;
@property (nonatomic, copy, readwrite) NSArray *versions;
@end

@implementation FBDialogConfig

#pragma mark - Class Methods

+ (instancetype)dialogConfigWithDictionary:(NSDictionary *)dictionary
{
    FBDialogConfig *config = [[[FBDialogConfig alloc] init] autorelease];
    id temp;
    temp = dictionary[@"name"];
    if ([temp isKindOfClass:[NSString class]]) {
        config.name = (NSString *)temp;
    } else {
        return nil;
    }
    temp = dictionary[@"url"];
    if ([temp isKindOfClass:[NSString class]]) {
        config.URL = [NSURL URLWithString:(NSString *)temp];
    }
    temp = dictionary[@"versions"];
    if ([temp isKindOfClass:[NSArray class]]) {
        config.versions = (NSArray *)temp;
    }
    return config;
}

#pragma mark - Object Lifecycle

- (void)dealloc
{
    [_name release];
    [_URL release];
    [_versions release];
    [super dealloc];
}

#pragma mark - NSCoding

static NSString *const FBDialogConfigNameKey = @"name";
static NSString *const FBDialogConfigURLKey = @"url";
static NSString *const FBDialogConfigVersionKey = @"version";
static NSString *const FBDialogConfigVersionsKey = @"versions";
static NSInteger const FBDialogConfigCodingVersion = 1;

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        if ([decoder decodeIntegerForKey:FBDialogConfigVersionKey] != FBDialogConfigCodingVersion) {
            [self release];
            return nil;
        }

        _name = [[decoder decodeObjectOfClass:[NSString class] forKey:FBDialogConfigNameKey] retain];
        _URL = [[decoder decodeObjectOfClass:[NSURL class] forKey:FBDialogConfigURLKey] retain];
        _versions = [[decoder decodeObjectOfClass:[NSArray class] forKey:FBDialogConfigVersionsKey] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInteger:FBDialogConfigCodingVersion forKey:FBDialogConfigVersionKey];
    [coder encodeObject:_name forKey:FBDialogConfigNameKey];
    [coder encodeObject:_URL forKey:FBDialogConfigURLKey];
    [coder encodeObject:_versions forKey:FBDialogConfigVersionsKey];
}

@end
