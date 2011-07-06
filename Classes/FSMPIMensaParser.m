#import "FSMPIMensaParser.h"
#import "TFHpple.h"
#import "TFHppleElement.h"

const NSUInteger kFutureDatesParsed = 3;

@implementation FSMPIMensaParser

@synthesize requestedMensaID, delegate;

- (void)parseMenuForMensaID:(NSString*)mensaID
{
	self.requestedMensaID = mensaID;
	NSString *menuURLString = [NSString stringWithFormat:@"http://www.studentenwerk-muenchen.de/mensa/speiseplan/speiseplan_%@_-de.html", mensaID];
	NSURL *menuURL = [NSURL URLWithString:menuURLString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:menuURL];
	connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
}

- (void)parseReceivedData:(NSData*)data
{
	TFHpple *xPathParser = [[TFHpple alloc] initWithHTMLData:data];
	NSArray *elements = [xPathParser search:@"//table[@class='menu']/tr/td[@class='gericht']|//table[@class='menu']/tr/td[@class='beschreibung']/span|//table[@class='menu']/tr/td[@class='headline']/span/a/strong"];
	NSMutableArray *dates = [[NSMutableArray alloc] init];
    NSMutableArray *menus;
	NSMutableDictionary *menuItem;
    NSMutableDictionary *dateContainer = nil;
	BOOL foundDescription = NO;
	BOOL skipDate = NO;
    NSUInteger foundDates = 0;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
	[dateFormatter setDateFormat:@"dd.MM.yyyy"];
	
	@try {
		for(TFHppleElement *element in elements){			
			if([[element tagName] isEqualToString:@"strong"]){
				// Parse date
				NSString *dateString = [element content];
				dateString = [dateString substringFromIndex:[dateString rangeOfString:@","].location + 2];

				NSDate *date = [dateFormatter dateFromString:dateString];
                if(foundDates >= kFutureDatesParsed || [date timeIntervalSinceDate:[NSDate date]] < (-1) * 60 * 60 * 24){
					// Skip past days and days too far in the future
					skipDate = YES;
					continue;
				}else{
					skipDate = NO;
                    foundDates++;
                    if(dateContainer != nil){
                        [dateContainer setObject:menus forKey:@"dishes"];
                    }
                    dateContainer = [[NSMutableDictionary alloc] init];
                    menus = [[NSMutableArray alloc] init];
                    [dateContainer setObject:date forKey:@"date"];
					[dates addObject:dateContainer];
				}
			}
			if([[element tagName] isEqualToString:@"td"] && !skipDate){
				foundDescription = NO;
				menuItem = [[NSMutableDictionary alloc] init];
				[menuItem setObject:[element content] forKey:@"meal"];
			}
			if([[element tagName] isEqualToString:@"span"] && !foundDescription && !skipDate){
				foundDescription = YES;
				[menuItem setObject:[element content] forKey:@"description"];
                [menus addObject:menuItem];
			}
		}
        if(dateContainer != nil) [dateContainer setObject:menus forKey:@"dishes"];
		
        [delegate mensaParser:self didFinishParsingMenu:dates forMensaID:requestedMensaID];
	}
	@catch (NSException * e) {
		// Something went wrong during HTML parsing (this might be a change to the website!)
		NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Parsing failed: %@", @"Mensa parser failure"), [e description]];
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:@"mensa_parser" code:2 userInfo:errorDetail];
		[delegate mensaParser:self didFailWithError:error forMensaID:requestedMensaID];
	}
	@finally {
	}
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response
{
	receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection 
	didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)aconnection
  didFailWithError:(NSError *)connectionError
{
	[delegate mensaParser:self didFailWithError:connectionError forMensaID:requestedMensaID];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aconnection
{
	[self parseReceivedData:receivedData];
}
@end