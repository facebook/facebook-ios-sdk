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

#import "FBGraphObject.h"
#import <objc/runtime.h>

static NSString *const FBIsGraphObjectKey = @"com.facebook.FBIsGraphObjectKey";

// used internally by the category impl
typedef enum _SelectorInferredImplType {
    SelectorInferredImplTypeNone  = 0,    
    SelectorInferredImplTypeGet = 1,
    SelectorInferredImplTypeSet = 2
} SelectorInferredImplType;

// internal-only wrapper
@interface FBGraphObjectArray : NSMutableArray
-(id)initWrappingArray:(NSArray *)otherArray;
@end


@interface FBGraphObject ()

- (id)initWrappingDictionary:(NSDictionary *)otherDictionary;
+ (id)graphObjectWrappingObject:(id)originalObject;
+ (SelectorInferredImplType)inferedImplTypeForSelector:(SEL)sel;
+ (BOOL)isProtocolImplementationInferable:(Protocol *)protocol checkFBGraphObjectAdoption:(BOOL)checkAdoption;

@end

@implementation FBGraphObject {
    NSMutableDictionary *_jsonObject;
}

#pragma mark Lifecycle

- (id)initWrappingDictionary:(NSDictionary *)jsonObject {
    self = [super init];    
    if (self) {
        if ([jsonObject isKindOfClass:[FBGraphObject class]]) {
            // in this case, we prefer to return the original object,
            // rather than allocate a wrapper
            
            // we are about to return this, better make it the caller's
            [jsonObject retain];
            
            // we don't need self after all
            [self release];
            
            // no wrapper needed, returning the object that was provided
            return (FBGraphObject*)jsonObject;
        } else {
            if ([jsonObject isKindOfClass:[NSMutableDictionary class]] ) {
                _jsonObject = (NSMutableDictionary*)[jsonObject retain];
            } else {
                _jsonObject = [[NSMutableDictionary dictionaryWithDictionary:jsonObject] retain];
            }
        }
    }
    return self;
}

- (void)dealloc {
    [_jsonObject release];
    [super dealloc];
}

#pragma mark -
#pragma mark Public Members

+ (NSMutableDictionary<FBGraphObject>*)graphObject {
    return [FBGraphObject graphObjectWrappingDictionary:[NSMutableDictionary dictionary]];
}

+ (NSMutableDictionary<FBGraphObject>*)graphObjectWrappingDictionary:(NSDictionary*)jsonDictionary {
    return [FBGraphObject graphObjectWrappingObject:jsonDictionary];
}

#pragma mark -
#pragma mark NSObject overrides

// make the respondsToSelector method do the right thing for the selectors we handle
- (BOOL)respondsToSelector:(SEL)sel
{
    return  [super respondsToSelector:sel] ||
    ([FBGraphObject inferedImplTypeForSelector:sel] != SelectorInferredImplTypeNone);
}

- (BOOL)conformsToProtocol:(Protocol *)protocol {
    return  [super conformsToProtocol:protocol] ||
    ([FBGraphObject isProtocolImplementationInferable:protocol 
                           checkFBGraphObjectAdoption:YES]);
}

// returns the signature for the method that we will actually invoke
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    SEL alternateSelector = sel;
    
    // if we should forward, to where?
    switch ([FBGraphObject inferedImplTypeForSelector:sel]) {
        case SelectorInferredImplTypeGet:
            alternateSelector = @selector(objectForKey:);
            break;
        case SelectorInferredImplTypeSet:
            alternateSelector = @selector(setObject:forKey:);
            break;
        case SelectorInferredImplTypeNone:
        default:
            break;
    }
    
    return [super methodSignatureForSelector:alternateSelector];
}

// forwards otherwise missing selectors that match the FBGraphObject convention
- (void)forwardInvocation:(NSInvocation *)invocation {
    // if we should forward, to where?
    switch ([FBGraphObject inferedImplTypeForSelector:[invocation selector]]) {
        case SelectorInferredImplTypeGet: {
            // property getter impl uses the selector name as an argument...
            NSString *propertyName = NSStringFromSelector([invocation selector]);
            [invocation setArgument:&propertyName atIndex:2];
            //... to the replacement method objectForKey:
            invocation.selector = @selector(objectForKey:);
            [invocation invokeWithTarget:self];
            break;
        }
        case SelectorInferredImplTypeSet: {
            // property setter impl uses the selector name as an argument...
            NSMutableString *propertyName = [NSMutableString stringWithString:NSStringFromSelector([invocation selector])];
            // remove 'set' and trailing ':', and lowercase the new first character
            [propertyName deleteCharactersInRange:NSMakeRange(0, 3)];                       // "set"
            [propertyName deleteCharactersInRange:NSMakeRange(propertyName.length - 1, 1)]; // ":"
            
            NSString *firstChar = [[propertyName substringWithRange:NSMakeRange(0,1)] lowercaseString];
            [propertyName replaceCharactersInRange:NSMakeRange(0, 1) withString:firstChar];
            // the object argument is already in the right place (2), but we need to set the key argument
            [invocation setArgument:&propertyName atIndex:3];
            // and replace the missing method with setObject:forKey:
            invocation.selector = @selector(setObject:forKey:);
            [invocation invokeWithTarget:self]; 
            break;
        } 
        case SelectorInferredImplTypeNone:
        default: 
            [super forwardInvocation:invocation];
            return;
    }
}

#pragma mark -
#pragma mark NSDictionary and NSMutableDictionary overrides

- (NSUInteger)count {
    return _jsonObject.count;
}

- (id)objectForKey:(id)key {
    id object = [_jsonObject objectForKey:key];
    // make certain it is FBObjectGraph-ified
    id possibleReplacement = [FBGraphObject graphObjectWrappingObject:object];
    if (object != possibleReplacement) {
        // and if not-yet, replace the original with the wrapped object
        [_jsonObject setObject:possibleReplacement forKey:key];
        object = possibleReplacement;
    }
    return object;
}

- (NSEnumerator *)keyEnumerator {
    return _jsonObject.keyEnumerator;
}

- (void)setObject:(id)object forKey:(id)key {
    return [_jsonObject setObject:object forKey:key];    
}

- (void)removeObjectForKey:(id)key {
    return [_jsonObject removeObjectForKey:key];
}

#pragma mark -
#pragma mark Public Members

#pragma mark -
#pragma mark Private Class Members

+ (id)graphObjectWrappingObject:(id)originalObject {
    // non-array and non-dictionary case, returns original object
    id result = originalObject;

    // array and dictionary wrap
    if ([originalObject isKindOfClass:[NSDictionary class]]) {
        result = [[[FBGraphObject alloc] initWrappingDictionary:originalObject] autorelease];
    } else if ([originalObject isKindOfClass:[NSArray class]]) {
        result = [[[FBGraphObjectArray alloc] initWrappingArray:originalObject] autorelease];
    }
    
    // return our object
    return result;
}

// helper method used by the catgory implementation to determine whether a selector should be handled 
+ (SelectorInferredImplType)inferedImplTypeForSelector:(SEL)sel {
    // the overhead in this impl is high relative to the cost of a normal property
    // accessor; if needed we will optimize by caching results of the following 
    // processing, indexed by selector
    
    NSString *selectorName = NSStringFromSelector(sel);
    int	parameterCount = [[selectorName componentsSeparatedByString:@":"] count]-1;
    // we will process a selector as a getter if paramCount == 0
    if (parameterCount == 0) {
        return SelectorInferredImplTypeGet;
        // otherwise we consider a setter if...
    } else if (parameterCount == 1 &&                   // ... we have the correct arity
               [selectorName hasPrefix:@"set"] &&       // ... we have the proper prefix
               selectorName.length > 4) {               // ... there are characters other than "set" & ":"
        return SelectorInferredImplTypeSet;
    } 
    
    return SelectorInferredImplTypeNone;
}

+ (BOOL)isProtocolImplementationInferable:(Protocol*)protocol checkFBGraphObjectAdoption:(BOOL)checkAdoption {
    // first handle base protocol questions 
    if (checkAdoption && !protocol_conformsToProtocol(protocol, @protocol(FBGraphObject))) {
        return NO;
    }
    
    if ([protocol isEqual:@protocol(FBGraphObject)]) {
        return YES; // by definition
    }

    unsigned int count = 0;    
    struct objc_method_description *methods = nil;
    
    // then confirm that all methods are required
    methods = protocol_copyMethodDescriptionList(protocol, 
                                                 NO,        // optional
                                                 YES,       // instance
                                                 &count);
    if (methods) {
        free(methods);
        return NO;
    }
    
    @try {
        // fetch methods of the protocol and confirm that each can be implemented automatically
        methods = protocol_copyMethodDescriptionList(protocol, 
                                                     YES,   // required
                                                     YES,   // instance
                                                     &count);
        for (int index = 0; index < count; index++) {
            if ([FBGraphObject inferedImplTypeForSelector:methods[index].name] == SelectorInferredImplTypeNone) {
                // we have a bad actor, short circuit
                return NO;
            }
        }
    } @finally {
        if (methods) {
            free(methods);
        }   
    }
    
    // fetch adopted protocols
    Protocol **adopted = nil;
    @try { 
        adopted = protocol_copyProtocolList(protocol, &count);
        for (int index = 0; index < count; index++) {
            // here we go again...
            if (![FBGraphObject isProtocolImplementationInferable:adopted[index] 
                                       checkFBGraphObjectAdoption:NO]) {
                return NO;
            }
        }
    } @finally {
        if (adopted) {
            free(adopted);
        }
    }
    
    // protocol ran the gauntlet
    return YES;
}

#pragma mark -

@end

#pragma mark internal classes

@implementation FBGraphObjectArray {
    NSMutableArray *_jsonArray;
}

- (id)initWrappingArray:(NSArray *)jsonArray {
    self = [super init];
    if (self) {
        if ([jsonArray isKindOfClass:[FBGraphObjectArray class]]) {
            // in this case, we prefer to return the original object,
            // rather than allocate a wrapper
            
            // we are about to return this, better make it the caller's
            [jsonArray retain];
            
            // we don't need self after all
            [self release];
            
            // no wrapper needed, returning the object that was provided
            return (FBGraphObjectArray*)jsonArray;
        } else {
        if ([jsonArray isKindOfClass:[NSMutableArray class]] ) {
            _jsonArray = (NSMutableArray*)[jsonArray retain];
        } else {
            _jsonArray = [[NSMutableArray arrayWithArray:jsonArray] retain];
        }
        }
    }
    return self;
}

- (void)dealloc {
    [_jsonArray release];
    [super dealloc];
}

- (NSUInteger)count {
    return _jsonArray.count;
}

- (id)objectAtIndex:(NSUInteger)index {
    id object = [_jsonArray objectAtIndex:index];
    // make certain it is FBObjectGraph-ified
    id possibleReplacement = [FBGraphObject graphObjectWrappingObject:object];
    if (object != possibleReplacement) {
        // and if not-yet, replace the original with the wrapped object
        [_jsonArray replaceObjectAtIndex:index withObject:possibleReplacement];
        object = possibleReplacement;
    }
    return object;
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index {
    [_jsonArray insertObject:object atIndex:index];
}

- (void)removeObjectAtIndex:(NSUInteger)index {
    [_jsonArray removeObjectAtIndex:index];
}

- (void)addObject:(id)object {
    [_jsonArray addObject:object];
}

- (void)removeLastObject {
    [_jsonArray removeLastObject];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object {
    [_jsonArray replaceObjectAtIndex:index withObject:object];
}

@end

#pragma mark -
