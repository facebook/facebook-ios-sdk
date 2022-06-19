// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "HRTCodelessIndexer.h"

#import <AdSupport/AdSupport.h>
#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/utsname.h>

#import "HRTBasicUtility.h"
#import "HRTCodelessMacros.h"
#import "HRTInternalUtility.h"
#import "HRTSwizzler.h"
#import "HRTUtility.h"
#import "HRTViewHierarchy.h"

static void sw_dispatch_on_default_thread(dispatch_block_t block)
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

static void sw_dispatch_on_main_thread(dispatch_block_t block)
{
  dispatch_async(dispatch_get_main_queue(), block);
}

@implementation HRTCodelessIndexer

static NSTimer *_appIndexingTimer;
static NSString *_lastTreeHash;

static BOOL isShowingEventSelection;

static NSArray *standardEvents;
static NSArray *eventNames;

static NSMutableArray *recordedData;
static NSMutableSet *failedData;

+ (void)load
{
  NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
  if (![bundleID hasPrefix:@"com.apple"]) {
    [self setup];
  }
}

+ (void)setup
{
  recordedData = [NSMutableArray array];
  failedData = [NSMutableSet set];
  // Setup events
  standardEvents = @[
    @"No event",
    @"View a Content or Product Page",
    @"Add Item to Cart",
    @"Add Payment Info",
    @"Complete Registration or Sign Up",
    @"Contact",
    @"Donate",
    @"Initiate Checkout",
    @"Lead or Referral",
    @"Purchase",
    @"Search",
    @"Start a Trial",
    @"Subscribe"
  ];
  NSMutableArray *names = [NSMutableArray array];
  for (NSString *event in standardEvents) {
    NSArray *strs = [[event stringByReplacingOccurrencesOfString:@"fb_mobile_" withString:@""] componentsSeparatedByString:@"_"];
    NSMutableString *mutstr = [NSMutableString string];
    for (NSString *str in strs) {
      [mutstr appendString:[str capitalizedString]];
    }
    [names addObject:[mutstr copy]];
  }
  eventNames = [names copy];

  sw_dispatch_on_main_thread(^{
    // Setup gesture
    [self setupGesture];
    // Setup action listener
    [self setupActionListener];
  });
}

+ (void)setupActionListener
{
  // Button
  [HRTSwizzler swizzleSelector:@selector(didMoveToWindow) onClass:[UIControl class] withBlock:^(UIControl *control) {
                                                                                      if ([control isKindOfClass:[UISwitch class]] || [control isKindOfClass:[UISegmentedControl class]]) {
                                                                                        return;
                                                                                      }
                                                                                      if (control.window) {
                                                                                        [control addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchDown];
                                                                                      }
                                                                                    } named:@"ButtonListener"];

  // UITableView
  void (^tableViewBlock)(id, SEL, id) =
  ^(id t0, SEL c0, id<UITableViewDelegate> delegate) {
    if (!delegate) {
      return;
    }

    void (^block)(id, SEL, id, id) = ^(id target, SEL command, UITableView *tableView, NSIndexPath *indexPath) {
      [self recordActionView:tableView];
    };

    [HRTSwizzler swizzleSelector:@selector(tableView:didSelectRowAtIndexPath:)
                         onClass:[delegate class]
                       withBlock:block
                           named:@"TableViewSelectCell"];
  };
  [HRTSwizzler swizzleSelector:@selector(setDelegate:)
                       onClass:[UITableView class]
                     withBlock:tableViewBlock
                         named:@"TableViewListener"];
  // UICollectionView
  void (^collectionViewBlock)(id, SEL, id) =
  ^(id t0, SEL c0, id<UICollectionViewDelegate> delegate) {
    if (nil == delegate) {
      return;
    }

    void (^block)(id, SEL, id, id) = ^(id target, SEL command, UICollectionView *collectionView, NSIndexPath *indexPath) {
      [HRTCodelessIndexer recordActionView:collectionView];
    };

    [HRTSwizzler swizzleSelector:@selector(collectionView:didSelectItemAtIndexPath:)
                         onClass:[delegate class]
                       withBlock:block
                           named:@"CollectionViewSelectCell"];
  };
  [HRTSwizzler swizzleSelector:@selector(setDelegate:)
                       onClass:[UICollectionView class]
                     withBlock:collectionViewBlock
                         named:@"CollectionViewListener"];
}

+ (void)buttonClicked:(UIControl *)control
{
  NSLog(@"Button Clicked");
  [HRTCodelessIndexer recordActionView:control];
}

+ (void)recordActionView:(UIView *)view
{
  sw_dispatch_on_main_thread(^{
    [self tagView:view block:^{
      NSString *currentTree = [HRTCodelessIndexer currentViewTreeInteracted:view];
      if (currentTree) {
        [recordedData addObject:currentTree];
        while (recordedData.count > 5) {
          [recordedData removeObjectAtIndex:0];
        }

        [self uploadEvent:@"_action" recorded:@[currentTree]];
      }
    }];
  });
}

+ (void)tagView:(UIView *)view block:(void (^)(void))block
{
  CGFloat w = view.layer.borderWidth;
  CGColorRef c = view.layer.borderColor;
  view.layer.borderWidth = 2;
  view.layer.borderColor = [UIColor redColor].CGColor;
  block();
  view.layer.borderWidth = w;
  view.layer.borderColor = c;
}

+ (void)clearBorder:(UIView *)view
{
  view.layer.borderWidth = 0;
  view.layer.borderColor = [UIColor clearColor].CGColor;
}

+ (void)setupGesture
{
  NSLog(@"Gesture Set");
  [UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
  Class class = [UIApplication class];

  [HRTSwizzler swizzleSelector:@selector(motionBegan:withEvent:) onClass:class withBlock:^{
                                                                                 // Shaked
                                                                                 [self showEventSelection];
                                                                               } named:@"motionBegan"];
}

+ (void)showEventSelection
{
  if (isShowingEventSelection) {
    return;
  }

  isShowingEventSelection = YES;

  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Choose Event" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
  void (^handler)(UIAlertAction *action) = ^(UIAlertAction *_Nonnull action) {
    isShowingEventSelection = NO;
    [self recordEvent:action.title];
  };

  for (NSString *name in eventNames) {
    [alert addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:handler]];
  }

  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:handler]];

  UIViewController *vc = [HRTInternalUtility topMostViewController];
  alert.popoverPresentationController.sourceView = vc.view;
  [vc presentViewController:alert animated:YES completion:nil];
}

+ (void)recordEvent:(NSString *)name
{
  if (![eventNames containsObject:name]) {
    return;
  }
  NSString *event = [standardEvents objectAtIndex:[eventNames indexOfObject:name]];
  NSArray *dataToUpload = [recordedData copy];
  [recordedData removeAllObjects];

  [self uploadEvent:event recorded:dataToUpload];
}

+ (void)uploadEvent:(NSString *)event recorded:(NSArray *)data
{
  NSBundle *bundle = [NSBundle mainBundle];

  NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
  parameters[@"platform"] = @"iOS";
  parameters[@"event"] = event;
  parameters[@"bundle_id"] = bundle.bundleIdentifier;
  parameters[@"app_name"] = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [bundle objectForInfoDictionaryKey:@"CFBundleName"];
  parameters[@"metadata"] = data;

  sw_dispatch_on_default_thread(^{
    NSLog(@"Start uploading");
    [self upload:parameters];
  });
}

+ (void)upload:(NSDictionary *)data
{
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.marsmobile.com/rt.php"]
                                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                     timeoutInterval:300];
  [request setHTTPMethod:@"POST"];
  // NSMutableString *str = [NSMutableString string];
  //
  // for (NSString *key in data.allKeys) {
  // if (str.length == 0) {
  // [str appendFormat:@"%@=%@", key, [HRTUtility URLEncode:[data objectForKey:key]]];
  // } else {
  // [str appendFormat:@"&%@=%@", key, [HRTUtility URLEncode:[data objectForKey:key]]];
  // }
  // }

  [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
  NSData *json = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
  [request setValue:[NSString stringWithFormat:@"%d", (int)json.length] forHTTPHeaderField:@"Content-Length"];
  // [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
  [request setHTTPBody:json];
  // [request setHTTPBody:[@"a=c" dataUsingEncoding:NSUTF8StringEncoding]];

  NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];

  if (response) {
    NSString *responseString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSLog(@"Response String: %@", responseString);
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:response options:0 error:nil];
    if ([[dict objectForKey:@"status"] intValue] == 200) {
      NSLog(@"Succeeded");
    } else {
      NSLog(@"Failed to upload, message: %@", [dict objectForKey:@"message"]);
    }
    if ([failedData containsObject:data]) {
      [failedData removeObject:data];
    }
  } else {
    [failedData addObject:data];
    NSLog(@"Failed to coonect to server");
  }
}

+ (NSString *)currentViewTree
{
  return [self currentViewTreeInteracted:nil];
}

+ (NSString *)currentViewTreeInteracted:(UIView *)interactedView
{
  NSMutableArray *trees = [NSMutableArray array];

  NSMutableSet<NSObject *> *objSet = [NSMutableSet set];
  NSArray *windows = [UIApplication sharedApplication].windows;
  for (UIWindow *window in windows) {
    NSDictionary *tree = [HRTCodelessIndexer recursiveCaptureTree:window
                                                withInteractedObj:interactedView
                                                          withSet:objSet];
    if (tree) {
      if (window.isKeyWindow) {
        [trees insertObject:tree atIndex:0];
      } else {
        [trees addObject:tree];
      }
    }
  }

  if (0 == trees.count) {
    return nil;
  }

  NSArray *viewTrees = [trees reverseObjectEnumerator].allObjects;
  UIImage *ss = [HRTCodelessIndexer imageWithImage:[HRTCodelessIndexer screenshot] scaledToWidth:400];
  NSData *data = UIImageJPEGRepresentation(ss, 0.5);
  NSString *screenshot = [data base64EncodedStringWithOptions:0];
  NSString *screenName = @"";
  UIViewController *topMostController = [HRTCodelessIndexer topMostViewController];
  if (topMostController) {
    screenName = [NSString stringWithUTF8String:class_getName(topMostController.class)];
  }

  NSMutableDictionary *treeInfo = [NSMutableDictionary dictionary];

  treeInfo[@"view"] = viewTrees;
  treeInfo[@"screenshot"] = screenshot ?: @"";
  treeInfo[@"screenname"] = screenName;

  NSString *tree = nil;
  data = [NSJSONSerialization dataWithJSONObject:treeInfo options:0 error:nil];
  if (data) {
    tree = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  }

  return tree;
}

+ (UIWindow *)findWindow
{
  UIWindow *window = [UIApplication sharedApplication].keyWindow;
  if (window == nil || window.windowLevel != UIWindowLevelNormal) {
    for (window in [UIApplication sharedApplication].windows) {
      if (window.windowLevel == UIWindowLevelNormal) {
        break;
      }
    }
  }

  return window;
}

+ (UIViewController *)topMostViewController
{
  UIWindow *keyWindow = [self findWindow];
  // SDK expects a key window at this point, if it is not, make it one
  if (keyWindow != nil && !keyWindow.isKeyWindow) {
    [keyWindow makeKeyWindow];
  }

  UIViewController *topController = keyWindow.rootViewController;
  while (topController.presentedViewController) {
    topController = topController.presentedViewController;
  }
  return topController;
}

+ (UIImage *)imageWithImage:(UIImage *)sourceImage scaledToWidth:(float)width
{
  float scaleFactor = width / sourceImage.size.width;

  float resizeHeight = sourceImage.size.height * scaleFactor;
  float resizeWidth = sourceImage.size.width * scaleFactor;

  UIGraphicsBeginImageContext(CGSizeMake(resizeWidth, resizeHeight));
  [sourceImage drawInRect:CGRectMake(0, 0, resizeWidth, resizeHeight)];
  UIImage *resizeImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return resizeImage;
}

+ (NSArray<NSDictionary<NSString *, id> *> *)pathOf:(NSObject *)obj
{
  if (!obj) {
    return nil;
  }

  NSMutableDictionary *info = [HRTViewHierarchy getDetailAttributesOf:obj];

  NSObject *parent = [HRTViewHierarchy getParent:obj];
  NSArray *parentPath = [HRTCodelessIndexer pathOf:parent];

  NSMutableArray *result;
  if (parentPath) {
    result = [NSMutableArray arrayWithArray:parentPath];
  } else {
    result = [NSMutableArray array];
  }

  [result addObject:info];

  return [result copy];
}

+ (NSDictionary<NSString *, id> *)recursiveCaptureTree:(NSObject *)obj
                                     withInteractedObj:(NSObject *)interacted
                                               withSet:(NSMutableSet *)objSet;
{
  if (!obj || [objSet containsObject:obj]) {
    return nil;
  }
  [objSet addObject:obj];

  NSMutableDictionary *result = [HRTViewHierarchy getDetailAttributesOf:obj];

  if (interacted == obj) {
    [result setObject:@"1" forKey:@"is_interacted"];
  }

  NSArray *children = [HRTViewHierarchy getChildren:obj];
  NSMutableArray *childrenTrees = [NSMutableArray array];
  for (NSObject *child in children) {
    NSDictionary *objTree = [self recursiveCaptureTree:child
                                     withInteractedObj:interacted
                                               withSet:objSet];
    if (objTree != nil) {
      [childrenTrees addObject:objTree];
    }
  }

  if (childrenTrees.count > 0) {
    [result setValue:[childrenTrees copy] forKey:CODELESS_VIEW_TREE_CHILDREN_KEY];
  }

  return [result copy];
}

+ (UIImage *)screenshot
{
  UIWindow *window = [UIApplication sharedApplication].delegate.window;

  UIGraphicsBeginImageContext(window.bounds.size);
  [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return image;
}

+ (NSDictionary<NSString *, NSNumber *> *)dimensionOf:(NSObject *)obj
{
  UIView *view = nil;

  if ([obj isKindOfClass:[UIView class]]) {
    view = (UIView *)obj;
  } else if ([obj isKindOfClass:[UIViewController class]]) {
    view = ((UIViewController *)obj).view;
  }

  CGRect frame = view.frame;
  CGPoint offset = CGPointZero;

  if ([view isKindOfClass:[UIScrollView class]]) {
    offset = ((UIScrollView *)view).contentOffset;
  }

  return @{
    CODELESS_VIEW_TREE_TOP_KEY : @((int)frame.origin.y),
    CODELESS_VIEW_TREE_LEFT_KEY : @((int)frame.origin.x),
    CODELESS_VIEW_TREE_WIDTH_KEY : @((int)frame.size.width),
    CODELESS_VIEW_TREE_HEIGHT_KEY : @((int)frame.size.height),
    CODELESS_VIEW_TREE_OFFSET_X_KEY : @((int)offset.x),
    CODELESS_VIEW_TREE_OFFSET_Y_KEY : @((int)offset.y),
    CODELESS_VIEW_TREE_VISIBILITY_KEY : view.isHidden ? @4 : @0
  };
}

@end
