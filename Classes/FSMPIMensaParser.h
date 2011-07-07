// FSMPI App - Fachschaft für Mathematik, Physik & Informatik TU München
// ---------------------------------------------------------------------
// Mensa parser for the munich student union website

#import <Foundation/Foundation.h>

@class FSMPIMensaParser;

@protocol FSMPIMensaParserDelegate
// Sent when a menu was parsed successfully
- (void)mensaParser:(FSMPIMensaParser*)parser didFinishParsingMenu:(NSArray*)menu forMensaID:(NSString*)mensaId;
// Sent when parsing failed
- (void)mensaParser:(FSMPIMensaParser*)parser didFailWithError:(NSError*)error forMensaID:(NSString*)mensaId;
@end


@interface FSMPIMensaParser : NSObject {
	NSString *requestedMensaID;
	NSMutableData *receivedData;
	NSURLConnection *connection;
	id<FSMPIMensaParserDelegate> __unsafe_unretained delegate;
}

@property (strong) NSString *requestedMensaID;
@property (assign) id<FSMPIMensaParserDelegate> delegate;

// Parse the menu for a canteen by ID from the student union website
- (void)parseMenuForMensaID:(NSString*)mensaID;
// Called whenever a connection finished loading HTML
- (void)parseReceivedData:(NSData*)data;

- (void)guessMealPropertiesForMenuItem:(NSDictionary**)menuItem;
@end