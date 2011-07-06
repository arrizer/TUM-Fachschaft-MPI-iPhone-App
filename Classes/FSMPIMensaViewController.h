// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// View controller for a mensa menu

#import <UIKit/UIKit.h>
#import "FSMPIMensaParser.h"

@interface FSMPIMensaViewController : UIViewController 
<FSMPIMensaParserDelegate, UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView *tableView;
	IBOutlet UITableViewCell *currentCell;
	IBOutlet UIView *loadingOverlayView;
	NSArray *menus;
    NSString *mensaID;
	FSMPIMensaParser *parser;
    NSDateFormatter *dateFormatter;
    NSDateFormatter *localizedDateFormatter;
	BOOL currentlyLoading;
	BOOL didShowErrorAlertView;
}

@property (strong) IBOutlet UITableView *tableView;
@property (strong) IBOutlet UITableViewCell *currentCell;
@property (strong) IBOutlet UIView *loadingOverlayView;

@property (strong) NSArray *menus;

// Initializes the view controller with a mensa ID
- (id)initWithMensaID:(NSString*)mensaIDString;
// Reload menus for all canteens
- (void)refreshAllMenus;

@end