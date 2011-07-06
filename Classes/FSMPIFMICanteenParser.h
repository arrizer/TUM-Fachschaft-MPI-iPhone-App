// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// Parser for the FMI canteen menu XML files

#import <Foundation/Foundation.h>

@class FSMPIFMICanteenParser;

@protocol FSMPIFMICanteenParserDelegate
// Sent when a menu was parsed successfully
- (void)canteenParser:(FSMPIFMICanteenParser*)parser didFinishParsingMenu:(NSArray*)menu forCanteenID:(NSString*)mensaId;
// Sent when parsing failed
- (void)canteenParser:(FSMPIFMICanteenParser*)parser didFailWithError:(NSError*)error forCanteenID:(NSString*)mensaId;
@end


@interface FSMPIFMICanteenParser : NSObject 
<NSXMLParserDelegate>
{
	NSString *requestedCanteenID;
	NSMutableData *receivedData;
	NSURLConnection *connection;
    NSXMLParser *xmlParser;
    NSDateFormatter *dateFormatter;
    NSMutableArray *menu;
    NSDictionary *currentMealPlan;
    NSDictionary *currentMeal;
    NSString *currentMealTag;
    NSMutableString *buffer;
    NSUInteger daysParsed;
    BOOL validPriceForCurrentMealPlan;
	id<FSMPIFMICanteenParserDelegate> __unsafe_unretained delegate;
}

@property (strong) NSString *requestedCanteenID;
@property (assign) id<FSMPIFMICanteenParserDelegate> delegate;

@property (strong) NSMutableArray *menu;
@property (strong) NSDictionary *currentMealPlan;
@property (strong) NSDictionary *currentMeal;
@property (strong) NSString *currentMealTag;

// Parse the menu for a canteen
- (void)parseMenuForCanteen:(NSString*)canteenID;
// Parse the received HTML data;
- (void)parseReceivedData:(NSData*)data;
@end