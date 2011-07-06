#import "FSMPILinksViewController.h"

const CGFloat kLinkCellHeight = 64;

@implementation FSMPILinksViewController
@synthesize linkTableView, currentCell, links, languageCode;

#pragma mark -
#pragma mark Memory Management


#pragma mark View Lifecycle

- (void)viewDidLoad
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
	self.languageCode = [languages objectAtIndex:0];
	if(![self.languageCode isEqualToString:@"en"] && ![self.languageCode isEqualToString:@"de"] && ![self.languageCode isEqualToString:@"fr"]) self.languageCode = @"en";
	NSString *path = [[NSBundle mainBundle] pathForResource:@"links" ofType:@"plist"];
	self.links = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}

#pragma mark -
#pragma mark UITableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self.links count];
}

- (NSInteger)tableView:(UITableView *)tableView 
 numberOfRowsInSection:(NSInteger)section
{
	return [(NSArray*)[(NSDictionary*)[self.links objectAtIndex:section] objectForKey:@"links"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView 
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *reuseIdentifier = @"linkCell";
	NSDictionary *link = [[[links objectAtIndex:indexPath.section] objectForKey:@"links"] objectAtIndex:indexPath.row];
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FSMPILinkCell" owner:self options:nil];
        cell = self.currentCell;
    }
	UILabel *titleLabel = (UILabel*)[cell viewWithTag:1];
	UILabel *subtitleLabel = (UILabel*)[cell viewWithTag:2];
	UIImageView *iconImageView = (UIImageView*)[cell viewWithTag:3];
	titleLabel.text = [link valueForKey:[NSString stringWithFormat:@"title_%@", self.languageCode]];
	subtitleLabel.text = [link valueForKey:[NSString stringWithFormat:@"subtitle_%@", self.languageCode]];
	iconImageView.image = [UIImage imageNamed:[link valueForKey:@"icon"]];

    return cell;
}

-  (NSString*)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section
{
	return [[links objectAtIndex:section] objectForKey:[NSString stringWithFormat:@"category_%@", self.languageCode]];
}

#pragma mark UITableView Delegate

-       (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSDictionary *link = [[[links objectAtIndex:indexPath.section] objectForKey:@"links"] objectAtIndex:indexPath.row];
	NSURL *url = [NSURL URLWithString:[link valueForKey:[NSString stringWithFormat:@"url_%@", self.languageCode]]];
	[[UIApplication sharedApplication] openURL:url];
}

-    (CGFloat)tableView:(UITableView *)tableView 
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kLinkCellHeight;
}
@end
