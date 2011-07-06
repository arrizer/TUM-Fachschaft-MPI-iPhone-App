#import "FSMPINewsViewController.h"

const CGFloat kNewsCellHeight = 109;

@implementation FSMPINewsViewController

@synthesize navigationController, currentCell, detailViewController, newsTableView, loadingOverlayView;

- (void)viewDidLoad
{
	loadingNewsItemDetail = NO;
	loadingNewsItems = NO;
	didShowErrorAlertView = NO;
	newsItems = [[NSMutableArray alloc] init];
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
	//[dateFormatter setLocale:[NSLocale currentLocale]];
	[dateFormatter setDateFormat:@"Y-MM-dd'T'HH:mm:ss'Z'"];
    [navigationController setTitle:NSLocalizedString(@"News", @"News title")];
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
	if(!loadingNewsItems && [newsItems count] == 0){
		loadingNewsItems = YES;
		[self loadNewsItems];
	}
    [newsTableView deselectRowAtIndexPath:[newsTableView indexPathForSelectedRow] animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	didShowErrorAlertView = NO;
}

#pragma mark -
#pragma mark News parser delegate

- (void)loadNewsItems
{
	FSMPINewsParser *newsParser = [[FSMPINewsParser alloc] init];
	newsItems = [[NSMutableArray alloc] init];
	[newsParser setDelegate:self];
	[newsParser loadAndParseNews];
}

- (void)newsParser:(FSMPINewsParser*)parser 
  didParseNewsItem:(NSDictionary*)newsItemDictionary
{
	[newsItems addObject:newsItemDictionary];
}

- (void)newsParserDidFinishParsing:(FSMPINewsParser*)parser
{
	[newsTableView reloadData];
	loadingNewsItems = NO;
    [self.loadingOverlayView setHidden:YES];
}

- (void)newsParser:(FSMPINewsParser*)parser 
  didFailWithError:(NSError*)error
{
	loadingNewsItems = NO;
	if(!didShowErrorAlertView){
		didShowErrorAlertView = YES;
		UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error alert view title") 
															 message:[error localizedDescription] 
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Error alert dismiss button label")  
												   otherButtonTitles:nil];
		[errorAlert show];
	}
}

#pragma mark -
#pragma mark TableView Delegate

- (NSInteger)tableView:(UITableView *)table 
 numberOfRowsInSection:(NSInteger)section
{
	return [newsItems count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView 
		cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *reuseIdentifier = @"NewsItemCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
	if(cell == nil){
		[[NSBundle mainBundle] loadNibNamed:@"FSMPINewsCell" owner:self options:nil];
		cell = self.currentCell;			
	}
	
	NSDictionary *newsItem = [newsItems objectAtIndex:indexPath.row];
	
	// Configure the cell
	UILabel *dateLabel = (UILabel*)[cell viewWithTag:1];
	UILabel *titleLabel = (UILabel*)[cell viewWithTag:2];
	UILabel *descriptionLabel = (UILabel*)[cell viewWithTag:3];
	UILabel *authorLabel = (UILabel*)[cell viewWithTag:4];
	
	NSDate *newsDate = [dateFormatter dateFromString:[newsItem objectForKey:@"dc:date"]];
	NSString *oldFormatString = [dateFormatter dateFormat];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	dateLabel.text = [dateFormatter stringFromDate:newsDate];
	[dateFormatter setDateFormat:oldFormatString];
	titleLabel.text = [newsItem objectForKey:@"title"];
	descriptionLabel.text = [newsItem objectForKey:@"description"];
	authorLabel.text = [newsItem objectForKey:@"dc:creator"];
	
	return cell;
}

-    (CGFloat)tableView:(UITableView *)tableView 
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kNewsCellHeight;
}

-       (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(loadingNewsItemDetail) return;
	loadingNewsItemDetail = YES;
//	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSDictionary *newsItem = [newsItems objectAtIndex:indexPath.row];
	UIWebView *webView = (UIWebView*)[detailViewController view];
    NSString *templateFilePath = [[NSBundle mainBundle] pathForResource:@"news_template" ofType:@"html"];
    NSString *htmlString = [NSString stringWithContentsOfFile:templateFilePath encoding:NSUTF8StringEncoding error:nil];
	NSString *contentString = [NSString stringWithFormat:@"<h1>%@</h1><h2>%@</h2>", [newsItem objectForKey:@"title"], [newsItem objectForKey:@"dc:creator"]];
	contentString = [contentString stringByAppendingFormat:@"%@", [newsItem objectForKey:@"content:encoded"]];
    htmlString = [htmlString stringByReplacingOccurrencesOfString:@"%content%" withString:contentString];
	NSURL *baseURL = [NSURL URLWithString:@"http://mpi.fs.tum.de"];
	[webView loadHTMLString:htmlString baseURL:baseURL];
//  [navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark -
#pragma mark WebView Delegate

-			 (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	if(loadingNewsItemDetail) return YES;
	[[UIApplication sharedApplication] openURL:[request URL]];
	return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	loadingNewsItemDetail = NO;
    [navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark -
#pragma mark Memory management


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end
