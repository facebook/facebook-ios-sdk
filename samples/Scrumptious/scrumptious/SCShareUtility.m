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

#import "SCShareUtility.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <FBSDKLoginKit/FBSDKLoginKit.h>

@implementation SCShareUtility
{
    NSString *_mealTitle;
    FBSDKMessageDialog *_messageDialog;
    UIImage *_photo;
    int _sendAsMessageButtonIndex;
    FBSDKShareAPI *_shareAPI;
    FBSDKShareDialog *_shareDialog;
    NSArray *_friends;
    NSString *_place;
}

- (instancetype)initWithMealTitle:(NSString *)mealTitle place:(NSString *)place friends:(NSArray *)friends photo:(UIImage *)photo
{
    if ((self = [super init])) {
        _mealTitle = [mealTitle copy];
        _photo = [self _normalizeImage:photo];
        _place = [place copy];
        _friends = [friends copy];

        FBSDKShareOpenGraphContent *shareContent = [self contentForSharing];

        _shareAPI = [[FBSDKShareAPI alloc] init];
        _shareAPI.delegate = self;
        _shareAPI.shareContent = shareContent;

        _shareDialog = [[FBSDKShareDialog alloc] init];
        _shareDialog.delegate = self;
        _shareDialog.shouldFailOnDataError = YES;
        _shareDialog.shareContent = shareContent;

        _messageDialog = [[FBSDKMessageDialog alloc] init];
        _messageDialog.delegate = self;
        _messageDialog.shouldFailOnDataError = YES;
        _messageDialog.shareContent = shareContent;
    }
    return self;
}

- (void)dealloc
{
    _shareAPI.delegate = nil;
    _shareDialog.delegate = nil;
    _messageDialog.delegate = nil;
}

- (void)start
{
    [self _postOpenGraphAction];
}

- (FBSDKShareOpenGraphContent *)contentForSharing
{
    NSString *previewPropertyName = @"fb_sample_scrumps:meal";

    if (!_mealTitle) {
        return nil;
    }

    id object = [self _existingMealURLWithTitle:_mealTitle];
    if (!object) {
        NSDictionary *objectProperties = @{
                                           @"og:type" : @"fb_sample_scrumps:meal",
                                           @"og:title": _mealTitle,
                                           @"og:description" : [@"Delicious " stringByAppendingString:_mealTitle],
                                           };
        object = [FBSDKShareOpenGraphObject objectWithProperties:objectProperties];
    }

    FBSDKShareOpenGraphAction *action = [[FBSDKShareOpenGraphAction alloc] init];
    action.actionType = @"fb_sample_scrumps:eat";
    [action setObject:object forKey:previewPropertyName];
    if (_photo) {
        [action setArray:@[[FBSDKSharePhoto photoWithImage:_photo userGenerated:YES]] forKey:@"og:image"];
    }

    FBSDKShareOpenGraphContent *content = [[FBSDKShareOpenGraphContent alloc] init];
    content.action = action;
    content.previewPropertyName = previewPropertyName;
    if (_friends.count > 0) {
        content.peopleIDs = _friends;
    }
    if (_place.length) {
        content.placeID = _place;
    }
    return content;
}

- (void)_postOpenGraphAction
{
    NSString *const publish_actions = @"publish_actions";
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:publish_actions]) {
        [self.delegate shareUtilityWillShare:self];
        [_shareAPI share];
    } else {
        [[[FBSDKLoginManager alloc] init]
         logInWithPublishPermissions:@[publish_actions]
         fromViewController:nil
         handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
             if ([result.grantedPermissions containsObject:publish_actions]) {
                 [self.delegate shareUtilityWillShare:self];
                 [_shareAPI share];
             } else {
                 // This would be a nice place to tell the user why publishing
                 // is valuable.
                 [_delegate shareUtility:self didFailWithError:nil];
             }
         }];
    }
}

- (NSString *)_existingMealURLWithTitle:(NSString *)title
{
    // Give it a URL of sample data that contains the object's name, title, description, and body.
    // These OG object URLs were created using the edit open graph feature of the graph tool
    // at https://www.developers.facebook.com/apps/
    if ([title isEqualToString:@"Cheeseburger"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/cheeseburger.html";
    } else if ([title isEqualToString:@"Pizza"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/pizza.html";
    } else if ([title isEqualToString:@"Hotdog"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/hotdog.html";
    } else if ([title isEqualToString:@"Italian"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/italian.html";
    } else if ([title isEqualToString:@"French"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/french.html";
    } else if ([title isEqualToString:@"Chinese"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/chinese.html";
    } else if ([title isEqualToString:@"Thai"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/thai.html";
    } else if ([title isEqualToString:@"Indian"]) {
        return @"https://d3uu10x6fsg06w.cloudfront.net/scrumptious-facebook/indian.html";
    } else {
        return nil;
    }
}

- (UIImage *)_normalizeImage:(UIImage *)image
{
    if (!image) {
        return nil;
    }

    CGImageRef imgRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGSize imageSize = bounds.size;
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;

    switch (orient) {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;

        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;

        default:
            // image is not auto-rotated by the photo picker, so whatever the user
            // sees is what they expect to get. No modification necessary
            transform = CGAffineTransformIdentity;
            break;
    }

    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    if ((image.imageOrientation == UIImageOrientationDown) ||
        (image.imageOrientation == UIImageOrientationRight) ||
        (image.imageOrientation == UIImageOrientationUp)) {
        // flip the coordinate space upside down
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -height);
    }

    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return imageCopy;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [_delegate shareUtility:self didFailWithError:nil];
    } else if (buttonIndex == _sendAsMessageButtonIndex) {
        [_messageDialog show];
    } else {
        _shareDialog.fromViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [_shareDialog show];
    }
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    [_delegate shareUtilityDidCompleteShare:self];
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    [_delegate shareUtility:self didFailWithError:error];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    [_delegate shareUtility:self didFailWithError:nil];
}

@end
