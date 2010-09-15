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


#import "DemoAppAppDelegate.h"
#import "DemoAppViewController.h"

@implementation DemoAppAppDelegate

@synthesize window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch
  controller = [[DemoAppViewController alloc] init];
  controller.view.frame = CGRectMake(0, 20, 320, 460);
  [window addSubview:controller.view];

  [window makeKeyAndVisible];
  return YES;

}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
  return [[controller facebook] handleOpenURL:url];
}

- (void)dealloc {
  [window release];
  [controller release];
  [super dealloc];
}


@end
