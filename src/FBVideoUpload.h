#import "FBRequest.h"

@interface FBVideoUpload : NSObject
{
    NSString *accessToken;
    NSString *appSecret;
    NSString *apiKey;
}

@property(retain) NSString *accessToken;
@property(retain) NSString *appSecret;
@property(retain) NSString *apiKey;

- (void) startUploadWithURL: (NSURL*) movieURL
    params: (NSDictionary*) userParams
    delegate: (id <FBRequestDelegate>) delegate;
    

@end
