// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// View controller for the links list

#import <UIKit/UIKit.h>

@interface FSMPILinksViewController : UIViewController 
<UITableViewDelegate, UITableViewDataSource> 
{
	IBOutlet UITableView *linkTableView;
	IBOutlet UITableViewCell *currentCell;
	NSString *languageCode;
	NSArray *links;
}

@property (strong) IBOutlet UITableView *linkTableView;
@property (strong) IBOutlet UITableViewCell *currentCell;
@property (strong) NSString *languageCode;

@property (strong) NSArray *links;

@end