// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// View controller for the FMI canteen menu

#import <UIKit/UIKit.h>
#import "FSMPIFMICanteenParser.h"

@interface FSMPIFMICanteenViewController : UIViewController 
<FSMPIFMICanteenParserDelegate, UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView *tableView;
	IBOutlet UITableViewCell *currentCell;
	IBOutlet UIView *loadingOverlayView;
	NSArray *menus;
    NSString *canteenID;
	FSMPIFMICanteenParser *parser;
    NSDateFormatter *localizedDateFormatter;
    NSDateFormatter *dateFormatter;
	BOOL currentlyLoading;
	BOOL didShowErrorAlertView;
}

@property (strong) IBOutlet UITableView *tableView;
@property (strong) IBOutlet UITableViewCell *currentCell;
@property (strong) IBOutlet UIView *loadingOverlayView;
@property (strong) NSArray *menus;

// Initializes the view controller with a mensa ID
- (id)initWithCanteenID:(NSString*)canteenIDString;
// Reload menus for all canteens
- (void)refreshAllMenus;

@end