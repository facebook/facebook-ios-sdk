/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "BOGFirstViewController.h"
#import "BOGAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>
#import "OGProtocols.h"

@interface BOGFirstViewController () <UIPickerViewDelegate>

- (void)postAction:(NSString *)actionPath
       leftOperand:(BOOL)left
      rightOperand:(BOOL)right
            result:(BOOL)result
 tryReauthIfNeeded:(BOOL)tryReauthIfNeeded;
- (NSString *)stringForTruthValue:(BOOL)truthValue;
+ (id<BOGGraphTruthValue>)ogObjectForTruthValue:(BOOL)value;

@end

@implementation BOGFirstViewController

@synthesize leftPicker = _leftPicker;
@synthesize rightPicker = _rightPicker;
@synthesize resultTextView = _resultTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"You Rock!", @"You Rock!");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidUnload {
    self.leftPicker = nil;
    self.rightPicker = nil;
    self.resultTextView = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark - Button handlers

// FBSample logic
// Handler for the "And" button, determines the left and right truth values, and then
// calls a helper to post a custom action
- (IBAction)pressedAnd:(id)sender {

    BOOL left = [self.leftPicker selectedRowInComponent:0];
    BOOL right = [self.rightPicker selectedRowInComponent:0];
    BOOL result = left && right;
    self.resultTextView.text = [NSString stringWithFormat:@"%@ AND %@ = %@",
                                [self stringForTruthValue:left],
                                [self stringForTruthValue:right],
                                [self stringForTruthValue:result]];
    
    // posts an "and" OG action, the path below is the normal form for custom OG actions (in this case 'and')
    [self postAction:@"me/fb_sample_boolean_og:and" 
         leftOperand:left
        rightOperand:right
              result:result
   tryReauthIfNeeded:YES];
}

// FBSample logic
// Handler for the "Or" button, determines the left and right truth values, and then
// calls a helper to post a custom action
- (IBAction)pressedOr:(id)sender {
    
    BOOL left = [self.leftPicker selectedRowInComponent:0];
    BOOL right = [self.rightPicker selectedRowInComponent:0];
    BOOL result = left || right;
    self.resultTextView.text = [NSString stringWithFormat:@"%@ OR %@ = %@",
                                [self stringForTruthValue:left],
                                [self stringForTruthValue:right],
                                [self stringForTruthValue:result]];
    
    // posts an "or" OG action, the path below is the normal form for custom OG actions (in this case 'or')
    [self postAction:@"me/fb_sample_boolean_og:or" 
         leftOperand:left
        rightOperand:right
              result:result
   tryReauthIfNeeded:YES];
}

#pragma mark - UIPickerViewDelegate impl

// FBSample logic
// There isn't any real facebook specific logic in the next four methods, they simply wire up the
// behavior for the two picker-views
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}

- (NSString *)pickerView:(UIPickerView *)pickerView 
             titleForRow:(NSInteger)row 
            forComponent:(NSInteger)component {
    return row ? @"True" : @"False";
}

- (void)pickerView:(UIPickerView *)pickerView 
      didSelectRow:(NSInteger)row 
       inComponent:(NSInteger)component {
    self.resultTextView.text = @"";
}

#pragma mark - private methods

// FBSample logic
// This is the workhorse method of this view. It sets up the content for a custom OG action, and then posts it
// using FBRequest/FBRequestConnection. This method also uses the custom protocols defined in
// OGProtocols.h (defined in this sample application), in order to create and consume actions in a typed fashion
- (void)postAction:(NSString *)actionPath
       leftOperand:(BOOL)left
      rightOperand:(BOOL)right
            result:(BOOL)result
 tryReauthIfNeeded:(BOOL)tryReauthIfNeeded {
    
    // if we have a valid session, then we post the action to the users wall, else noop
    if (FBSession.activeSession.isOpen) {
        
        // if we don't have permission to post, let's first address that
        if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
            [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                                     defaultAudience:FBSessionDefaultAudienceFriends
                                                   completionHandler:^(FBSession *session, NSError *error) {
                                                       if (!error) {
                                                           // re-call assuming we now have the permission
                                                           [self postAction:actionPath
                                                                leftOperand:left
                                                               rightOperand:right
                                                                     result:result
                                                          tryReauthIfNeeded:NO];
                                                       }
                                                   }];
        } else {
            
            // create an object to hold our action information, the FBGraphObject class has a lightweight
            // static method API that supports creating and comparing of objects that implement the
            // FBGraphObject protocol
            id<BOGGraphBooleanAction> action = (id<BOGGraphBooleanAction>)[FBGraphObject graphObject];
            
            // set the action's results and two truth-value objects, using inferred accessor methods
            // in our custom open graph action protocol
            action.result = result ? @"1" : @"0";
            action.truthvalue = [BOGFirstViewController ogObjectForTruthValue:left];
            action.anothertruthvalue = [BOGFirstViewController ogObjectForTruthValue:right];
            
            
            // post the action using one of the lightweight static start* methods on FBRequest
            [FBRequestConnection startForPostWithGraphPath:actionPath
                                               graphObject:action
                                         completionHandler:^(FBRequestConnection *connection, id requestResult, NSError *error) {
                                             if (!error) {
                                                 // successful post, in the sample we do nothing with the id, however
                                                 // a more complex application may want to store or perform addtional actions
                                                 // with the id that represents the just-posted action
                                             } else {
                                                 // get the basic error message
                                                 NSString *message = error.localizedDescription;
                                                 
                                                 // see if we can improve on it with an error message from the server
                                                 id json = [error.userInfo objectForKey:FBErrorParsedJSONResponseKey];
                                                 id facebookError = nil;
                                                 NSDecimalNumber *code = nil;
                                                 if ([json isKindOfClass:[NSDictionary class]] &&
                                                     (json = [json objectForKey:@"body"]) &&
                                                     [json isKindOfClass:[NSDictionary class]] &&
                                                     (facebookError = [json objectForKey:@"error"]) &&
                                                     [facebookError isKindOfClass:[NSDictionary class]] &&
                                                     (json = [facebookError objectForKey:@"message"])) {
                                                     message = [json description];
                                                     code = [facebookError objectForKey:@"code"];
                                                 }
                                                 
                                                 if ([code intValue] == 200 && tryReauthIfNeeded) {
                                                     // We got an error indicating a permission is missing. This could happen if the user has gone into
                                                     // their Facebook settings and explictly removed a permission they had previously granted. Try reauthorizing
                                                     // again to get the permission back.
                                                     [FBSession.activeSession reauthorizeWithPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                                                                                behavior:FBSessionLoginBehaviorWithFallbackToWebView
                                                                                       completionHandler:^(FBSession *session, NSError *error) {
                                                                                           if (!error) {
                                                                                               // re-call assuming we now have the permission
                                                                                               [self postAction:actionPath
                                                                                                    leftOperand:left
                                                                                                   rightOperand:right
                                                                                                         result:result
                                                                                              tryReauthIfNeeded:NO];
                                                                                           }
                                                                                       }];
                                                 } else {
                                                     // display the message that we have
                                                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OG Post Failed"
                                                                                                     message:message
                                                                                                    delegate:nil
                                                                                           cancelButtonTitle:@"OK"
                                                                                           otherButtonTitles:nil];
                                                     [alert show];
                                                 }
                                             }
                                         }];
        }
    }
}

// FBSample logic
// Simple helper here to give us a readable string from a boolean value
- (NSString*)stringForTruthValue:(BOOL)truthValue  {
    return truthValue ? @"True" : @"False";
}

// FBSample logic
// This is a helper function that returns an FBGraphObject representing a truth value, either true or false
+ (id<BOGGraphTruthValue>)ogObjectForTruthValue:(BOOL)value {
    
    // NOTE! Production applications must host OG objects using a server provisioned for use by the app
    // These OG object URLs were created using the edit open graph feature of the graph tool
    // at https://developers.facebook.com/apps/
    NSString *trueURL = @"http://samples.ogp.me/369360019783304";
    NSString *falseURL = @"http://samples.ogp.me/369360256449947";
    
    // no need to create more than one of each TruthValue object, so we will store references here
    static id<BOGGraphTruthValue> trueObj = nil; 
    static id<BOGGraphTruthValue> falseObj = nil;
    
    // return, and possibly create, the correct truth value
    if (value) {
        if (!trueObj) {
            trueObj = (id<BOGGraphTruthValue>)[FBGraphObject graphObject];
            trueObj.url = trueURL;
        }
        return trueObj;
    } else {
        if (!falseObj) {
            falseObj = (id<BOGGraphTruthValue>)[FBGraphObject graphObject];
            falseObj.url = falseURL;
        }
        return falseObj;
    }
}

@end
