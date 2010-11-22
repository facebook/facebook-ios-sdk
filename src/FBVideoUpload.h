#import "FBRequest.h"

// Uploads video to Facebook using a combination
// of the old and the new API/SDK.
@interface FBVideoUpload : NSObject
{
    NSString *accessToken;
    NSString *appSecret;
    NSString *apiKey;
}

// The access token from the Facebook class. We need the access
// key to get the session key, so that this param is required if
// you want to upload anything at all.
@property(retain) NSString *accessToken;

// Application secret as shown in the app settings on Facebook.
// This is a required param, since we need the secret to correctly
// compute the request signature.
@property(retain) NSString *appSecret;

// Application API key, also required.
@property(retain) NSString *apiKey;

// The URL has to be a file URL or bad things will happen.
- (void) startUploadWithURL: (NSURL*) movieURL
    params: (NSDictionary*) userParams
    delegate: (id <FBRequestDelegate>) delegate;
    

@end
