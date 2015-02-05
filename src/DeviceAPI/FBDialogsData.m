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

#import "FBDialogsData+Internal.h"

@interface FBDialogsData ()

@property (nonatomic, readwrite, copy) NSString *method;
@property (nonatomic, readwrite, copy) NSDictionary *arguments;
@property (nonatomic, readwrite, copy) NSDictionary *clientState;
@property (nonatomic, readwrite, copy) NSDictionary *results;
@property (nonatomic, readwrite, copy) NSDictionary *rawResultData;

@end

@implementation FBDialogsData

- (instancetype)initWithMethod:(NSString *)method arguments:(NSDictionary *)arguments {
    self = [super init];
    if (self) {
        self.method = method;
        self.arguments = arguments ?: @{};
    }
    return self;
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString stringWithFormat:@"<%@: %p, method: %@",
                               NSStringFromClass([self class]),
                               self,
                               self.method];

    if (self.arguments) {
        [result appendFormat:@"\n arguments: %@", self.arguments];
    }
    if (self.results) {
        [result appendFormat:@"\n results: %@", self.results];
    }
    if (self.clientState) {
        [result appendFormat:@"\n clientState: %@", self.clientState];
    }

    [result appendString:@">"];
    return result;
}

- (void)dealloc {
    [_method release];
    [_arguments release];
    [_clientState release];
    [_results release];

    [super dealloc];
}

- (BOOL)isValid {
    return (_method != nil);
}

@end
