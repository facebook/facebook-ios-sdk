// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "CameraDialogViewController.h"

@import FBSDKShareKit;

static NSString *const WolfMaskEffectID = @"1808360332775136";
static NSString *const TexturesTestEffectID = @"1865593017034090";
static NSString *const NikeRunSampleID = @"231493957323532";
static NSString *const NikeRunSampleArgs = @"{\"kilometers\":\"3.12\",\"xArray\":[\"0.67\",\"0.67\",\"0.65\",\"0.62\",\"0.61\",\"0.55\",\"0.45\",\"0.35\",\"0.27\",\"0.21\",\"0.18\",\"0.17\",\"0.2\",\"0.2\",\"0.27\",\"0.3\",\"0.35\",\"0.4\",\"0.5\",\"0.52\",\"0.53\",\"0.55\",\"0.59\",\"0.65\",\"0.67\",\"0.67\",\"0.7\",\"0.73\",\"0.72\",\"0.7\"],\"yArray\":[\"0.97\",\"0.92\",\"0.88\",\"0.85\",\"0.81\",\"0.82\",\"0.87\",\"0.92\",\"0.9\",\"0.85\",\"0.75\",\"0.65\",\"0.53\",\"0.45\",\"0.35\",\"0.25\",\"0.17\",\"0.14\",\"0.13\",\"0.25\",\"0.32\",\"0.4\",\"0.5\",\"0.65\",\"0.7\",\"0.75\",\"0.76\",\"0.8\",\"0.85\",\"0.83\"]}";

@implementation CameraDialogViewController

- (IBAction)openCamera:(id)sender
{
  FBSDKShareCameraEffectContent *content = [FBSDKShareCameraEffectContent new];
  [FBSDKShareDialog showFromViewController:self
                               withContent:content
                                  delegate:nil];
}

- (IBAction)openWolfMask:(id)sender
{
  FBSDKShareCameraEffectContent *content = [FBSDKShareCameraEffectContent new];
  content.effectID = WolfMaskEffectID;
  [FBSDKShareDialog showFromViewController:self
                               withContent:content
                                  delegate:nil];
}

- (IBAction)openEffectWithTextures:(id)sender
{
  FBSDKShareCameraEffectContent *content = [FBSDKShareCameraEffectContent new];
  content.effectID = TexturesTestEffectID;
  FBSDKCameraEffectTextures *textures = [FBSDKCameraEffectTextures new];
  UIImage *texture1 = [UIImage imageNamed:@"AppIcon40x40"];
  UIImage *texture2 = [UIImage imageNamed:@"png_transparency.png"];
  UIImage *texture3 = [UIImage imageNamed:@"bugs_bunny-500x500.jpg"];
  [textures setImage:texture1 forKey:@"shareTexture0"];
  [textures setImage:texture2 forKey:@"shareTexture1"];
  [textures setImage:texture3 forKey:@"shareTexture2"];
  content.effectTextures = textures;

  FBSDKCameraEffectArguments *arguments = [FBSDKCameraEffectArguments new];
  [arguments setString:@"test" forKey:@"arg0"];
  content.effectArguments = arguments;

  [FBSDKShareDialog showFromViewController:self
                               withContent:content
                                  delegate:nil];
}

- (IBAction)openEffectWithID:(id)sender
{
  UIAlertController *alertController =
  [UIAlertController alertControllerWithTitle:@"Launch Effect With ID"
                                      message:@"Enter ID and arguments of effect"
                               preferredStyle:UIAlertControllerStyleAlert];
  [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"Effect ID";
  }];
  [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
    textField.placeholder = @"Arguments (JSON)";
  }];
  [alertController addAction:[UIAlertAction actionWithTitle:@"Launch Camera"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                      [self _openCameraWithEffectID:alertController.textFields[0].text
                                                                    argumentsString:alertController.textFields[1].text];
                                                    }]];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)shareYourRun:(id)sender
{
  [self _openCameraWithEffectID:NikeRunSampleID argumentsString:NikeRunSampleArgs];
}

#pragma mark - Helper Methods

- (void)_openCameraWithEffectID:(NSString *)effectID
                argumentsString:(NSString *)argumentsString
{
  FBSDKShareCameraEffectContent *content = [FBSDKShareCameraEffectContent new];
  if ([effectID length] > 0) {
    content.effectID = effectID;
  }
  NSError *jsonError = nil;
  if ([argumentsString length] > 0) {
    NSData *jsonData = [argumentsString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
    FBSDKCameraEffectArguments *arguments = [FBSDKCameraEffectArguments new];
    [jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      if ([obj isKindOfClass:[NSString class]]) {
        [arguments setString:obj forKey:key];
      } else if ([obj isKindOfClass:[NSArray class]]) {
        [arguments setArray:obj forKey:key];
      }
    }];
    content.effectArguments = arguments;
  }

  if (jsonError) {
    UIAlertController *errorAlertController =
    [UIAlertController alertControllerWithTitle:@"Invalid JSON String"
                                        message:@"Arguments must be a JSON string. Example: {\"arg1\":\"value1\",\"arg2\":\"value2\"}"
                                 preferredStyle:UIAlertControllerStyleAlert];
    [errorAlertController addAction:[UIAlertAction actionWithTitle:@"Dismiss"
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil]];
    [self presentViewController:errorAlertController animated:YES completion:nil];
  } else {
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:nil];
  }
}

@end
