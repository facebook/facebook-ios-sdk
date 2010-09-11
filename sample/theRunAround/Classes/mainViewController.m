/*
 * Copyright 2010 Facebook
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

#import "mainViewController.h"
#import "FBConnect.h"
#import "Runs.h"
#import "Session.h"



// Your Facebook App Id must be set before running this example
// See http://www.facebook.com/developers/createapp.php
static NSString* kAppId = nil;

@implementation mainViewController

@synthesize managedObjectContext = _managedObjectContext,      
            logoutView = _logoutView,
            loginView  = _loginView,
            headerView = _headerView,
            addRunView = _addRunView,
       myRunController = _myRunController;

///////////////////////////////////////////////////////////////////////////////////////////////////
// Private helper function for login / logout

- (void) login {
  [_facebook authorize:kAppId permissions:_permissions delegate:self];
}

- (void) logout {
  [_session unsave];
  [_facebook logout:self]; 
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// Public

/**
 * initialization
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    _permissions =  [[NSArray arrayWithObjects: 
                      @"publish_stream",@"read_stream", @"offline_access",nil] retain];
      
  }
  return self;
}


- (void)viewDidLoad {
  [super viewDidLoad];
 
  _location.keyboardType = UIKeyboardTypeDefault;
  _location.returnKeyType = UIReturnKeyDone;
  _location.delegate = self;
  _distance.returnKeyType = UIReturnKeyDone;
  _distance.delegate = self;
  
  _session = [[Session alloc] init];
  _facebook = [[_session restore] retain];
  if (_facebook == nil) {
    _facebook = [[Facebook alloc] init];
    _fbButton.isLoggedIn = NO;
    _addRunButton.hidden = YES;
    [self.view addSubview:self.logoutView];
  } else {
    _fbButton.isLoggedIn = YES;
    _addRunButton.hidden = NO;
    [self fbDidLogin];
    [self.view addSubview:self.loginView];
  }

  [_fbButton updateImage];
  [[self view] addSubview:[self headerView]];
  [_headerView addSubview:_fbButton];

  
  
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return NO;
}

- (void)dealloc {
  
  [_facebook release];
  [_permissions release];
  [_userInfo release];
  [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// IBAction

/**
 * IBAction for login/logout button click
 */
- (IBAction) fbButtonClick: (id) sender {
  if (_fbButton.isLoggedIn) {
    [self logout];
  } else {
    [self login];
  }
}

/**
 * IBAction for Add New Run button click
 */
- (IBAction) addRunButtonClick: (id) sender {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.75];     
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight 
                         forView:self.view cache:YES];

  [_loginView removeFromSuperview];
  [_headerView removeFromSuperview];
  

  [self.view  addSubview:self.addRunView];
  [UIView commitAnimations];
}

/**
 * IBAction for Add My Run button click
 */
- (IBAction) insertRun: (id) sender{
  
  NSEntityDescription *runEntity = [NSEntityDescription entityForName:@"Runs" 
                                               inManagedObjectContext:_managedObjectContext];
  Runs *newRun = [[[NSManagedObject alloc] initWithEntity:runEntity 
                           insertIntoManagedObjectContext:_managedObjectContext] autorelease];
  newRun.location = _location.text;

  NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
  newRun.facebookUid = [f numberFromString:_userInfo.uid];

  newRun.date = _date.date;
  
  if (_distance.text) {
    newRun.distance = [f numberFromString:_distance.text]; 
  }
  
  [f release];
  
  NSError *error = nil;
  if (![_managedObjectContext save:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
  }
  
  [_addRunView removeFromSuperview]; 
  [self.view addSubview:_headerView];
  _myRunController.managedObjectContext = _managedObjectContext;
  [self.myRunController viewWillAppear:YES];
  [self.view addSubview:_loginView];
  
  
  SBJSON *jsonWriter = [[SBJSON new] autorelease];
  

  NSDictionary* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys: 
                               @"Always Running",@"text",@"http://itsti.me/",@"href", nil], nil];
  
  NSString *actionLinksStr = [jsonWriter stringWithObject:actionLinks];
  
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  [dateFormatter setDateStyle:NSDateFormatterShortStyle];
  
  NSString *caption = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@", 
    @"I run",_distance.text, @"miles at", _location.text ,@"on",
                       [dateFormatter stringFromDate:_date.date]];
  NSDictionary* attachment = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"I Started Running", @"name",
                              caption, @"caption",
                              @"It finally happened, I started exercising.", @"description",
                              @"http://itsti.me/", @"href", nil];
  NSString *attachmentStr = [jsonWriter stringWithObject:attachment];
  
                       
  NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 kAppId, @"api_key",
                                 @"Tell the world you are running",  @"user_message_prompt",
                                  actionLinksStr, @"action_links",
                                 attachmentStr, @"attachment",
                                 nil];
  [dateFormatter release];
  
  [_facebook dialog: @"stream.publish"
          andParams: params
        andDelegate: self];
  
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// Delegates

/**
 * FBSessionDelegate
 */ 
-(void) fbDidLogin {
  [_logoutView removeFromSuperview];
  [_addRunView removeFromSuperview];

   _fbButton.isLoggedIn         = YES;
  [_fbButton updateImage];
  _addRunButton.hidden = NO;
  
  _userInfo = [[[[UserInfo alloc] initializeWithFacebook:_facebook andDelegate: self] 
                autorelease] 
               retain];
  [_userInfo requestAllInfo];
  
  [self.view addSubview:self.loginView];
}

/**
 * FBSessionDelegate
 */ 
-(void) fbDidLogout {
  [_session unsave];
  [_loginView removeFromSuperview];
  [self.view addSubview:_logoutView];
  _fbButton.isLoggedIn         = NO;
  [_fbButton updateImage];
  _addRunButton.hidden = YES;
}

/*
 * UserInfoLoadDelegate
 */
- (void)userInfoDidLoad {
  [_session setSessionWithFacebook:_facebook andUid:_userInfo.uid];
  [_session save];
  
  _myRunController = [[MyRunViewController alloc] init];
  _myRunController.managedObjectContext = _managedObjectContext;
  _myRunController.userInfo = _userInfo;
  _myRunController.view.frame = CGRectMake(0, 0, 320, 460);
  [self.myRunController viewWillAppear:YES];
  [_loginView addSubview:self.myRunController.view];
}

- (void)userInfoFailToLoad {
  [self logout]; 
  _fbButton.isLoggedIn = NO;
  _addRunButton.hidden = YES;
  [self.view addSubview:self.logoutView];
  
}
/**
 * UITextFieldDelegate
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}


@end
