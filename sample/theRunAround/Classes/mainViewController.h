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

#import <UIKit/UIKit.h>
#import "FBLoginButton.h"
#import "FBConnect.h"
#import "UserInfo.h"
#import "MyRunViewController.h"
#import "Session.h"

@class Runs;

@interface mainViewController : UIViewController <FBSessionDelegate, 
                                                  UserInfoLoadDelegate,
                                                  UITextFieldDelegate,
                                                  FBDialogDelegate> {
  
  IBOutlet FBLoginButton* _fbButton;
  IBOutlet UIButton* _addRunButton;
  Facebook *_facebook;
  Session *_session;
  NSArray *_permissions;
  UserInfo *_userInfo;
  MyRunViewController *_myRunController;
  
  IBOutlet UITextField *_location;
  IBOutlet UITextField *_distance;
  IBOutlet UIDatePicker *_date;
  
  IBOutlet UIView *_logoutView;
  IBOutlet UIScrollView *_loginView;
  IBOutlet UIView *_headerView;
  IBOutlet UIView *_addRunView;
  
  UITableView *_friendTableView;
  NSManagedObjectContext *_managedObjectContext;
}


@property(nonatomic, retain) UIView *logoutView;
@property(nonatomic, retain) UIScrollView *loginView;
@property(nonatomic, retain) UIView *headerView;
@property(nonatomic, retain) UIView *addRunView;
@property(nonatomic, retain) MyRunViewController *myRunController;
@property(nonatomic, retain) NSManagedObjectContext *managedObjectContext;

- (IBAction) fbButtonClick: (id) sender;
- (IBAction) addRunButtonClick: (id) sender;
- (IBAction) insertRun: (id) sender;

@end
