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

#import "FBFetchedAppSettings.h"

#import "FBSettings.h"

@interface FBFetchedAppSettings()

@property (readwrite, retain, nonatomic) NSString *appID;

@end

@implementation FBFetchedAppSettings

-(id) init {
    return [self initWithAppID:nil];
}

-(id) initWithAppID:(NSString *)appID {
    if (self = [super init]) {
        if (appID == nil) {
            appID = [FBSettings defaultAppID];
        }
        self.appID = appID;
    }
    return self;
}

-(void) dealloc {
    self.serverAppName = nil;
    self.appID = nil;

    [super dealloc];
}
@end
