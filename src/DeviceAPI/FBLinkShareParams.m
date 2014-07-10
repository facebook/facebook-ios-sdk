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

#import "FBLinkShareParams.h"

#import "FBAppBridge.h"
#import "FBAppBridgeScheme.h"
#import "FBDialogsParams+Internal.h"
#import "FBError.h"
#import "FBInternalSettings.h"
#import "FBLogger.h"
#import "FBShareDialogParams.h"
#import "FBUtility.h"

@implementation FBShareDialogParams
@end

@implementation FBLinkShareParams

- (instancetype)initWithLink:(NSURL *)link
                        name:(NSString *)name
                     caption:(NSString *)caption
                 description:(NSString *)description
                     picture:(NSURL *)picture {
  if ((self = [super init])) {
    self.link = link;
    self.name = name;
    self.caption = caption;
    self.linkDescription = description;
    self.picture = picture;
  }
  return self;
}

- (void)dealloc
{
    [_link release];
    [_name release];
    [_caption release];
    [_linkDescription release];
    [_picture release];
    [_friends release];
    [_place release];
    [_ref release];

    [super dealloc];
}

- (NSDictionary *)dictionaryMethodArgs
{
    NSMutableDictionary *args = [NSMutableDictionary dictionary];
    if (self.link) {
        [args setObject:[self.link absoluteString] forKey:@"link"];
    }
    if (self.name) {
        [args setObject:self.name forKey:@"name"];
    }
    if (self.caption) {
        [args setObject:self.caption forKey:@"caption"];
    }
    if (self.linkDescription) {
        [args setObject:self.linkDescription forKey:@"description"];
    }
    if (self.picture) {
        [args setObject:[self.picture absoluteString] forKey:@"picture"];
    }
    if (self.friends) {
        NSMutableArray *tags = [NSMutableArray arrayWithCapacity:self.friends.count];
        for (id tag in self.friends) {
            [tags addObject:[FBUtility stringFBIDFromObject:tag]];
        }
        [args setObject:tags forKey:@"tags"];
    }
    if (self.place) {
        [args setObject:[FBUtility stringFBIDFromObject:self.place] forKey:@"place"];
    }
    if (self.ref) {
        [args setObject:self.ref forKey:@"ref"];
    }
    [args setObject:[NSNumber numberWithBool:self.dataFailuresFatal] forKey:@"dataFailuresFatal"];

    return args;
}

- (NSError *)validate {
    NSString *errorReason = nil;
    NSString *errorFailureReason = nil;

    if ((_link && ![FBAppBridgeScheme isSupportedScheme:_link.scheme]) ||
        (_picture && ![FBAppBridgeScheme isSupportedScheme:_picture.scheme])) {
        errorReason = FBErrorDialogInvalidShareParameters;
        errorFailureReason = @"Only http(s):// links are supported";
    }

    if (errorReason) {
        NSDictionary *userInfo = @{ FBErrorDialogReasonKey: errorReason,
                                    NSLocalizedFailureReasonErrorKey : errorFailureReason };
        return [NSError errorWithDomain:FacebookSDKDomain
                                   code:FBErrorDialog
                               userInfo:userInfo];
    }
    return nil;
}

+ (NSString *)methodName {
    return @"share";
}

- (void)setLink:(NSURL *)link
{
    [_link autorelease];
    if(link && ![FBAppBridgeScheme isSupportedScheme:link.scheme]) {
        _link = nil;
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                            logEntry:@"FBLinkShareParams: only \"http\" or \"https\" schemes are supported for link shares"];
    } else {
        _link = [link copy];
    }
}

- (void)setPicture:(NSURL *)picture
{
    [_picture autorelease];
    if (picture && ![FBAppBridgeScheme isSupportedScheme:picture.scheme]) {
        _picture = nil;
        [FBLogger singleShotLogEntry:FBLoggingBehaviorDeveloperErrors
                            logEntry:@"FBLinkShareParams: only \"http\" or \"https\" schemes are supported for link thumbnails"];
    } else {
        _picture = [picture copy];
    }
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone
{
    FBLinkShareParams *copy = [super copyWithZone:zone];
    copy->_caption = [_caption copyWithZone:zone];
    copy->_dataFailuresFatal = _dataFailuresFatal;
    copy->_friends = [_friends copyWithZone:zone];
    copy->_link = [_link copyWithZone:zone];
    copy->_linkDescription = [_linkDescription copyWithZone:zone];
    copy->_name = [_name copyWithZone:zone];
    copy->_picture = [_picture copyWithZone:zone];
    copy->_place = [_place copyWithZone:zone];
    copy->_ref = [_ref copyWithZone:zone];
    return copy;
}

@end
