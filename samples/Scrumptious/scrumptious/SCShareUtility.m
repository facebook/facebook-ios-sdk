/*
 * Copyright 2010-present Facebook.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "SCShareUtility.h"

#import "SCProtocols.h"

@implementation SCShareUtility
{
    NSArray *_friends;
    NSString *_mealTitle;
    UIImage *_photo;
    id<FBGraphPlace> _place;
    NSUInteger _retryCount;
    int _sendAsMessageButtonIndex;
}

- (instancetype)initWithMealTitle:(NSString *)mealTitle place:(id<FBGraphPlace>)place friends:(NSArray *)friends photo:(UIImage *)photo
{
    if ((self = [super init])) {
        _mealTitle = [mealTitle copy];
        _place = place;
        _friends = [friends copy];
        _photo = [self _normalizeImage:photo];
    }
    return self;
}

- (void)start
{
    if ([FBSession activeSession].isOpen) {
        // Attempt to post immediately - note the error handling logic will request permissions
        // if they are needed.
        [self _postOpenGraphAction];
    } else {
        FBOpenGraphActionParams *params = [self _openGraphActionParams];
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                            delegate:self
                                                   cancelButtonTitle:nil
                                              destructiveButtonTitle:nil
                                                   otherButtonTitles:nil];
        _sendAsMessageButtonIndex = -1;
        if ([FBDialogs canPresentMessageDialogWithOpenGraphActionParams:params]) {
            _sendAsMessageButtonIndex = (int) [sheet addButtonWithTitle:@"Send with Messenger"];
        }
        if ([FBDialogs canPresentShareDialogWithOpenGraphActionParams:params]) {
            [sheet addButtonWithTitle:@"Share on Facebook"];
        }
        if (sheet.numberOfButtons == 0) {
            [self.delegate shareUtilityUserShouldLogin:self];
        } else {
            [sheet addButtonWithTitle:@"Cancel"];
            sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
            [sheet showInView:self.delegate.view];
        }
    }
}

- (id<SCOGEatMealAction>)_actionForSharing
{
    // Create an Open Graph eat action with the meal, our location, and the people we were with.
    id<SCOGEatMealAction> action = (id<SCOGEatMealAction>)[FBGraphObject graphObject];
    action.image = @"http://facebooksampleapp.com/scrumptious/static/images/logo.png";

    if (_place) {
        // Facebook SDK * pro-tip *
        // We don't use the action.place syntax here because, unfortunately, setPlace:
        // and a few other selectors may be flagged as reserved selectors by Apple's App Store
        // validation tools.  While this doesn't necessarily block App Store approval, it
        // could slow down the approval process.  Falling back to the setObject:forKey:
        // selector is a useful technique to avoid such naming conflicts.
        [action setObject:_place forKey:@"place"];
    }

    if (_friends.count > 0) {
        [action setObject:_friends forKey:@"tags"];
    }

    return action;
}

- (void)_postOpenGraphAction
{
    [self.delegate shareUtilityWillShare:self];
    FBRequestConnection *requestConnection = [[FBRequestConnection alloc] init];
    requestConnection.errorBehavior = (FBRequestConnectionErrorBehaviorRetry | FBRequestConnectionErrorBehaviorReconnectSession);

    __weak SCShareUtility *weakSelf = self;

    id<SCOGEatMealAction> action = [self _actionForSharing];

    // Get the existing meal object if it exists, otherwise create a new OG object for it
    id<SCOGMeal> meal = [self _existingMealWithTitle:_mealTitle];
    if (meal) {
        action.meal = meal;
    } else {
        meal = (id<SCOGMeal>)[FBGraphObject openGraphObjectForPostWithType:@"fb_sample_scrumps:meal"
                                                                     title:_mealTitle
                                                                     image:nil
                                                                       url:nil
                                                               description:[@"Delicious " stringByAppendingString:_mealTitle]];

        // Create the object as part of the batch request.
        FBRequest *createObjectRequest = [FBRequest requestForPostOpenGraphObject:meal];
        [requestConnection addRequest:createObjectRequest
                    completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        if (error) {
                            SCShareUtility *strongSelf = weakSelf;
                            [strongSelf _handlePostOpenGraphActionError:error];
                        }
                    }
                       batchEntryName:@"createobject"];
        // Set the meal property on the action based on the create object response.
        action[@"meal"] = @"{result=createobject:$.id}";
    }

    if (_photo) {
        // Upload the photo as part of the batch request
        FBRequest *photoStagingRequest = [FBRequest requestForUploadStagingResourceWithImage:_photo];
        [requestConnection addRequest:photoStagingRequest
                    completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        if (error) {
                            SCShareUtility *strongSelf = weakSelf;
                            [strongSelf _handlePostOpenGraphActionError:error];
                        }
                    }
                       batchEntryName:@"stagedphoto"];
        // Set the image property on the action based on the upload response.
        action.image = @[@{
                             @"url": @"{result=stagedphoto:$.uri}",
                             @"user_generated": @"true",
                             }];
    }

    // Create the request for the action and add it to the batch.
    FBRequest *actionRequest = [FBRequest requestForPostWithGraphPath:@"me/fb_sample_scrumps:eat" graphObject:action];
    [requestConnection addRequest:actionRequest completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        SCShareUtility *strongSelf = weakSelf;
        if (result) {
            [[[UIAlertView alloc] initWithTitle:@"Result"
                                        message:[@"Posted Open Graph action, id: " stringByAppendingString:result[@"id"]]
                                       delegate:nil
                              cancelButtonTitle:@"Thanks!"
                              otherButtonTitles:nil]
             show];

            [strongSelf.delegate shareUtilityDidCompleteShare:strongSelf];
        } else {
            [strongSelf _handlePostOpenGraphActionError:error];
        }
    }];

    [requestConnection start];
}

- (FBOpenGraphActionParams *)_openGraphActionParams {
    id<SCOGEatMealAction> action = [self _actionForSharing];

    // Get the existing meal object if it exists, otherwise create a new OG object for it
    action.meal = (id<SCOGMeal>)[FBGraphObject openGraphObjectForPostWithType:@"fb_sample_scrumps:meal"
                                                                        title:_mealTitle
                                                                        image:nil
                                                                          url:nil
                                                                  description:[@"Delicious " stringByAppendingString:_mealTitle]];

    if (_photo) {
        action.image = @[@{
                             @"url": _photo,
                             @"user_generated": @"true",
                             }];
    }

    FBOpenGraphActionParams *params = [[FBOpenGraphActionParams alloc] initWithAction:action
                                                                           actionType:@"fb_sample_scrumps:eat"
                                                                  previewPropertyName:@"meal"];
    return params;
}

- (void)_presentShareDialogWithParams:(FBOpenGraphActionParams *)params isMessageShare:(BOOL)isMessageShare
{
    __weak SCShareUtility *weakSelf = self;
    FBDialogAppCallCompletionHandler handler = ^(FBAppCall *call, NSDictionary *results, NSError *error) {
        SCShareUtility *strongSelf = weakSelf;
        if (error) {
            [strongSelf.delegate shareUtility:strongSelf didFailWithError:error];
        } else {
            [strongSelf.delegate shareUtilityDidCompleteShare:strongSelf];
        };
    };

    FBAppCall *appCall = nil;
    if (isMessageShare) {
        appCall = [FBDialogs presentMessageDialogWithOpenGraphActionParams:params
                                                               clientState:nil
                                                                   handler:handler];
    } else {
        appCall = [FBDialogs presentShareDialogWithOpenGraphActionParams:params
                                                             clientState:nil
                                                                 handler:handler];
    }

    if (!appCall) {
        // this means that the Facebook app is not installed or up to date
        // if the share dialog is not available, lets encourage a login so we can share directly
        [self.delegate shareUtilityUserShouldLogin:self];
    }
}

- (id<SCOGMeal>)_existingMealWithTitle:(NSString *)title
{
    // We create an FBGraphObject object, but we can treat it as an SCOGMeal with typed
    // properties, etc. See <FacebookSDK/FBGraphObject.h> for more details.
    id<SCOGMeal> result = (id<SCOGMeal>)[FBGraphObject graphObject];

    // Give it a URL of sample data that contains the object's name, title, description, and body.
    // These OG object URLs were created using the edit open graph feature of the graph tool
    // at https://www.developers.facebook.com/apps/
    if ([title isEqualToString:@"Cheeseburger"]) {
        result.url = @"http://samples.ogp.me/314483151980285";
    } else if ([title isEqualToString:@"Pizza"]) {
        result.url = @"http://samples.ogp.me/314483221980278";
    } else if ([title isEqualToString:@"Hotdog"]) {
        result.url = @"http://samples.ogp.me/314483265313607";
    } else if ([title isEqualToString:@"Italian"]) {
        result.url = @"http://samples.ogp.me/314483348646932";
    } else if ([title isEqualToString:@"French"]) {
        result.url = @"http://samples.ogp.me/314483375313596";
    } else if ([title isEqualToString:@"Chinese"]) {
        result.url = @"http://samples.ogp.me/314483421980258";
    } else if ([title isEqualToString:@"Thai"]) {
        result.url = @"http://samples.ogp.me/314483451980255";
    } else if ([title isEqualToString:@"Indian"]) {
        result.url = @"http://samples.ogp.me/314483491980251";
    } else {
        return nil;
    }
    return result;
}

- (void)_handlePostOpenGraphActionError:(NSError *)error {
    // Facebook SDK * error handling *
    // Some Graph API errors are retriable. For this sample, we will have a simple
    // retry policy of one additional attempt. Please refer to
    // https://developers.facebook.com/docs/reference/api/errors/ for more information.
    _retryCount++;
    FBErrorCategory errorCategory = [FBErrorUtility errorCategoryForError:error];
    if (errorCategory == FBErrorCategoryThrottling) {
        // We also retry on a throttling error message. A more sophisticated app
        // should consider a back-off period.
        if (_retryCount < 2) {
            NSLog(@"Retrying open graph post");
            [self _postOpenGraphAction];
            return;
        } else {
            NSLog(@"Retry count exceeded.");
        }
    }

    // Facebook SDK * pro-tip *
    // Users can revoke post permissions on your app externally so it
    // can be worthwhile to request for permissions again at the point
    // that they are needed. This sample assumes a simple policy
    // of re-requesting permissions.
    if (errorCategory == FBErrorCategoryPermissions) {
        NSLog(@"Re-requesting permissions");
        [self _requestPermissionAndPost];
        return;
    }

    // Facebook SDK * error handling *
    [self.delegate shareUtility:self didFailWithError:error];
}

// Helper method to request publish permissions and post.
- (void)_requestPermissionAndPost {
    __weak SCShareUtility *weakSelf = self;
    [[FBSession activeSession] requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                            defaultAudience:FBSessionDefaultAudienceFriends
                                          completionHandler:^(FBSession *session, NSError *error) {
                                              SCShareUtility *strongSelf = weakSelf;
                                              if (error) {
                                                  // Facebook SDK * error handling *
                                                  // if the operation is not user cancelled
                                                  if ([FBErrorUtility errorCategoryForError:error] != FBErrorCategoryUserCancelled) {
                                                      [strongSelf.delegate shareUtility:strongSelf didFailWithError:error];
                                                      return;
                                                  }
                                              } else if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] != NSNotFound) {
                                                  // Now we have the permission
                                                  [strongSelf _postOpenGraphAction];
                                                  return;
                                              }

                                              // User cancelled
                                              [strongSelf.delegate shareUtilityDidCompleteShare:strongSelf];
                                          }];
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
        [self.delegate shareUtility:self didFailWithError:nil];
    } else if (buttonIndex == _sendAsMessageButtonIndex) {
        [self _presentShareDialogWithParams:[self _openGraphActionParams] isMessageShare:YES];
    } else {
        [self _presentShareDialogWithParams:[self _openGraphActionParams] isMessageShare:NO];
    }
}

@end
