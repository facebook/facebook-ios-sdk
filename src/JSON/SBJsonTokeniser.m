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

#import "SBJsonTokeniser.h"


#define isDigit(x) (*x >= '0' && *x <= '9')
#define skipDigits(x) while (isDigit(x)) x++

#define SBStringIsIllegalSurrogateHighCharacter(x) (((x) >= 0xd800) && ((x) <= 0xdfff))


@interface SBJsonTokeniser ()

@property (copy) NSString *error;

- (void)skipWhitespace;

- (sbjson_token_t)match:(const char *)utf8 ofLength:(NSUInteger)len andReturn:(sbjson_token_t)tok;
- (sbjson_token_t)matchString;
- (sbjson_token_t)matchNumber;

- (int)parseUnicodeEscape:(const char *)bytes index:(NSUInteger *)index;
- (NSString*)decodeUnicodeEscape:(const char *)bytes index:(NSUInteger *)index;

@end

@implementation SBJsonTokeniser

@synthesize error;

#pragma mark Housekeeping

- (id)init {
	self = [super init];
	if (self) {
		tokenStart = tokenLength = 0;
		buf = [[NSMutableData alloc] initWithCapacity:4096];
		illegalCharacterSet = [[NSCharacterSet illegalCharacterSet] copy];
	}
	return self;
}

- (void)dealloc {
	self.error = nil;
	[buf release];
	[illegalCharacterSet release];
	[super dealloc];
}

#pragma mark Methods

- (void)appendData:(NSData *)data {
	
	// Remove previous NUL char
	if (buf.length)
		buf.length = buf.length - 1;
	
	if (tokenStart) {
		// Remove stuff in the front of the offset
		[buf replaceBytesInRange:NSMakeRange(0, tokenStart) withBytes:"" length:0];
		tokenStart = 0;
	}
		
	[buf appendData:data];
	
	// Append NUL byte to simplify logic
	[buf appendBytes:"\0" length:1];
	
	bufbytes = [buf bytes];
	bufbytesLength = [buf length];
}

- (BOOL)getToken:(const char **)utf8 length:(NSUInteger *)len {
	if (!tokenLength)
		return NO;
	
	*len = tokenLength;
	*utf8 = bufbytes + tokenStart;
	return YES;
}

- (NSString*)getDecodedStringToken {
	NSUInteger len;
	const char *bytes;
	[self getToken:&bytes length:&len];
	
	len -= 1;
	
	NSMutableData *data = [NSMutableData dataWithCapacity:len * 1.1];
	
	char c;
	NSUInteger i = 1;
again: while (i < len) {
		switch (c = bytes[i++]) {
			case '\\':
				switch (c = bytes[i++]) {
					case '\\':
					case '/':
					case '"':
						break;
						
					case 'b':
						c = '\b';
						break;
						
					case 'n':
						c = '\n';
						break;
						
					case 'r':
						c = '\r';
						break;
						
					case 't':
						c = '\t';
						break;
						
					case 'f':
						c = '\f';
						break;
						
					case 'u': {
						NSString *s = [self decodeUnicodeEscape:bytes index:&i];
						NSAssert(s, @"Illegal unicode escape");
						[data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
						goto again;
						break;
					}
						
					default:
						NSAssert(NO, @"Should never get here");
						break;
				}
				break;
				
			case 0 ... 0x1F:
				self.error = @"Unescaped control chars";
				return nil;
				break;
				
			default:
				break;
		}
		[data appendBytes:&c length:1];
	}
	
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}


- (sbjson_token_t)next {
	tokenStart += tokenLength;
	tokenLength = 0;

	[self skipWhitespace];
	
	switch (*(bufbytes + tokenStart)) {
		case '\0':
			return sbjson_token_eof;
			break;
			
		case '[':
			tokenLength = 1;
			return sbjson_token_array_start;
			break;
			
		case ']':
			tokenLength = 1;
			return sbjson_token_array_end;
			break;
			
		case '{':
			tokenLength = 1;
			return sbjson_token_object_start;
			break;
			
		case ':':
			tokenLength = 1;
			return sbjson_token_key_value_separator;
			break;
			
		case '}':
			tokenLength = 1;
			return sbjson_token_object_end;
			break;
			
		case ',':
			tokenLength = 1;
			return sbjson_token_separator;
			break;
			
		case 'n':
			return [self match:"null" ofLength:4 andReturn:sbjson_token_null];
			break;
			
		case 't':
			return [self match:"true" ofLength:4 andReturn:sbjson_token_true];
			break;

		case 'f':
			return [self match:"false" ofLength:5 andReturn:sbjson_token_false];
			break;

		case '"':
			return [self matchString];
			break;
			
		case '-':
		case '0' ... '9':
			return [self matchNumber];
			break;			
			
		case '+':
			self.error = [NSString stringWithFormat:@"Leading + is illegal in numbers at offset %u", tokenStart];
			return sbjson_token_error;
			break;			
	}
	
	self.error = [NSString stringWithFormat:@"Unrecognised leading character at offset %u", tokenStart];
	return sbjson_token_error;
}

#pragma mark Private methods

- (void)skipWhitespace {
	while (tokenStart < bufbytesLength) {
		switch (bufbytes[tokenStart]) {
			case ' ':
			case '\t':
			case '\n':
			case '\r':
			case '\f':
			case '\v':
				tokenStart++;
				break;
			default:
				return;
				break;
		}
	}
}

- (sbjson_token_t)match:(const char *)utf8 ofLength:(NSUInteger)len andReturn:(sbjson_token_t)tok {
	if (buf.length - tokenStart - 1 < len)
		return sbjson_token_eof;
	
	if (strncmp(bufbytes + tokenStart, utf8, len)) {
		NSString *format = [NSString stringWithFormat:@"Expected '%%s' but found '%%.%us'.", len];
		self.error = [NSString stringWithFormat:format, utf8, bufbytes + tokenStart];
		return sbjson_token_error;
	}
	
	tokenLength = len;
	return tok;
}


- (int)decodeHexQuad:(const char *)hexQuad {
	char c;
	int ret = 0;
    for (int i = 0; i < 4; i++) {
		ret *= 16;
		switch (c = hexQuad[i]) {
			case '\0':
				return -2;
				break;
				
			case '0' ... '9':
				ret += c - '0';
				break;
				
			case 'a' ... 'f':
				ret += 10 + c - 'a';
				break;
				
			case 'A' ... 'F':
				ret += 10 + c - 'A';
				break;
				
			default:
				self.error = @"XXX illegal digit in hex char";
				return -1;
				break;
		}
    }
    return ret;
}

- (int)parseUnicodeEscape:(const char *)bytes index:(NSUInteger *)index {
	int hi = [self decodeHexQuad:bytes + *index];
	if (hi == -2) return -2; // EOF
	if (hi < 0) {
		self.error = @"Missing hex quad";
		return -1;
	}
	*index += 4;
	
	if (CFStringIsSurrogateHighCharacter(hi)) {
		int lo = -1;
		if (bytes[(*index)++] == '\\' && bytes[(*index)++] == 'u')
			lo = [self decodeHexQuad:bytes + *index];
		
		if (lo < 0) {
			self.error = @"Missing low character in surrogate pair";
			return -1;
		}
		*index += 4;
			
		if (!CFStringIsSurrogateLowCharacter(lo)) {
			self.error = @"Invalid low surrogate char";
			return -1;
		}		
	} else if (SBStringIsIllegalSurrogateHighCharacter(hi)) {
		self.error = @"Invalid high character in surrogate pair";
		return -1;
	}


	return hi;
}

- (NSString*)decodeUnicodeEscape:(const char *)bytes index:(NSUInteger *)index {
	int decodedHexQuad = [self decodeHexQuad:bytes + *index];
	if (decodedHexQuad < 0) {
		self.error = @"Missing hex quad";
		return nil;
	}
	unichar hi = 0xFFFF & decodedHexQuad;
	*index += 4;

	if (CFStringIsSurrogateHighCharacter(hi)) {     // high surrogate char?
		int lo = -1;
		if (bytes[(*index)++] == '\\' && bytes[(*index)++] == 'u')
			lo = [self decodeHexQuad:bytes + *index];
			
		if (lo < 0) {
			self.error = @"Missing low character in surrogate pair";
			return nil;
		}
		*index += 4;
			
		if (!CFStringIsSurrogateLowCharacter(lo)) {
			self.error = @"Invalid low surrogate char";
			return nil;
		}
			
		unichar pair[2] = {hi, lo};
		return [NSString stringWithCharacters:pair length:2];
			
	} else if (SBStringIsIllegalSurrogateHighCharacter(hi)) {		
		self.error = @"Invalid high character in surrogate pair";
		return nil;
	}
	
	return [NSString stringWithCharacters:&hi length:1];
}


- (sbjson_token_t)matchString {
	sbjson_token_t ret = sbjson_token_string;

	const char *bytes = bufbytes + tokenStart;
	NSUInteger idx = 1;
	NSUInteger maxIdx = buf.length - 2 - tokenStart;
	
	while (idx <= maxIdx) {
		switch (bytes[idx++]) {
			case 0 ... 0x1F:
				self.error = [NSString stringWithFormat:@"Unescaped control char 0x%0.2X", (int)bytes[idx-1]];
				return sbjson_token_error;
				break;
				
			case '\\':
				ret = sbjson_token_string_encoded;
				
				if (idx >= maxIdx)
					return sbjson_token_eof;

				switch (bytes[idx++]) {
					case 'b':
					case 't':
					case 'n':
					case 'r':
					case 'f':
					case 'v':
					case '"':
					case '\\':
					case '/':
						// Valid escape sequence
						break;
						
					case 'u': {
						int ch = [self parseUnicodeEscape:bytes index:&idx];
						if (ch == -2)
							return sbjson_token_eof;
						if (ch == -1)
							return sbjson_token_error;
						break;
					}
					default:
						self.error = [NSString stringWithFormat:@"Broken escape character at index %u in token starting at offset %u", idx-1, tokenStart];
						return sbjson_token_error;
						break;
				}
				break;
				
			case '"':
				tokenLength = idx;
				return ret;
				break;
				
			default:
				// any other character
				break;
		}
	}

	return sbjson_token_eof;
}

- (sbjson_token_t)matchNumber {

	sbjson_token_t ret = sbjson_token_integer;
	const char *c = bufbytes + tokenStart;

	if (*c == '-') {
		c++;
		if (!isDigit(c)) {
			self.error = @"No digits after initial minus";
			return sbjson_token_error;
		}
	}
	
	if (*c == '0') {
		c++;
		if (isDigit(c)) {
			self.error = [NSString stringWithFormat:@"Leading zero is illegal in number at offset %u", tokenStart];
			return sbjson_token_error;
		}
	}
	
	skipDigits(c);
	
	
	if (*c == '.') {
		ret = sbjson_token_double;
		c++;
		
		if (!isDigit(c) && *c) {
			self.error = [NSString stringWithFormat:@"No digits after decimal point at offset %u", tokenStart];
			return sbjson_token_error;
		}
		
		skipDigits(c);
	}
	
	if (*c == 'e' || *c == 'E') {
		ret = sbjson_token_double;
		c++;
		
		if (*c == '-' || *c == '+')
			c++;
	
		if (!isDigit(c) && *c) {
			self.error = [NSString stringWithFormat:@"No digits after exponent mark at offset %u", tokenStart];
			return sbjson_token_error;
		}
		
		skipDigits(c);
	}
	
	if (!*c)
		return sbjson_token_eof;
	
	tokenLength = c - (bufbytes + tokenStart);
	return ret;
}

@end
