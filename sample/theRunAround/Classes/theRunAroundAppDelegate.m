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

#import "theRunAroundAppDelegate.h"


@interface theRunAroundAppDelegate (PrivateCoreDataStack)
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end


@implementation theRunAroundAppDelegate

@synthesize window;

//////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application 
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
  // Override point for customization after application launch
  controller = [[mainViewController alloc] init];
  controller.managedObjectContext = [self managedObjectContext];
  controller.view.frame = CGRectMake(0, 20, 320, 460);
  [window addSubview:controller.view];
  
  [window makeKeyAndVisible];
  return YES;
  
}


/**
 * applicationWillTerminate: saves changes in the application's managed object 
 * context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	
  NSError *error = nil;
    if (managedObjectContext != nil) {
      if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
      }
    }
}


#pragma mark -
#pragma mark Core Data stack

/**
 * Returns the managed object context for the application.
 * If the context doesn't already exist, it is created and bound to the persistent 
 * store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
  if (managedObjectContext != nil) {
    return managedObjectContext;
  }
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil) {
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
  }
  return managedObjectContext;
}


/**
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created by merging all of the models 
 * found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
  if (managedObjectModel != nil) {
    return managedObjectModel;
  }
  managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
  return managedObjectModel;
}


/**
 * Returns the persistent store coordinator for the application.
 * If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

  if (persistentStoreCoordinator != nil) {
    return persistentStoreCoordinator;
  }
	
  NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] 
            stringByAppendingPathComponent: @"theRunAround.sqlite"]];
	
  NSError *error = nil;
  persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] 
                                initWithManagedObjectModel:[self managedObjectModel]];

  if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                configuration:nil 
                                                          URL:storeUrl 
                                                      options:nil 
                                                        error:&error]) {
  NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
  abort();
  }
    
  return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 * Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
  return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) 
          lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	
  [managedObjectContext release];
  [managedObjectModel release];
  [persistentStoreCoordinator release];
    
  [window release];
  [super dealloc];
}



@end

