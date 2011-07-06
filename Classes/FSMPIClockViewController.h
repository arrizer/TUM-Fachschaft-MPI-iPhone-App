// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// View controller for the wooden abakus clock

#import <UIKit/UIKit.h>

@interface FSMPIClockViewController : UIViewController 
{
	IBOutlet UILabel *timeLabel;
	IBOutlet UIImageView *clockCaseImageView;
	IBOutlet UIWebView *clockTutorialWebView;
	IBOutlet UIViewController *clockTutorialViewController;
	
	NSMutableArray *ballImageViews;
	NSTimer *clockUpdateTimer;
    BOOL didLoadTutorial;
}

@property (strong) IBOutlet UILabel *timeLabel;
@property (strong) IBOutlet UIImageView *clockCaseImageView;
@property (strong) IBOutlet UIWebView *clockTutorialWebView;
@property (strong) IBOutlet UIViewController *clockTutorialViewController;

@property (strong) NSMutableArray *ballImageViews;
@property (strong) NSTimer *clockUpdateTimer;

// Adds all ball image views in their default positions to the view
- (void)setupClock;

// Updates the clock view to the current time
- (void)updateClock;
- (void)updateClockAnimated:(BOOL)shouldAnimate;

// Moves the clock items to represent the given time in hours and minutes
- (void)arrangeClockForHours:(NSUInteger)hours minutes:(NSUInteger)minutes animated:(BOOL)shouldAnimate;

// Show/Hide the clock tutorial modal view
- (IBAction)showClockTutorial;
- (IBAction)hideClockTutorial;
@end