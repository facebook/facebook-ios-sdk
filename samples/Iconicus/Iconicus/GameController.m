// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "GameController.h"

#import "Utilities.h"

@implementation GameController
{
  NSMutableIndexSet *_lockedPositions;
  NSMutableArray *_values;
}

#pragma mark - Class Methods

+ (instancetype)gameControllerFromStringRepresentationWithData:(NSString *)data locked:(NSString *)locked
{
  NSUInteger valueCount = NumberOfTiles * NumberOfTiles;
  NSUInteger dataLength = [data length];
  NSUInteger lockedLength = [locked length];

  if (dataLength != valueCount) {
    return nil;
  }
  if (lockedLength != dataLength) {
    locked = data;
  }
  GameController *gameController = [[self alloc] init];
  for (NSUInteger position = 0; position < valueCount; ++position) {
    NSUInteger value = [[data substringWithRange:NSMakeRange(position, 1)] integerValue];
    [gameController setValue:value forPosition:position];
    NSUInteger lockedValue = [[locked substringWithRange:NSMakeRange(position, 1)] integerValue];
    if (value != 0 && lockedValue != 0) {
      [gameController lockValueAtPosition:position];
    }
  }
  return gameController;
}

+ (instancetype)generate
{
  GameController *gameController = [[self alloc] init];
  NSArray *values = GenerateGridValues(50);
  [values enumerateObjectsUsingBlock:^(NSNumber *valueNumber, NSUInteger position, BOOL *stop) {
    NSUInteger value = [valueNumber unsignedIntegerValue];
    [gameController setValue:value forPosition:position];
    if (value != 0) {
      [gameController lockValueAtPosition:position];
    }
  }];
  return gameController;
}

#pragma mark - Object Lifecycle

- (instancetype)init
{
  if ((self = [super init])) {
    _values = [[NSMutableArray alloc] init];
    NSUInteger count = NumberOfTiles * NumberOfTiles;
    for (NSUInteger i = 0; i < count; ++i) {
      [_values addObject:@0];
    }
    _lockedPositions = [[NSMutableIndexSet alloc] init];
  }
  return self;
}

#pragma mark - Public Methods

- (void)lockValueAtPosition:(NSUInteger)position
{
  [_lockedPositions addIndex:position];
}

- (void)reset
{
  NSUInteger count = [_values count];
  for (NSUInteger i = 0; i < count; ++i) {
    if (![_lockedPositions containsIndex:i]) {
      _values[i] = @0;
    }
  }
}

- (void)setValue:(NSUInteger)value forPosition:(NSUInteger)position
{
  _values[position] = @(value);
}

- (NSString *)stringRepresentation
{
  return [_values componentsJoinedByString:@""];
}

- (void)unlockValueAtPosition:(NSUInteger)position
{
  [_lockedPositions removeIndex:position];
}

- (NSUInteger)valueAtPosition:(NSUInteger)position
{
  return [_values[position] unsignedIntegerValue];
}

- (BOOL)valueAtPositionIsLocked:(NSUInteger)position
{
  return [_lockedPositions containsIndex:position];
}

- (BOOL)valueAtPositionIsValid:(NSUInteger)position
{
  if ([_values[position] unsignedIntegerValue] == 0) {
    return YES;
  }
  return ValidateGridValue(_values, position);
}

#pragma mark - NSCoding

+ (BOOL)supportsSecureCoding
{
  return YES;
}

#define LOCKED_POSITIONS_KEY @"lockedPositions"
#define VALUES_KEY @"values"

- (id)initWithCoder:(NSCoder *)decoder
{
  NSArray *values = [decoder decodeObjectOfClass:[NSArray class] forKey:VALUES_KEY];
  if ([values count] != NumberOfTiles * NumberOfTiles) {
    return nil;
  }
  if ((self = [self init])) {
    _values = [values copy];
    NSIndexSet *lockedPositions = [decoder decodeObjectOfClass:[NSIndexSet class] forKey:LOCKED_POSITIONS_KEY];
    _lockedPositions = [[NSMutableIndexSet alloc] initWithIndexSet:lockedPositions];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_lockedPositions forKey:LOCKED_POSITIONS_KEY];
  [encoder encodeObject:_values forKey:VALUES_KEY];
}

@end
