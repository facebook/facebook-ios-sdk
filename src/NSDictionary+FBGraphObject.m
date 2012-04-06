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

#import "NSDictionary+FBGraphObject.h"

static NSString *const FBIsGraphObjectKey = @"com.facebook.FBIsGraphObjectKey";

// used internally by the category impl
typedef enum _SelectorDecision {
    SelectorDecisionNO  = 0,    
    SelectorDecisionGet = 1,
    SelectorDecisionSet = 2
} SelectorDecision;

@implementation NSDictionary (FBGraphObject)

#pragma mark public members

- (void)treatAsGraphObject {
    [self  setValue:[NSNumber numberWithBool:YES] forKey:FBIsGraphObjectKey];
}

#pragma mark -
#pragma mark category implementation (treat as private)

// helper method used by the catgory implementation to determine whether a selector should be handled 
- (SelectorDecision)shouldForwardSelector:(SEL)sel {
    // if no blessed list, super
    NSNumber *blessed = [self valueForKey:FBIsGraphObjectKey];
    if (!([blessed isKindOfClass:[NSNumber class]] &&
          [blessed boolValue])) {
        return SelectorDecisionNO;
    }
    
    // the overhead in this impl is high relative to the cost of a normal property
    // accessor; if needed we will optimize by caching results of the following 
    // processing, indexed by selector
    
    NSString *selectorName = NSStringFromSelector(sel);
    int	parameterCount = [[selectorName componentsSeparatedByString:@":"] count]-1;
    // we will process a selector as a getter if...
    if ([self respondsToSelector:@selector(objectForKey:)] &&       // ... we are able to process it
        parameterCount == 0) {                                      // ... we have the correct arity
        return SelectorDecisionGet;
    // otherwise we consider a getter if...
    } else if ([self respondsToSelector:@selector(setObject:forKey:)] &&    // ... we are able to process it
        parameterCount == 1 &&                                              // ... we have the correct arity
        [selectorName hasPrefix:@"set"] &&                                  // ... we have the proper prefix
        selectorName.length > 3) {                                          // ... there are characters after "set"
        return SelectorDecisionSet;
    } 
        
    return SelectorDecisionNO;
}

// make the respondsToSelector method do the right thing for the selectors we handle
- (BOOL)respondsToSelector:(SEL)sel
{
    return  [super respondsToSelector:sel] ||
            ([self shouldForwardSelector:sel] != SelectorDecisionNO);
}

// returns the signature for the method that we will actually invoke
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    SEL alternateSelector = sel;

    // if we should forward, to where?
    switch ([self shouldForwardSelector:sel]) {
        case SelectorDecisionGet:
            alternateSelector = @selector(objectForKey:);
            break;
        case SelectorDecisionSet:
            alternateSelector = @selector(setObject:forKey:);
            break;
        case SelectorDecisionNO:
        default:
            break;
    }
    
    // confirm that we have selected a viable alternate
    if ([self respondsToSelector:alternateSelector]) {
        // returns a method signature for a different selector,
        // which we will use in forwardInvocation to make the actual call
        return [super methodSignatureForSelector:alternateSelector];
    } else {
        // otherwise pass through
        return [super methodSignatureForSelector:alternateSelector];
    }
}

// forwards otherwise missing selectors that match the FBGraphObject convention
- (void)forwardInvocation:(NSInvocation *)invocation {
    // if we should forward, to where?
    switch ([self shouldForwardSelector:[invocation selector]]) {
        case SelectorDecisionGet: {
            // property getter impl uses the selector name as an argument...
            NSString *propertyName = NSStringFromSelector([invocation selector]);
            [invocation setArgument:&propertyName atIndex:2];
            //... to the replacement method objectForKey:
            invocation.selector = @selector(objectForKey:);
            [invocation invokeWithTarget:self];
            
            id returnValue = nil;
            [invocation getReturnValue:&returnValue];
            
            // if the returned object can be a graph object, make it so
            if ([returnValue respondsToSelector:@selector(treatAsGraphObject)]) {
                [returnValue treatAsGraphObject];
            }
            break;
        }
        case SelectorDecisionSet: {
            // property setter impl uses the selector name as an argument...
            NSMutableString *propertyName = [NSMutableString stringWithString:NSStringFromSelector([invocation selector])];
            // remove 'set' and lowercase the new first character
            [propertyName deleteCharactersInRange:NSMakeRange(0, 3)];
            NSString *firstChar = [[propertyName substringWithRange:NSMakeRange(0,1)] lowercaseString];
            [propertyName replaceCharactersInRange:NSMakeRange(0, 1) withString:firstChar];
            // the object argument is already in the right place (2), but we need to set the key argument
            [invocation setArgument:&propertyName atIndex:3];
            // and replace the missing method with setObject:forKey:
            invocation.selector = @selector(setObject:forKey:);
            [invocation invokeWithTarget:self]; 
            break;
        } 
        case SelectorDecisionNO:
        default: 
            [super forwardInvocation:invocation];
            return;
    }
}

#pragma mark -

@end

// BUG:
// a dummy function, referenced from another module (in this case FBRequest.m) mitigates the linker bug
// in a way that does not require applicaiton logic to use the -all_load or -force_load linker flags
// http://stackoverflow.com/questions/6820778/linking-objective-c-categories-in-a-static-library
void BUG_MITIGATION_LINK_CATEGORY(){
    NSLog(@"do nothing, just make the linker include this module");
}
