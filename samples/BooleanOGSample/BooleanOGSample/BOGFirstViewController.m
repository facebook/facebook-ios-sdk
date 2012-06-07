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
#import <FBiOSSDK/FacebookSDK.h>
#import "OGProtocols.h"

@interface BOGFirstViewController () <UIPickerViewDelegate>
+ (id<BOGGraphTruthValue>)ogObjectForTruthValue:(BOOL)value;
- (void)postAction:(NSString *)actionPath
       leftOperand:(BOOL)left
      rightOperand:(BOOL)right
            result:(BOOL)result;
@end

@implementation BOGFirstViewController
@synthesize leftPicker;
@synthesize rightPicker;
@synthesize resultTextView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return row ? @"True" : @"False";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    resultTextView.text = @"";
}

							
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setLeftPicker:nil];
    [self setRightPicker:nil];
    [self setResultTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (NSString*)stringForTruthValue:(BOOL)truthValue  {
    return truthValue ? @"True" : @"False";
}

- (IBAction)pressedAnd:(id)sender {

    BOOL left = [leftPicker selectedRowInComponent:0];
    BOOL right = [rightPicker selectedRowInComponent:0];
    BOOL result = left && right;
    resultTextView.text = [NSString stringWithFormat:@"%@ AND %@ = %@",
                           [self stringForTruthValue:left],
                           [self stringForTruthValue:right],
                           [self stringForTruthValue:result]];
    
    // posts an "And" OG action
    [self postAction:@"me/fb_sample_boolean_og:and" 
         leftOperand:left
        rightOperand:right
              result:result];
}

- (IBAction)pressedOr:(id)sender {
    
    BOOL left = [leftPicker selectedRowInComponent:0];
    BOOL right = [rightPicker selectedRowInComponent:0];
    BOOL result = left || right;
    resultTextView.text = [NSString stringWithFormat:@"%@ OR %@ = %@",
                           [self stringForTruthValue:left],
                           [self stringForTruthValue:right],
                           [self stringForTruthValue:result]];
    
    // posts an "Or" OG action
    [self postAction:@"me/fb_sample_boolean_og:or" 
         leftOperand:left
        rightOperand:right
              result:result];
}

- (void)postAction:(NSString *)actionPath
       leftOperand:(BOOL)left
      rightOperand:(BOOL)right
            result:(BOOL)result {
    // if we have a valid session, then we post the action to the users wall
    BOGAppDelegate* appDelegate = (BOGAppDelegate*)[UIApplication sharedApplication].delegate;
    if (appDelegate.session.isOpen) {
        
        // create an object to hold our action information
        id<BOGGraphBooleanAction> action = (id<BOGGraphBooleanAction>)[FBGraphObject graphObject];
        
        // set the ation's results and two truth-value objects
        action.result = result ? @"1" : @"0";
        action.truthvalue = [BOGFirstViewController ogObjectForTruthValue:left];
        action.anothertruthvalue = [BOGFirstViewController ogObjectForTruthValue:right];
        
        // create the request and post the action
        FBRequest *req = [[FBRequest alloc] initForPostWithSession:appDelegate.session
                                                         graphPath:actionPath
                                                       graphObject:action];
        FBRequestConnection *conn = [[FBRequestConnection alloc] init];
        [conn addRequest:req completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // successful post, do something with the action id    
            } 
        } ];
        
        [conn start];
    }
}

+ (id<BOGGraphTruthValue>)ogObjectForTruthValue:(BOOL)value {
    // this URL is specific to this sample, and can be used to create arbitrary
    // OG objects for this app; your OG objects will have URLs hosted by your server
    NSString *format =  
        @"http://fbsdkog.herokuapp.com/repeater.php?"
        @"fb:app_id=369258453126794&og:type=fb_sample_boolean_og:truthvalue&"
        @"og:title=%@&og:description=%%22%@%%22&og:image=http://fbsdkog.herokuapp.com/%@&body=%@";
    
    // no need to create more than one of each TruthValue object
    static id<BOGGraphTruthValue> trueObj = nil; 
    static id<BOGGraphTruthValue> falseObj = nil;
    
    // return, and possibly create, the correct truth value
    if (value) {
        if (!trueObj) {
            trueObj = (id<BOGGraphTruthValue>)[FBGraphObject graphObject];
            trueObj.url = [NSString stringWithFormat:format, @"True", @"Not%20False", @"1.jpg", @"True"];
        }
        return trueObj;
    } else {
        if (!falseObj) {
            falseObj = (id<BOGGraphTruthValue>)[FBGraphObject graphObject];
            falseObj.url = [NSString stringWithFormat:format, @"False", @"Not%20True", @"0.jpg", @"False"];
        }
        return falseObj;
    }
}

@end
