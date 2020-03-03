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

#import "FBSDKGamingVideoUploader.h"

#import "FBSDKCoreKit+Internal.h"
#import "FBSDKGamingVideoUploaderConfiguration.h"
#import "FBSDKVideoUploader.h"

static FBSDKGamingVideoUploader *executingUploader = nil;

@interface FBSDKGamingVideoUploader() <FBSDKVideoUploaderDelegate>
{
  NSFileHandle *_fileHandle;
  FBSDKGamingServiceCompletionHandler _completionHandler;
}
@end

@implementation FBSDKGamingVideoUploader

+ (void)uploadVideoWithConfiguration:(FBSDKGamingVideoUploaderConfiguration * _Nonnull)configuration
                andCompletionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  if ([FBSDKAccessToken currentAccessToken] == nil) {
    completionHandler(false, [FBSDKError
                              errorWithCode:FBSDKErrorAccessTokenRequired
                              message:@"A valid access token is required to upload Images"]);

    return;
  }

  if (configuration.videoURL == nil) {
    completionHandler(false, [FBSDKError
                              errorWithCode:FBSDKErrorInvalidArgument
                              message:@"Attempting to upload a nil videoURL"]);

    return;
  }

  NSFileHandle *const fileHandle =
  [NSFileHandle
   fileHandleForReadingFromURL:configuration.videoURL
   error:nil];

  if ((unsigned long)[fileHandle seekToEndOfFile] == 0) {
    completionHandler(false, [FBSDKError
                              errorWithCode:FBSDKErrorInvalidArgument
                              message:@"Attempting to upload an empty video file"]);

    return;
  }

  executingUploader =
  [[FBSDKGamingVideoUploader alloc]
   initWithFileHandle:fileHandle
   completionHandler:completionHandler];

  FBSDKVideoUploader *const videoUploader =
  [[FBSDKVideoUploader alloc]
   initWithVideoName:[configuration.videoURL lastPathComponent]
   videoSize:(unsigned long)[fileHandle seekToEndOfFile]
   parameters:@{}
   delegate:executingUploader];

  [videoUploader start];
}

- (instancetype)initWithFileHandle:(NSFileHandle *)fileHandle
                 completionHandler:(FBSDKGamingServiceCompletionHandler _Nonnull)completionHandler
{
  if (self = [super init]) {
    _fileHandle = fileHandle;
    _completionHandler = completionHandler;
  }
  return self;
}

- (void)safeCompleteWithResult:(BOOL)result
                      andError:(NSError *)error
{
  NSError *finalError = error;

  if (result == false && error == nil)  {
    finalError =
    [FBSDKError
     errorWithCode:FBSDKErrorUnknown
     message:@"Video upload was unsuccessful, but no error was thrown."];
  }

  if (_completionHandler != nil) {
    _completionHandler(result, finalError);
  }
  executingUploader = nil;
}

#pragma mark - FBSDKVideoUploaderDelegate

- (NSData *)videoChunkDataForVideoUploader:(FBSDKVideoUploader *)videoUploader
                               startOffset:(NSUInteger)startOffset
                                 endOffset:(NSUInteger)endOffset
{
  NSUInteger chunkSize = endOffset - startOffset;
  [_fileHandle seekToFileOffset:startOffset];
  NSData *videoChunkData = [_fileHandle readDataOfLength:chunkSize];
  if (videoChunkData == nil || videoChunkData.length != chunkSize) {
    return nil;
  }
  return videoChunkData;
}

- (void)videoUploader:(FBSDKVideoUploader *)videoUploader
didCompleteWithResults:(NSDictionary<NSString *, id> *)results
{
  [self
   safeCompleteWithResult:[results[@"success"] boolValue]
   andError:nil];
}

- (void)videoUploader:(FBSDKVideoUploader *)videoUploader
     didFailWithError:(NSError *)error
{
  [self
   safeCompleteWithResult:true
   andError:error];
}

@end
