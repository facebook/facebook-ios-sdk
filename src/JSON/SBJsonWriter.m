/*
 Copyright (C) 2009 Stig Brautaset. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
 
 * Neither the name of the author nor the names of its contributors may be used
   to endorse or promote products derived from this software without specific
   prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SBJsonWriter.h"
#import "SBJsonStreamWriter.h"

@interface SBJsonWriter ()
@property (copy) NSString *error;
@end

@implementation SBJsonWriter

@synthesize error;

- (id)init {
    self = [super init];
    if (self) {
        _writer = [[SBJsonStreamWriter alloc] init];
        _writer.delegate = self;
        
        _data = [[NSMutableData alloc] initWithCapacity:1024u];
    }
    return self;
}

- (void)dealloc {
    [_writer release];
    [error release];
    [_data release];
    [super dealloc];
}

- (NSString*)stringWithObject:(id)value {
	NSData *data = [self dataWithObject:value];
	if (data)
		return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	return nil;
}	

- (NSString*)stringWithObject:(id)value error:(NSError**)error_ {
    NSString *tmp = [self stringWithObject:value];
    if (tmp)
        return tmp;
    
    if (error_) {
		NSDictionary *ui = [NSDictionary dictionaryWithObjectsAndKeys:self.error, NSLocalizedDescriptionKey, nil];
        *error_ = [NSError errorWithDomain:@"org.brautaset.json.parser.ErrorDomain" code:0 userInfo:ui];
	}
	
    return nil;
}

- (NSData*)dataWithObject:(id)object {
    self.error = nil;
    [_data setLength:0];
    [_writer reset];
    
	BOOL ok = NO;
	if ([object isKindOfClass:[NSDictionary class]])
		ok = [_writer writeObject:object];
	
	else if ([object isKindOfClass:[NSArray class]])
		ok = [_writer writeArray:object];
		
	else if ([object respondsToSelector:@selector(proxyForJson)])
		return [self dataWithObject:[object proxyForJson]];

	else {
		self.error = @"Not valid type for JSON";
		return nil;
	}
	
	if (ok)
		return [[_data copy] autorelease];
	
    self.error = _writer.error;
	return nil;	
}

- (NSUInteger)maxDepth {
    return _writer.maxDepth;
}

- (void)setMaxDepth:(NSUInteger)maxDepth {
    _writer.maxDepth = maxDepth;
}

- (BOOL)humanReadable {
    return _writer.humanReadable;
}

- (void)setHumanReadable:(BOOL)humanReadable {
    _writer.humanReadable = humanReadable;
}

- (BOOL)sortKeys {
    return _writer.sortKeys;
}

- (void)setSortKeys:(BOOL)sortKeys {
    _writer.sortKeys = sortKeys;
}

#pragma mark SBJsonStreamWriterDelegate

- (void)writer:(SBJsonStreamWriter *)writer appendBytes:(const void *)bytes length:(NSUInteger)length {
    [_data appendBytes:bytes length:length];
}

@end
