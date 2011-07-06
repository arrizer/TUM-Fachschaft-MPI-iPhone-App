#import "FSMPIPubTransportViewController.h"

@implementation FSMPIPubTransportViewController
@synthesize departuresTableView, refreshButton, currentCell, reloadTimer;

const CGFloat kCellHeight = 45;                     // Table view cell height
const NSUInteger kWarnMinutesMax = 3;               // Threshold for red minute labels
const NSTimeInterval kDepartureUpdateInterval = 10; // Interval for updating the view (seconds)

#pragma mark -
#pragma mark Memory Management


#pragma mark View Lifecycle

- (void)viewDidLoad 
{
	stations = [[NSArray alloc] initWithObjects:@"Garching-Forschungszentrum", @"Theresienstraße", @"Pinakotheken", nil];
	// Fill departures with placeholders
	stationsDepartures = [[NSMutableArray alloc] init];
	for(int i = 0; i < [stations count]; i++) [stationsDepartures addObject:[NSNull null]];
	numberOfParsersInProgress = 0;
	didInitialLoad = NO;
	didShowErrorAlertView = NO;
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	if(self.reloadTimer == nil) 
		self.reloadTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] 
														 interval:kDepartureUpdateInterval
														   target:self
														 selector:@selector(reloadDepartures) 
														 userInfo:nil 
														  repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:self.reloadTimer forMode:NSDefaultRunLoopMode];
	if(!didInitialLoad){
		didInitialLoad = YES;
		[self reloadDepartures];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	didShowErrorAlertView = NO;
	[self.reloadTimer invalidate];
	self.reloadTimer = nil;
}

#pragma mark -
#pragma mark Reload Departures

- (void)reloadDepartures
{
	if(reloadingDepartues) return;
	reloadingDepartues = YES;
	[self.departuresTableView reloadData];
	self.refreshButton.enabled = NO;
	for(NSString *station in stations) {
		// Start parser for each station
		FSMPIMVGParser *mvgParser = [[FSMPIMVGParser alloc] init];
		[mvgParser setDelegate:self];
		[mvgParser requestDeparturesForStation:station];
		numberOfParsersInProgress++;
	}
}

#pragma mark MVG Parser Delegate

-		   (void)mvgParser:(FSMPIMVGParser*)parser 
didFinishParsingDepartures:(NSArray*)departureDictionaries 
				forStation:(NSString*)stationName
{
	// Update departures for the station
	NSUInteger stationIndex = [stations indexOfObject:stationName];
	[stationsDepartures replaceObjectAtIndex:stationIndex withObject:departureDictionaries];
	numberOfParsersInProgress--;
	if(numberOfParsersInProgress == 0){
		reloadingDepartues = NO;
		self.refreshButton.enabled = YES;	
	}
	[self.departuresTableView reloadData];
}

- (void)mvgParser:(FSMPIMVGParser*)parser 
 didFailWithError:(NSError*)error
{
	numberOfParsersInProgress--;
	if(numberOfParsersInProgress == 0){
		reloadingDepartues = NO;
		self.refreshButton.enabled = YES;
	}
	[self.departuresTableView reloadData];
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
#pragma mark UITableView Data Source

- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [stations count];
}

- (int)tableView:(UITableView *)table 
  numberOfRowsInSection:(NSInteger)section
{
	if(![[stationsDepartures objectAtIndex:section] isKindOfClass:[NSArray class]]) return 1;
	NSArray *departuresAtStation = [stationsDepartures objectAtIndex:section];
	return [departuresAtStation count];
}

-   (NSString*)tableView:(UITableView *)tableView 
titleForHeaderInSection:(NSInteger)section
{
	return [stations objectAtIndex:section];
}

-  (NSString*)tableView:(UITableView *)tableView 
titleForFooterInSection:(NSInteger)section
{
	if((section+1) < [stations count]) return nil;
	return NSLocalizedString(@"No liability assumed", "Disclaimer for public transport departures");
}

- (UITableViewCell*)tableView:(UITableView *)tableView 
		cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifier = @"departureCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FSMPIPubTransportCell" owner:self options:nil];
        cell = self.currentCell;
    }
	
	UIImageView *lineIcon = (UIImageView*)[cell viewWithTag:1];			// Icon of the line
	UILabel *destionationLabel = (UILabel*)[cell viewWithTag:2];		// Line headsign
	UILabel *minutesLabel = (UILabel*)[cell viewWithTag:3];				// Minutes until departure
	UIView *loadingOverlayView = (UIView*)[cell viewWithTag:4];			// Overlay when station is loading
	UIView *notAvailableOverlayView = (UIView*)[cell viewWithTag:5];	// Overlay when no departures are available
	UILabel *lineFallbackLabel = (UILabel*)[cell viewWithTag:6];		// Fallback for line number (when no line icon image available)
	
	if([[stationsDepartures objectAtIndex:indexPath.section] isKindOfClass:[NSArray class]]){
		// Configure cell
		NSArray *departuresAtStation = [stationsDepartures objectAtIndex:indexPath.section];
		NSDictionary *departure = [departuresAtStation objectAtIndex:indexPath.row];
		
		NSString *lineIconImagePath = [NSString stringWithFormat:@"%@.gif", [departure valueForKey:@"line"]];
		lineIcon.image = [UIImage imageNamed:lineIconImagePath];
		lineFallbackLabel.text = [departure valueForKey:@"line"];
		lineFallbackLabel.hidden = lineIcon.image != nil;
		destionationLabel.text = [departure valueForKey:@"destination"];
		NSString *minutesString = [NSString stringWithFormat:NSLocalizedString(@"%@ Min.", "Minutes until departure"), [departure valueForKey:@"minutes"]];
		minutesLabel.text = minutesString;
		if([minutesString intValue] <= kWarnMinutesMax){
			minutesLabel.textColor = [UIColor redColor];
		}else{
			minutesLabel.textColor = [UIColor blackColor];
		}
		loadingOverlayView.hidden = YES;
		notAvailableOverlayView.hidden = YES;
	}else{
		// Configure loading or n/a cell
		loadingOverlayView.hidden = !reloadingDepartues;
		notAvailableOverlayView.hidden = reloadingDepartues;
	}

    return cell;
}

#pragma mark UITableView Delegate

-    (CGFloat)tableView:(UITableView *)tableView 
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kCellHeight;
}

#pragma mark -
#pragma mark IBOutlets

- (IBAction)reloadButtonTapped
{
	[self reloadDepartures];
}

@end
