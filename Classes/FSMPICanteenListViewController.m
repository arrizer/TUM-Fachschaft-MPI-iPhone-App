#import "FSMPICanteenListViewController.h"
#import "FSMPIFMICanteenViewController.h"

@implementation FSMPICanteenListViewController

@synthesize tableView, navigationController;

#pragma mark View Lifecycle

-(void)viewDidLoad{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"canteens" ofType:@"plist"];
    canteens = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
    [self setTitle:NSLocalizedString(@"Canteens", @"Canteen list title")];
    NSLog(@"%@", NSLocalizedString(@"Canteens", @"Canteen list title"));
    //[self setTitle:@"Foo"];
}

-(void)viewWillAppear:(BOOL)animated
{
    [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:animated];
}

#pragma mark -
#pragma mark TableView data source

- (NSInteger)tableView:(UITableView *)table 
 numberOfRowsInSection:(NSInteger)section
{
    return [canteens count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    NSDictionary *canteen = [canteens objectAtIndex:indexPath.row];
    NSString *reuseIdentifier = @"canteenCell";
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if(!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }
    cell.textLabel.text = [canteen objectForKey:@"title"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage imageNamed:[canteen objectForKey:@"icon"]];
    
    return cell;
}

#pragma mark -
#pragma mark TableView delegate

-       (void)tableView:(UITableView *)aTableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *canteen = [canteens objectAtIndex:indexPath.row];
    NSString *parserIdentifier = [canteen objectForKey:@"parser"];
    UIViewController *viewController = nil;
    
    if([parserIdentifier isEqualToString:@"mensa"]){
        // Initialize a mensa view controller
        NSString *mensaID = [canteen objectForKey:@"id"];
        FSMPIMensaViewController *mensaViewController = [[FSMPIMensaViewController alloc] initWithMensaID:mensaID];
        mensaViewController.title = [canteen objectForKey:@"title"];
        viewController = mensaViewController;
    }else if([parserIdentifier isEqualToString:@"fmi"]){
        // Initialize FMI canteen view controller
        NSString *canteenID = [canteen objectForKey:@"id"];
        FSMPIFMICanteenViewController *canteenViewController = [[FSMPIFMICanteenViewController alloc] initWithCanteenID:canteenID];
        canteenViewController.title = [canteen objectForKey:@"title"];
        viewController = canteenViewController;
    }else{
        NSLog(@"Unknown canteen parser identifier: '%@'", parserIdentifier);
    }
    
    if(viewController != nil){
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark -
#pragma mark Navigation Controller Delegate

- (void)navigationController:(UINavigationController *)aNavigationController 
      willShowViewController:(UIViewController *)viewController 
                    animated:(BOOL)animated
{
    //if(viewController == self) [navigationController setTitle:NSLocalizedString(@"Canteen", @"Canteen list title")];
}

@end
