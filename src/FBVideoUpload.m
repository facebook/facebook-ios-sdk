#import "FBVideoUpload.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *const kAPIURL = @"http://api-video.facebook.com/restserver.php";

@implementation FBVideoUpload
@synthesize accessToken, apiKey, appSecret;

- (void) dealloc
{
    [accessToken release];
    [appSecret release];
    [apiKey release];
    [super dealloc];
}

#pragma mark Request Signature Support

- (NSString*) md5HexDigest: (NSString*) input
{
    const char* cstr = [input UTF8String];
    unsigned char hash[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstr, strlen(cstr), hash);
    NSMutableString *result = [NSMutableString string];
    for (int i=0; i<CC_MD5_DIGEST_LENGTH; i++)
        [result appendFormat:@"%02x", hash[i]];
    return result;
}

- (NSString*) signatureForParams: (NSDictionary*) params
{
    NSArray* keys = [params.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString *joined = [NSMutableString string];
    for (id key in keys) {
        id value = [params objectForKey:key];
        if (![value isKindOfClass:[NSString class]])
            continue;
        [joined appendString:key];
        [joined appendString:@"="];
        [joined appendString:value];
    }
    [joined appendString:appSecret];
    return [self md5HexDigest:joined];
}

#pragma mark Build the Request

- (NSString*) sessionID
{
    NSArray *components = [accessToken componentsSeparatedByString:@"|"];
    return [components count] < 2 ? nil : [components objectAtIndex:1];
}

- (void) startUploadWithURL: (NSURL*) movieURL
    params: (NSDictionary*) userParams
    delegate: (id <FBRequestDelegate>) delegate
{
    if ([self sessionID] == nil) {
        NSLog(@"Unable to retrieve session key from the access token.");
        return;
    }
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:userParams];
    [params setObject:@"1.0" forKey:@"v"];
    [params setObject:@"facebook.video.upload" forKey:@"method"];
    [params setObject:[self sessionID] forKey:@"session_key"];
    [params setObject:apiKey forKey:@"api_key"];
    [params setObject:[self signatureForParams:params] forKey:@"sig"];
    [params
        setObject:[NSData dataWithContentsOfURL:movieURL]
        forKey:[movieURL lastPathComponent]];
    [[FBRequest getRequestWithParams:params
        httpMethod:@"POST" delegate:delegate requestURL:kAPIURL] connect];
}

@end