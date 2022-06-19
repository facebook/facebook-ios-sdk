// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import "ShoppingCartViewController.h"

static NSMutableArray<Coffee *> *items;
static NSString *cellReuseIdentifier = @"ShoppingCartCell";

@implementation ShoppingCartViewController

+ (void)initialize
{
  if (self == [ShoppingCartViewController class]) {
    items = [[NSMutableArray alloc] init];
  }
}

+ (void)appendItem:(Coffee *)item
{
  [items addObject:item];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:cellReuseIdentifier];

  [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
  [self.tableView reloadData];
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
  return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
  Coffee *coffee = items[indexPath.row];
  [cell.textLabel setText:[NSString stringWithFormat:@"Product: %@  Price: %.2f", coffee.name, coffee.price]];
  return cell;
}

@end
