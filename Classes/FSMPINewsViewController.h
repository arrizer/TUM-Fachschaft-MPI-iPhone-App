// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// View controller for the FSMPI news

#import <UIKit/UIKit.h>
#import "FSMPINewsParser.h"

@interface FSMPINewsViewController : UIViewController 
<FSMPINewsParserDelegate, UITableViewDelegate, UITableViewDataSource, UIWebViewDelegate>
{
	IBOutlet UINavigationController *navigationController;
	IBOutlet UITableViewCell *currentCell;
	IBOutlet UIViewController *detailViewController;
	IBOutlet UITableView *newsTableView;
    IBOutlet UIView *loadingOverlayView;
	
	NSMutableArray *newsItems;		// News item dictionaries from RSS parser
	NSDateFormatter *dateFormatter;	// Date formatter for news date
	BOOL loadingNewsItemDetail;		// YES while loading a detail page
	BOOL loadingNewsItems;			// YES while loading news items
	BOOL didShowErrorAlertView;		// YES when alert view has been shown
}

@property (strong) IBOutlet UINavigationController *navigationController;
@property (strong) IBOutlet UITableViewCell *currentCell;
@property (strong) IBOutlet UIViewController *detailViewController;
@property (strong) IBOutlet UITableView *newsTableView;
@property (strong) IBOutlet UIView *loadingOverlayView;

// Load all news items from the parser
- (void)loadNewsItems;

@end