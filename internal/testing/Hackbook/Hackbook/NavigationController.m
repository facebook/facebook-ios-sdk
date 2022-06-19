// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "NavigationController.h"

#import "Console.h"
#import "DismissSegue.h"
#import "Hackbook-Swift.h"
#import "HighlightView.h"
#import "Toast.h"

#define ANIMATION_DURATION 0.3
#define SCALE_ZERO 0.001
#define TOAST_MARGIN 20.0
#define TOAST_TIMEOUT 2.0

@implementation NavigationController

#pragma mark - Object Lifecycle

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Management

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.delegate = self;
  Console *console = [Console sharedInstance];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(_showHighlightWithNotification:)
             name:ConsoleDidAddMessageNotification
           object:console];
  [nc addObserver:self
         selector:@selector(_showToastWithNotification:)
             name:ConsoleDidReportBugNotification
           object:console];
  [nc addObserver:self
         selector:@selector(_showToastWithNotification:)
             name:ConsoleDidSucceedNotification
           object:console];
  if (![console isEmpty]) {
    [self _highlightConsole];
  }
}

#pragma mark - Segues

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController
                                      fromViewController:(UIViewController *)fromViewController
                                              identifier:(NSString *)identifier
{
  if ([identifier isEqualToString:@"unwindToRoot"]) {
    return [[DismissSegue alloc] initWithIdentifier:identifier
                                             source:toViewController
                                        destination:fromViewController];
  } else {
    return [super segueForUnwindingToViewController:toViewController
                                 fromViewController:fromViewController
                                         identifier:identifier];
  }
}

- (IBAction)unwindToRoot:(UIStoryboardSegue *)segue
{}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
  if (viewController.navigationItem.rightBarButtonItem) {
    return;
  }

  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                        target:self
                                                                        action:@selector(_showConsole:)];
  viewController.navigationItem.rightBarButtonItem = item;
}

#pragma mark - Helper Methods

- (CGPoint)_centerOfConsoleButtonInWindow
{
  UINavigationBar *navigationBar = self.navigationBar;
  UIWindow *window = navigationBar.window;
  CGRect navigationBarFrame = [navigationBar convertRect:navigationBar.bounds toView:window];
  CGFloat size = CGRectGetHeight(navigationBarFrame);
  // yes, these are magic layout numbers - deal with it
  return CGPointMake(CGRectGetMaxX(navigationBarFrame) - (size / 2) - 7.0, CGRectGetMidY(navigationBarFrame) - 2.0);
}

- (void)_highlightConsole
{
  UINavigationBar *navigationBar = self.navigationBar;
  UIWindow *window = navigationBar.window;
  if (!window) {
    __weak NavigationController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf _highlightConsole];
    });
    return;
  }

  CGRect navigationBarFrame = [navigationBar convertRect:navigationBar.bounds toView:window];
  CGRect bounds = CGRectZero;
  CGFloat size = CGRectGetHeight(navigationBarFrame);
  bounds.size = CGSizeMake(size, size);
  HighlightView *highlightView = [[HighlightView alloc] initWithFrame:CGRectZero];
  highlightView.bounds = bounds;
  highlightView.center = [self _centerOfConsoleButtonInWindow];
  [navigationBar.window addSubview:highlightView];
  [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                                                   highlightView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                                                 } completion:^(BOOL finished) {
                                                   [UIView animateWithDuration:ANIMATION_DURATION * 2 animations:^{
                                                                                                        highlightView.transform = CGAffineTransformMakeScale(SCALE_ZERO, SCALE_ZERO);
                                                                                                      } completion:^(BOOL innerFinished) {
                                                                                                        [highlightView removeFromSuperview];
                                                                                                      }];
                                                 }];
}

- (void)_showConsole:(id)sender
{
  ConsoleViewController *consoleVC = [[ConsoleViewController alloc] init];
  NavigationController *nav = [[NavigationController alloc] initWithRootViewController:consoleVC];
  [self presentViewController:nav animated:YES completion:nil];
}

- (void)_showHighlightWithNotification:(NSNotification *)notification
{
  // give some time for the animations that may be happening
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)),
    dispatch_get_main_queue(), ^{
      [self _highlightConsole];
    });
}

- (void)_showToastWithNotification:(NSNotification *)notification
{
  Toast *toast = [[Toast alloc] initWithFrame:CGRectZero];
  id<ConsoleMessage> consoleMessage = notification.userInfo[ConsoleMessageKey];
  toast.text = consoleMessage.message;
  UIWindow *window = self.navigationBar.window;
  CGRect windowBounds = CGRectInset(window.bounds, TOAST_MARGIN, TOAST_MARGIN);
  CGRect toastBounds = CGRectZero;
  toastBounds.size = [toast sizeThatFits:windowBounds.size];
  toast.bounds = toastBounds;
  toast.center = CGPointMake(CGRectGetMidX(windowBounds), CGRectGetMidY(windowBounds));
  CGFloat alpha = toast.alpha;
  toast.alpha = 0.0;
  [window addSubview:toast];
  [UIView animateWithDuration:ANIMATION_DURATION animations:^{
    toast.alpha = alpha;
  }];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TOAST_TIMEOUT * NSEC_PER_SEC)),
    dispatch_get_main_queue(), ^{
      [self _highlightConsole];
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                                                           CGPoint sourceCenter = toast.center;
                                                           CGPoint destinationCenter = [self _centerOfConsoleButtonInWindow];
                                                           CGAffineTransform transform = CGAffineTransformIdentity;
                                                           transform = CGAffineTransformTranslate(
                                                             transform,
                                                             destinationCenter.x - sourceCenter.x,
                                                             destinationCenter.y - sourceCenter.y
                                                           );
                                                           transform = CGAffineTransformScale(transform, SCALE_ZERO, SCALE_ZERO);
                                                           toast.transform = transform;
                                                         } completion:^(BOOL finished) {
                                                           [toast removeFromSuperview];
                                                         }];
        });
    });
}

@end
