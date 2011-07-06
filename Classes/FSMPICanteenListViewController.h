// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// View controller for the canteen selection list

#import <Foundation/Foundation.h>
#import "FSMPIMensaViewController.h"

@interface FSMPICanteenListViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate>
{
    IBOutlet UITableView *tableView;
    IBOutlet UINavigationController *navigationController;
    
    NSArray *canteens;
}

@property (strong) IBOutlet UITableView *tableView;
@property (strong) IBOutlet UINavigationController *navigationController;

@end