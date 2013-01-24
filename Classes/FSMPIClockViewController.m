#import "FSMPIClockViewController.h"

const CGFloat kUpperBallTopOffset = 92;			// y distance of the upper balls
const CGFloat kUpperBallMoveOffset = 28;		// y distance of down moved upper balls
const CGFloat kLowerBallTopOffset = 189;		// y distance of highest lower ball
const CGFloat kLowerBallHoleOffset = 30;		// height of the hole between the lower balls
const CGFloat kLowerBallMoveOffset = 42;		// distance between two balls in the lower half
const CGFloat kBallLeftOffset = 61;				// x distance from the leftmost column
const CGFloat kBallLeftStep = 52;				// x distance from the column to the left
const CGFloat kBallShadowOversize = 13;			// additional pixels of the image arround the actual ball
const CGFloat kBallSize = 67;					// scaled image size
const CGFloat kBallMoveAnimationDuration = 0.5;	// duration of the ball movement animation
const NSTimeInterval kClockUpdateInterval = 1;	// number of seconds between clock updates

@implementation FSMPIClockViewController
@synthesize timeLabel, clockCaseImageView, clockUpdateTimer, ballImageViews,
clockTutorialViewController, clockTutorialWebView;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[self.ballImageViews removeAllObjects];
}

#pragma mark View Lifecycle

- (void)viewDidLoad {
	[self setupClock];
	NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tutorial" ofType:@"html"]];
	[self.clockTutorialWebView loadRequest:[NSURLRequest requestWithURL:url]];
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	// Setup time for periodical clock updates
	if(self.clockUpdateTimer == nil) 
		self.clockUpdateTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] 
														 interval:kClockUpdateInterval 
														   target:self
														 selector:@selector(updateClock) 
														 userInfo:nil 
														  repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:self.clockUpdateTimer forMode:NSDefaultRunLoopMode];
	// Update once to catch up
	[self updateClockAnimated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// Stop updating the time as we don't see anything
	[self.clockUpdateTimer invalidate];
	self.clockUpdateTimer = nil;
}

#pragma mark -
#pragma mark Clock Controller

- (void)setupClock
{
	self.ballImageViews = [[NSMutableArray alloc] init];
	for(int column = 0; column < 4; column++){
		for(int row = 0; row < 5; row++){
			UIImageView *ballImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clock_ball.png"]];
			CGFloat positionX = kBallLeftOffset + (column * kBallLeftStep);
			CGFloat positionY = 0;
			if(row == 0){
				positionY = kUpperBallTopOffset + (row * kUpperBallMoveOffset);
			}else{
				positionY = kLowerBallTopOffset + ((row - 1) * kLowerBallMoveOffset);
			}
			positionX -= kBallShadowOversize;
			positionY -= kBallShadowOversize;
			CGRect ballImageViewFrame = CGRectMake(positionX, positionY, kBallSize, kBallSize);
			[ballImageView setFrame:ballImageViewFrame];
			[self.clockCaseImageView addSubview:ballImageView];
			[self.ballImageViews addObject:ballImageView];
		}
	}
	[self updateClockAnimated:NO];
    //NSLog(@"Height = %f", [self.clockCaseImageView superview].frame.size.height);
    if([self.clockCaseImageView superview].frame.size.height == 548){
        CGRect clockCaseFrame = self.clockCaseImageView.frame;
        clockCaseFrame.origin.y = 20;
        self.clockCaseImageView.frame = clockCaseFrame;
    }
}

- (void)updateClock
{
	[self updateClockAnimated:YES];
}

- (void)updateClockAnimated:(BOOL)shouldAnimate
{
	NSDate *now = [NSDate date];
	NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *timeComponents = [calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:now];
	[self arrangeClockForHours:[timeComponents hour] minutes:[timeComponents minute] animated:shouldAnimate];
	// Update the time label below the clock
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm"];
	[self.timeLabel setText:[dateFormatter stringFromDate:[NSDate date]]];
}

- (void)arrangeClockForHours:(NSUInteger)hours 
					 minutes:(NSUInteger)minutes
					animated:(BOOL)shouldAnimate
{
	for(int digit = 0; digit < 4; digit++){
		NSUInteger digitValue = 0;
		if(digit == 0) digitValue = hours / 10;
		if(digit == 1) digitValue = hours % 10;
		if(digit == 2) digitValue = minutes / 10;
		if(digit == 3) digitValue = minutes % 10;
		NSUInteger digitValueHigh = digitValue / 5;
		NSUInteger digitValueLow = digitValue % 5;
		//NSLog(@"Digit %i is %i (%i|%i)", digit, digitValue, digitValueHigh, digitValueLow);
		for(int digitBall = 0; digitBall < 5; digitBall++){
			UIImageView *ballImageView = [self.ballImageViews objectAtIndex:((digit * 5) + digitBall)];
			CGRect ballImageViewFrame = [ballImageView frame];
			if(digitBall == 0){
				// Move the upper ball
				ballImageViewFrame.origin.y = kUpperBallTopOffset + (digitValueHigh * kUpperBallMoveOffset);
			}else{
				// Move the lower balls
				ballImageViewFrame.origin.y = kLowerBallTopOffset + (((digitBall - 1) * kLowerBallMoveOffset) + ((digitBall > digitValueLow) * kLowerBallHoleOffset));
			}
			ballImageViewFrame.origin.y -= kBallShadowOversize;
			
			[UIView beginAnimations:@"ballMovement" context:NULL];
			[UIView setAnimationDuration:kBallMoveAnimationDuration];
			[UIView setAnimationsEnabled:shouldAnimate];
			if(digitBall > 0) [UIView setAnimationDelay:(4 - digitBall) * kBallMoveAnimationDuration];
			[ballImageView setFrame:ballImageViewFrame];
			[UIView commitAnimations];
		}
	}
}

#pragma mark -
#pragma mark Clock Tutorial

- (IBAction)showClockTutorial
{
	[self.clockTutorialViewController setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
	[self presentModalViewController:self.clockTutorialViewController animated:YES];
}

- (IBAction)hideClockTutorial
{
	[self.clockTutorialViewController dismissModalViewControllerAnimated:YES];
}

-			 (BOOL)webView:(UIWebView *)webView 
shouldStartLoadWithRequest:(NSURLRequest *)request 
            navigationType:(UIWebViewNavigationType)navigationType
{
    if(!didLoadTutorial){
        didLoadTutorial = YES;
        return YES;
    }
    NSLog(@"Opening clock page in safari...");
    [[UIApplication sharedApplication] openURL:[request URL]];
    return NO;
}
@end
