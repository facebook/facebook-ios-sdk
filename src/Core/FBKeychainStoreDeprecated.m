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

#import "FBKeychainStoreDeprecated.h"

#import "FBDynamicFrameworkLoader.h"

@implementation FBKeychainStoreDeprecated

- (instancetype)init {
    return [super initWithService:[[NSBundle mainBundle] bundleIdentifier]];
}

- (NSMutableDictionary*)queryForKey:(NSString *)key {
    NSMutableDictionary *query = [NSMutableDictionary dictionary];
    [query setObject:[FBDynamicFrameworkLoader loadkSecClassGenericPassword] forKey:[FBDynamicFrameworkLoader loadkSecClass]];
    [query setObject:self.service forKey:[FBDynamicFrameworkLoader loadkSecAttrService]];
    [query setObject:key forKey:[FBDynamicFrameworkLoader loadkSecAttrGeneric]];
#if !TARGET_IPHONE_SIMULATOR
    if (self.accessGroup) {
        [query setObject:self.accessGroup forKey:[FBDynamicFrameworkLoader loadkSecAttrAccessGroup]];
    }
#endif

    return query;
}

@end
