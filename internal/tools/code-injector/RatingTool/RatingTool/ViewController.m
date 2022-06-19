// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  tvSample = [[UITableView alloc] initWithFrame:CGRectMake(0, 60, 200, 200)];
  [tvSample registerClass:[UITableViewCell class] forCellReuseIdentifier:@"ABC"];
  tvSample.delegate = self;
  tvSample.dataSource = self;
  [self.view addSubview:tvSample];

  BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbauth2://abc"]];
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fbauth3://"]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ABC" forIndexPath:indexPath];

  cell.textLabel.text = @"A";

  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 30;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 20;
}

@end
