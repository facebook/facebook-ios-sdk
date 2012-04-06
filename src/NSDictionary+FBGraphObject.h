/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

// NSDictionary (FBGraphObject) category
//
// Summary:
// use of this category enables use of NSDictionary and NSMutableDictionary objects as "FBGraphObjects";
// the concrete impact of this is that the objects can be cast to protocol references and used in a typed
// manner, like so:
//    NSDictionary<FBGraphPerson> person = obj;
//    NSLog(@"first_name=%@", person.first_name);
//
// To enable this behavior call treatAsGraphObject on any NSDictionary object; objects returned by the SDK
// have already had treatAsGraphObject called
@interface NSDictionary (FBGraphObject)

// treatAsGraphObject method
//
// Summary:
// usable by application and SDK code to mark an NSDictionary or NSDictionary-derived object as useable
// for casting to FBGraphPlace, FBGraphPerson, etc. as well as custom OG accessor protocols
- (void)treatAsGraphObject;

// necessary for forwarding property accessor calls to the appropriate methods, these are called by the 
// objective-c runtime and should should not be called directly by application code
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
- (void)forwardInvocation:(NSInvocation *)invocation;

@end
