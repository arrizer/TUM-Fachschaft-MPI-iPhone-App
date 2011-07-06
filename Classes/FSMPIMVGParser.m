#import "FSMPIMVGParser.h"
#import "TFHpple.h"
#import "TFHppleElement.h"

const int kMaxDeparturesPerStation = 4;

@implementation FSMPIMVGParser
@synthesize delegate, requestedStationName;

#pragma mark -
#pragma mark MVG Parser

- (void)requestDeparturesForStation:(NSString*)stationName
{
	self.requestedStationName = stationName;
	NSString *urlFormatString = @"http://www.mvg-live.de/ims/dfiStaticAuswahl.svc?haltestelle=%@&ubahn=checked&bus=checked&tram=checked";
	NSString *urlEncodedStationName = self.requestedStationName;
    //TODO: Fix this workaround! For some reason, the URL escaping is not working properly on this string?!
	urlEncodedStationName = [urlEncodedStationName stringByReplacingOccurrencesOfString:@"ß" withString:@"%DF"];
    urlEncodedStationName = [urlEncodedStationName stringByReplacingOccurrencesOfString:@"ö" withString:@"%F6"];
	//urlEncodedStationName = [urlEncodedStationName stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
	NSString *urlString = [NSString stringWithFormat:urlFormatString, urlEncodedStationName];
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
}

- (void)parseReceivedData:(NSData*)data
{
	TFHpple *xPathParser = [[TFHpple alloc] initWithHTMLData:data];
	NSArray *tdElements = [xPathParser search:@"//tr[@class='rowOdd']/td|//tr[@class='rowEven']/td|//tr[@class='rowOdd']/td[@class='stationColumn']/text()[1]|//tr[@class='rowEven']/td[@class='stationColumn']/text()[1]"];
	NSMutableArray *departures = [[NSMutableArray alloc] init];
	NSMutableDictionary *departure = [[NSMutableDictionary alloc] init];
	@try {
		int departureCount = 0;
		for(TFHppleElement *element in tdElements){
			NSString *tdElementClass = [[element attributes] valueForKey:@"class"];
			if([tdElementClass isEqualToString:@"lineColumn"]){
				[departure setValue:[element content] forKey:@"line"];
			}else if([tdElementClass isEqualToString:@"inMinColumn"]){
				[departure setValue:[element content] forKey:@"minutes"];
			}else{
				NSString *destinationString = [[element content] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				[departure setValue:destinationString forKey:@"destination"];
			}
			if([departure count] == 3){
				//NSLog(@"Parsed departure: %@ %@ %@ min", [departure valueForKey:@"line"], [departure valueForKey:@"destination"], [departure valueForKey:@"minutes"]);
				[departures addObject:departure];
				departure = [[NSMutableDictionary alloc] init];
				departureCount++;
			}
			if(departureCount == kMaxDeparturesPerStation) break;
		}
		[delegate mvgParser:self didFinishParsingDepartures:departures forStation:requestedStationName];
	}
	@catch (NSException * e) {
		// Something went wrong during HTML parsing (this might be change to the website!)
		NSString *errorString = [NSString stringWithFormat:NSLocalizedString(@"Departure times Parsing failed: %@", @"MVG parser error parser failure"), [e description]];
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
		NSError *error = [NSError errorWithDomain:@"mvg_parser" code:2 userInfo:errorDetail];
		[delegate mvgParser:self didFailWithError:error];
	}
	@finally {
	}
}

#pragma mark -
#pragma mark NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response
{
	// Reset received data store
	receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection 
	didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)aconnection
  didFailWithError:(NSError *)error
{
	[delegate mvgParser:self didFailWithError:error];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aconnection
{
	[self parseReceivedData:receivedData];
}
@end
