/*
 Copyright (c) 2010-2011, Stig Brautaset. All rights reserved.

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
#import "SBJsonUTF8Stream.h"

#define SBStringIsIllegalSurrogateHighCharacter(x) (((x) >= 0xd800) && ((x) <= 0xdfff))


@implementation SBJsonTokeniser

@synthesize error = _error;

- (id)init {
    self = [super init];
    if (self) {
        _stream = [[SBJsonUTF8Stream alloc] init];

    }

    return self;
}

- (void)dealloc {
    [_stream release];
    [super dealloc];
}

- (void)appendData:(NSData *)data_ {
    [_stream appendData:data_];
}


- (sbjson_token_t)match:(const char *)pattern length:(NSUInteger)len retval:(sbjson_token_t)token {
    if (![_stream ensureChars:len])
        return sbjson_token_eof;

    if ([_stream skipCharacters:pattern length:len])
        return token;

    char bytes[len+1];
    (void)[_stream getBytes:bytes length:len];

    NSString *fmt = [NSString stringWithFormat:@"Expected '%%s' but found '%%.%us'", len];
    self.error = [NSString stringWithFormat:fmt, pattern, bytes];
    return sbjson_token_error;
}

- (BOOL)decodeEscape:(unichar)ch into:(unichar*)decoded {
    switch (ch) {
        case '\\':
        case '/':
        case '"':
            *decoded = ch;
            break;

        case 'b':
            *decoded = '\b';
            break;

        case 'n':
            *decoded = '\n';
            break;

        case 'r':
            *decoded = '\r';
            break;

        case 't':
            *decoded = '\t';
            break;

        case 'f':
            *decoded = '\f';
            break;

        default:
            self.error = @"Illegal escape character";
            return NO;
            break;
    }
    return YES;
}

- (BOOL)decodeHexQuad:(unichar*)quad {
    unichar c, tmp = 0;

    for (int i = 0; i < 4; i++) {
        (void)[_stream getNextUnichar:&c];
        tmp *= 16;
        switch (c) {
            case '0' ... '9':
                tmp += c - '0';
                break;

            case 'a' ... 'f':
                tmp += 10 + c - 'a';
                break;

            case 'A' ... 'F':
                tmp += 10 + c - 'A';
                break;

            default:
                return NO;
        }
    }
    *quad = tmp;
    return YES;
}

- (sbjson_token_t)getStringToken:(NSObject**)token {
    NSMutableString *acc = nil;

    for (;;) {
        [_stream skip];
        
        unichar ch;
        {
            NSMutableString *string = nil;
            if (![_stream getSimpleString:&string])
                return sbjson_token_eof;
        
            if (![_stream getUnichar:&ch])
                return sbjson_token_eof;

            if (acc) {
                [acc appendString:string];
            
            } else if (ch == '"') {
                *token = string;
                [_stream skip];
                return sbjson_token_string;

            } else {
                acc = [[string mutableCopy] autorelease];
            }
        }
        
        switch (ch) {
            case 0 ... 0x1F:
                self.error = [NSString stringWithFormat:@"Unescaped control character [0x%0.2X]", (int)ch];
                return sbjson_token_error;
                break;

            case '"':
                *token = acc;
                [_stream skip];
                return sbjson_token_string;
                break;

            case '\\':
                if (![_stream getNextUnichar:&ch])
                    return sbjson_token_eof;

                if (ch == 'u') {
                    if (![_stream ensureChars:5])
                        return sbjson_token_eof;

                    unichar hi;
                    if (![self decodeHexQuad:&hi]) {
                        self.error = @"Invalid hex quad";
                        return sbjson_token_error;
                    }

                    if (CFStringIsSurrogateHighCharacter(hi)) {
                        unichar lo;

                        if (![_stream ensureChars:6])
                            return sbjson_token_eof;

                        (void)[_stream getNextUnichar:&ch];
                        (void)[_stream getNextUnichar:&lo];
                        if (ch != '\\' || lo != 'u' || ![self decodeHexQuad:&lo]) {
                            self.error = @"Missing low character in surrogate pair";
                            return sbjson_token_error;
                        }

                        if (!CFStringIsSurrogateLowCharacter(lo)) {
                            self.error = @"Invalid low character in surrogate pair";
                            return sbjson_token_error;
                        }

                        unichar pair[2] = {hi, lo};
                        CFStringAppendCharacters((CFMutableStringRef)acc, pair, 2);
                    } else if (SBStringIsIllegalSurrogateHighCharacter(hi)) {
                        self.error = @"Invalid high character in surrogate pair";
                        return sbjson_token_error;
                    } else {
                        CFStringAppendCharacters((CFMutableStringRef)acc, &hi, 1);
                    }


                } else {
                    unichar decoded;
                    if (![self decodeEscape:ch into:&decoded])
                        return sbjson_token_error;
                    CFStringAppendCharacters((CFMutableStringRef)acc, &decoded, 1);
                }

                break;

            default: {
                char bytes[1];
                [_stream getBytes:bytes length:1];
                [NSException raise:@"unexpected error" format:@"Should not get here: '%c'", *bytes];
                break;
            }
        }
    }
    return sbjson_token_eof;
}

- (sbjson_token_t)getNumberToken:(NSObject**)token {

    NSUInteger numberStart = _stream.index;
    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];

    unichar ch;
    if (![_stream getUnichar:&ch])
        return sbjson_token_eof;

    BOOL isNegative = NO;
    if (ch == '-') {
        isNegative = YES;
        if (![_stream getNextUnichar:&ch])
            return sbjson_token_eof;
    }

    if (ch == '0') {
        if (![_stream getNextUnichar:&ch])
            return sbjson_token_eof;

        if ([digits characterIsMember:ch]) {
            self.error = @"Leading zero is illegal in number";
            return sbjson_token_error;
        }
    }

    unsigned long long mantissa = 0;
    int mantissa_length = 0;

    while ([digits characterIsMember:ch]) {
        mantissa *= 10;
        mantissa += (ch - '0');
        mantissa_length++;

        if (![_stream getNextUnichar:&ch])
            return sbjson_token_eof;
    }

    short exponent = 0;
    BOOL isFloat = NO;

    if (ch == '.') {
        isFloat = YES;
        if (![_stream getNextUnichar:&ch])
            return sbjson_token_eof;

        while ([digits characterIsMember:ch]) {
            mantissa *= 10;
            mantissa += (ch - '0');
            mantissa_length++;
            exponent--;

            if (![_stream getNextUnichar:&ch])
                return sbjson_token_eof;
        }

        if (!exponent) {
            self.error = @"No digits after decimal point";
            return sbjson_token_error;
        }
    }

    BOOL hasExponent = NO;
    if (ch == 'e' || ch == 'E') {
        hasExponent = YES;

        if (![_stream getNextUnichar:&ch])
            return sbjson_token_eof;

        BOOL expIsNegative = NO;
        if (ch == '-') {
            expIsNegative = YES;
            if (![_stream getNextUnichar:&ch])
                return sbjson_token_eof;

        } else if (ch == '+') {
            if (![_stream getNextUnichar:&ch])
                return sbjson_token_eof;
        }

        short exp = 0;
        short exp_length = 0;
        while ([digits characterIsMember:ch]) {
            exp *= 10;
            exp += (ch - '0');
            exp_length++;

            if (![_stream getNextUnichar:&ch])
                return sbjson_token_eof;
        }

        if (exp_length == 0) {
            self.error = @"No digits in exponent";
            return sbjson_token_error;
        }

        if (expIsNegative)
            exponent -= exp;
        else
            exponent += exp;
    }

    if (!mantissa_length && isNegative) {
        self.error = @"No digits after initial minus";
        return sbjson_token_error;

    } else if (mantissa_length >= 19) {
        // The super slow path... for REALLY long numbers
        NSUInteger index = _stream.index;        
        NSUInteger length = index - numberStart;
        char bytes[length+1];

        _stream.index = numberStart;
        [_stream getBytes:bytes length:length];
        _stream.index = index;

        NSString *numberString = [[[NSString alloc] initWithBytes:bytes length:length encoding:NSUTF8StringEncoding] autorelease];
        *token = [NSDecimalNumber decimalNumberWithString:numberString];

    } else if (!isFloat && !hasExponent) {
        if (!isNegative)
            *token = [NSNumber numberWithUnsignedLongLong:mantissa];
        else
            *token = [NSNumber numberWithLongLong:-mantissa];
    } else {
        *token = [NSDecimalNumber decimalNumberWithMantissa:mantissa
                                                   exponent:exponent
                                                 isNegative:isNegative];
    }

    return sbjson_token_number;
}

- (sbjson_token_t)getToken:(NSObject **)token {

    [_stream skipWhitespace];

    unichar ch;
    if (![_stream getUnichar:&ch])
        return sbjson_token_eof;

    NSUInteger oldIndexLocation = _stream.index;
    sbjson_token_t tok;

    switch (ch) {
        case '[':
            tok = sbjson_token_array_start;
            [_stream skip];
            break;

        case ']':
            tok = sbjson_token_array_end;
            [_stream skip];
            break;

        case '{':
            tok = sbjson_token_object_start;
            [_stream skip];
            break;

        case ':':
            tok = sbjson_token_keyval_separator;
            [_stream skip];
            break;

        case '}':
            tok = sbjson_token_object_end;
            [_stream skip];
            break;

        case ',':
            tok = sbjson_token_separator;
            [_stream skip];
            break;

        case 'n':
            tok = [self match:"null" length:4 retval:sbjson_token_null];
            break;

        case 't':
            tok = [self match:"true" length:4 retval:sbjson_token_true];
            break;

        case 'f':
            tok = [self match:"false" length:5 retval:sbjson_token_false];
            break;

        case '"':
            tok = [self getStringToken:token];
            break;

        case '0' ... '9':
        case '-':
            tok = [self getNumberToken:token];
            break;

        case '+':
            self.error = @"Leading + is illegal in number";
            tok = sbjson_token_error;
            break;

        default:
            self.error = [NSString stringWithFormat:@"Illegal start of token [%c]", ch];
            tok = sbjson_token_error;
            break;
    }

    if (tok == sbjson_token_eof) {
        // We ran out of bytes in the middle of a token.
        // We don't know how to restart in mid-flight, so
        // rewind to the start of the token for next attempt.
        // Hopefully we'll have more data then.
        _stream.index = oldIndexLocation;
    }

    return tok;
}


@end
