/*
 Copyright (c) 2010, Stig Brautaset.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:
 
   Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
  
   Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 
   Neither the name of the the author nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SBJsonStreamWriter.h"
#import "SBJsonStreamWriterState.h"

static NSDecimalNumber *notANumber;

@implementation SBJsonStreamWriter

@synthesize error;
@dynamic depth;
@dynamic maxDepth;
@synthesize states;
@synthesize humanReadable;
@synthesize sortKeys;

+ (void)initialize {
	notANumber = [NSDecimalNumber notANumber];
}

#pragma mark Housekeeping

@synthesize delegate;

- (id)init {
	self = [super init];
	if (self) {
		maxDepth = 512;
		states = calloc(maxDepth, sizeof(SBJsonStreamWriterState*));
		NSAssert(states, @"States not initialised");
		
        [self reset];

		stringCache = [[NSCache alloc] init];
    }
	return self;
}

- (void)dealloc {
	self.error = nil;
	free(states);
	[super dealloc];
}

#pragma mark Methods

- (void)reset {
    states[0] = [SBJsonStreamWriterStateStart sharedInstance];
}

- (void)appendBytes:(const void *)bytes length:(NSUInteger)length {
    [delegate writer:self appendBytes:bytes length:length];
}

- (BOOL)writeObject:(NSDictionary *)dict {
	if (![self writeObjectOpen])
		return NO;
	
	NSArray *keys = [dict allKeys];
	if (sortKeys)
		keys = [keys sortedArrayUsingSelector:@selector(compare:)];
	
	for (id k in keys) {
		if (![k isKindOfClass:[NSString class]]) {
			self.error = [NSString stringWithFormat:@"JSON object key must be string: %@", k];
			return NO;
		}

		if (![self writeString:k])
			return NO;
		if (![self writeValue:[dict objectForKey:k]])
			return NO;
	}
	
	return [self writeObjectClose];
}

- (BOOL)writeArray:(NSArray*)array {
	if (![self writeArrayOpen])
		return NO;
	for (id v in array)
		if (![self writeValue:v])
			return NO;
	return [self writeArrayClose];
}


- (BOOL)writeObjectOpen {
	SBJsonStreamWriterState *s = states[depth];
	if ([s isInvalidState:self]) return NO;
	if ([s expectingKey:self]) return NO;
	[s appendSeparator:self];
	if (humanReadable && depth) [s appendWhitespace:self];
	
	if (maxDepth && ++depth > maxDepth) {
		self.error = @"Nested too deep";
		return NO;
	}

	states[depth] = kSBJsonStreamWriterStateObjectStart;
	[delegate writer:self appendBytes:"{" length:1];
	return YES;
}

- (BOOL)writeObjectClose {
	SBJsonStreamWriterState *state = states[depth--];
	if ([state isInvalidState:self]) return NO;
	if (humanReadable) [state appendWhitespace:self];
	[delegate writer:self appendBytes:"}" length:1];
	[states[depth] transitionState:self];
	return YES;
}

- (BOOL)writeArrayOpen {
	SBJsonStreamWriterState *s = states[depth];
	if ([s isInvalidState:self]) return NO;
	if ([s expectingKey:self]) return NO;
	[s appendSeparator:self];
	if (humanReadable && depth) [s appendWhitespace:self];
	
	if (maxDepth && ++depth > maxDepth) {
		self.error = @"Nested too deep";
		return NO;
	}

	states[depth] = kSBJsonStreamWriterStateArrayStart;
	[delegate writer:self appendBytes:"[" length:1];
	return YES;
}

- (BOOL)writeArrayClose {
	SBJsonStreamWriterState *state = states[depth--];
	if ([state isInvalidState:self]) return NO;
	if ([state expectingKey:self]) return NO;
	if (humanReadable) [state appendWhitespace:self];
	
	[delegate writer:self appendBytes:"]" length:1];
	[states[depth] transitionState:self];
	return YES;
}

- (BOOL)writeNull {
	SBJsonStreamWriterState *s = states[depth];
	if ([s isInvalidState:self]) return NO;
	if ([s expectingKey:self]) return NO;
	[s appendSeparator:self];
	if (humanReadable) [s appendWhitespace:self];

	[delegate writer:self appendBytes:"null" length:4];
	[s transitionState:self];
	return YES;
}

- (BOOL)writeBool:(BOOL)x {
	SBJsonStreamWriterState *s = states[depth];
	if ([s isInvalidState:self]) return NO;
	if ([s expectingKey:self]) return NO;
	[s appendSeparator:self];
	if (humanReadable) [s appendWhitespace:self];
	
	if (x)
		[delegate writer:self appendBytes:"true" length:4];
	else
		[delegate writer:self appendBytes:"false" length:5];
	[s transitionState:self];
	return YES;
}


- (BOOL)writeValue:(id)o {
	if ([o isKindOfClass:[NSDictionary class]]) {
		return [self writeObject:o];

	} else if ([o isKindOfClass:[NSArray class]]) {
		return [self writeArray:o];

	} else if ([o isKindOfClass:[NSString class]]) {
		[self writeString:o];
		return YES;

	} else if ([o isKindOfClass:[NSNumber class]]) {
		return [self writeNumber:o];

	} else if ([o isKindOfClass:[NSNull class]]) {
		return [self writeNull];
		
	} else if ([o respondsToSelector:@selector(proxyForJson)]) {
		return [self writeValue:[o proxyForJson]];

	}	
	
	self.error = [NSString stringWithFormat:@"JSON serialisation not supported for %@", [o class]];
	return NO;
}

static const char *strForChar(int c) {	
	switch (c) {
		case 0: return "\\u0000"; break;
		case 1: return "\\u0001"; break;
		case 2: return "\\u0002"; break;
		case 3: return "\\u0003"; break;
		case 4: return "\\u0004"; break;
		case 5: return "\\u0005"; break;
		case 6: return "\\u0006"; break;
		case 7: return "\\u0007"; break;
		case 8: return "\\b"; break;
		case 9: return "\\t"; break;
		case 10: return "\\n"; break;
		case 11: return "\\u000b"; break;
		case 12: return "\\f"; break;
		case 13: return "\\r"; break;
		case 14: return "\\u000e"; break;
		case 15: return "\\u000f"; break;
		case 16: return "\\u0010"; break;
		case 17: return "\\u0011"; break;
		case 18: return "\\u0012"; break;
		case 19: return "\\u0013"; break;
		case 20: return "\\u0014"; break;
		case 21: return "\\u0015"; break;
		case 22: return "\\u0016"; break;
		case 23: return "\\u0017"; break;
		case 24: return "\\u0018"; break;
		case 25: return "\\u0019"; break;
		case 26: return "\\u001a"; break;
		case 27: return "\\u001b"; break;
		case 28: return "\\u001c"; break;
		case 29: return "\\u001d"; break;
		case 30: return "\\u001e"; break;
		case 31: return "\\u001f"; break;
		case 34: return "\\\""; break;
		case 92: return "\\\\"; break;
	}
	NSLog(@"FUTFUTFUT: -->'%c'<---", c);
	return "FUTFUTFUT";
}

- (BOOL)writeString:(NSString*)string {	
	SBJsonStreamWriterState *s = states[depth];
	if ([s isInvalidState:self]) return NO;
	[s appendSeparator:self];
	if (humanReadable) [s appendWhitespace:self];
	
	NSMutableData *buf = [stringCache objectForKey:string];
	if (!buf) {
        
        NSUInteger len = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        const char *utf8 = [string UTF8String];
        NSUInteger written = 0, i = 0;
		
        buf = [NSMutableData dataWithCapacity:len * 1.1f];
        [buf appendBytes:"\"" length:1];
        
        for (i = 0; i < len; i++) {
            int c = utf8[i];
            BOOL isControlChar = c >= 0 && c < 32;
            if (isControlChar || c == '"' || c == '\\') {
                if (i - written)
                    [buf appendBytes:utf8 + written length:i - written];
                written = i + 1;
                
                const char *t = strForChar(c);
                [buf appendBytes:t length:strlen(t)];
            }
        }
        
        if (i - written)
            [buf appendBytes:utf8 + written length:i - written];
        
        [buf appendBytes:"\"" length:1];
        [stringCache setObject:buf forKey:string];
    }

	[delegate writer:self appendBytes:[buf bytes] length:[buf length]];
	[s transitionState:self];
	return YES;
}

- (BOOL)writeNumber:(NSNumber*)number {
	if ((CFBooleanRef)number == kCFBooleanTrue || (CFBooleanRef)number == kCFBooleanFalse)
		return [self writeBool:[number boolValue]];
	
	SBJsonStreamWriterState *s = states[depth];
	if ([s isInvalidState:self]) return NO;
	if ([s expectingKey:self]) return NO;
	[s appendSeparator:self];
	if (humanReadable) [s appendWhitespace:self];
		
	if ((CFNumberRef)number == kCFNumberPositiveInfinity) {
		self.error = @"+Infinity is not a valid number in JSON";
		return NO;

	} else if ((CFNumberRef)number == kCFNumberNegativeInfinity) {
		self.error = @"-Infinity is not a valid number in JSON";
		return NO;

	} else if ((CFNumberRef)number == kCFNumberNaN) {
		self.error = @"NaN is not a valid number in JSON";
		return NO;
		
	} else if (number == notANumber) {
		self.error = @"NaN is not a valid number in JSON";
		return NO;
	}
	
	const char *objcType = [number objCType];
	char num[128];
	size_t len;
	
	switch (objcType[0]) {
		case 'c': case 'i': case 's': case 'l': case 'q':
			len = snprintf(num, sizeof num, "%lld", [number longLongValue]);
			break;
		case 'C': case 'I': case 'S': case 'L': case 'Q':
			len = snprintf(num, sizeof num, "%llu", [number unsignedLongLongValue]);
			break;
		case 'f': case 'd': default:
			if ([number isKindOfClass:[NSDecimalNumber class]]) {
				char const *utf8 = [[number stringValue] UTF8String];
				[delegate writer:self appendBytes:utf8 length: strlen(utf8)];
				[s transitionState:self];
				return YES;
			}
			len = snprintf(num, sizeof num, "%.17g", [number doubleValue]);
			break;
	}
	[delegate writer:self appendBytes:num length: len];
	[s transitionState:self];
	return YES;
}

#pragma mark Private methods

- (NSUInteger)depth {
	return depth;
}

- (void)setMaxDepth:(NSUInteger)x {
	NSAssert(x, @"maxDepth must be greater than 0");
	maxDepth = x;
	states = realloc(states, x);
	NSAssert(states, @"Failed to reallocate more memory for states");
}

@end
