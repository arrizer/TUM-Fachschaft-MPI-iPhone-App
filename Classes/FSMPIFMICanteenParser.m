#import "FSMPIFMICanteenParser.h"

@implementation FSMPIFMICanteenParser


const NSUInteger kFutureCanteenDatesParsed = 5;

@synthesize requestedCanteenID, delegate, menu, currentMeal, currentMealPlan, currentMealTag;

- (id)init {
    self = [super init];
    if (self) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
        [dateFormatter setDateFormat:@"dd.MM.yyyy"];
    }
    return self;
}

- (void)parseMenuForCanteen:(NSString*)canteenID;
{
	self.requestedCanteenID = canteenID;
	NSString *menuURLString = [NSString stringWithFormat:@"http://apps.interface-group.eu/mensa/%@.xml", canteenID];
	NSURL *menuURL = [NSURL URLWithString:menuURLString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:menuURL];
	connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
}

- (void)parseReceivedData:(NSData*)data
{
	xmlParser = [[NSXMLParser alloc] initWithData:data];
	[xmlParser setShouldProcessNamespaces:NO];
	[xmlParser setShouldReportNamespacePrefixes:NO];
	[xmlParser setShouldResolveExternalEntities:NO];
	[xmlParser setDelegate:self];
	[xmlParser parse];
}

#pragma mark -
#pragma mark XMLParser Delegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    self.menu = [[NSMutableArray alloc] init];
    daysParsed = 0;
}

-  (void)parser:(NSXMLParser *)parser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqualToString:@"mealPlan"]){
        self.currentMealPlan = [[NSMutableDictionary alloc] init];
        NSString *dateString = [attributeDict valueForKey:@"date"];
        dateString = [dateString substringFromIndex:[dateString rangeOfString:@","].location+1];
        NSDate *date = [dateFormatter dateFromString:dateString];
        [self.currentMealPlan setValue:date forKey:@"date"];
        [self.currentMealPlan setValue:[[NSMutableArray alloc] init] forKey:@"dishes"];
        validPriceForCurrentMealPlan = NO;
    }
    else if([elementName isEqualToString:@"meal"]){
        self.currentMeal = [[NSMutableDictionary alloc] init];
    }
    else if([elementName isEqualToString:@"description"] || [elementName isEqualToString:@"price"]){
        self.currentMealTag = elementName;
        buffer = [[NSMutableString alloc] init];
    }
}

-  (void)parser:(NSXMLParser *)parser 
foundCharacters:(NSString *)string
{
    if([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) return;
    if(self.currentMealTag != nil){
        [buffer appendString:string];
        if([currentMealTag isEqualToString:@"price"]) validPriceForCurrentMealPlan = YES;
    }
}

- (void)parser:(NSXMLParser *)parser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
{
    if([elementName isEqualToString:@"mealPlan"]){
        BOOL dateIsFuture = [[self.currentMealPlan objectForKey:@"date"] timeIntervalSinceDate:[NSDate date]] >= (-1) * 60 * 60 * 24;
        NSLog(@"Meal plan date: %@", [self.currentMealPlan objectForKey:@"date"]);
        if(daysParsed < kFutureCanteenDatesParsed && dateIsFuture && validPriceForCurrentMealPlan){
            [self.menu addObject:self.currentMealPlan];
            NSLog(@"Found a menu");
            daysParsed++;
        }
    }
    else if([elementName isEqualToString:@"meal"]){
        NSMutableArray *dishes = [self.currentMealPlan valueForKey:@"dishes"];
        [dishes addObject:self.currentMeal];
        self.currentMealTag = nil;
    }
    else if([elementName isEqualToString:@"price"]){
        [buffer appendString:@" €"];
        [self.currentMeal setValue:buffer forKey:@"price"];
    }
    else if([elementName isEqualToString:@"description"]){
        [self.currentMeal setValue:buffer forKey:@"description"];
        [self guessMealPropertiesForCurrentMeal];
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    [self.delegate canteenParser:self didFinishParsingMenu:self.menu forCanteenID:self.requestedCanteenID];
}


- (void)guessMealPropertiesForCurrentMeal
{
    NSDictionary *regularExpressions = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"(^V | V )", @"isVegetarian",
                                        @"(^R+S |^S| R+S | S |Schwein)", @"containsPork",
                                        @"(^R+S |^R| R+S | R |Rind)", @"containsBeef",
                                        nil];
    NSArray *removeStrings = [NSArray arrayWithObjects:@" R+S ", @"R+S ", @"V ", @" V ", @"R ", @"S ",  @" R ", @" S ", nil];
    
    for(NSString *key in [regularExpressions allKeys]){
        NSError *error = NULL;
        NSString *expressionString = [regularExpressions objectForKey:key];
        NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:expressionString
                                                  options:NSRegularExpressionCaseInsensitive 
                                                    error:&error];
        NSString *descriptionString = [self.currentMeal valueForKey:@"description"];
        NSRange range = [expression rangeOfFirstMatchInString:descriptionString 
                                                      options:0 
                                                        range:NSMakeRange(0, [descriptionString length])];
        if (!NSEqualRanges(range, NSMakeRange(NSNotFound, 0))) 
        {
            [currentMeal setValue:[NSNumber numberWithBool:YES] forKey:key];
        }
    }
    for(NSString *stringToRemove in removeStrings){
        NSString *descriptionString = [self.currentMeal valueForKey:@"description"];
        descriptionString = [descriptionString stringByReplacingOccurrencesOfString:stringToRemove withString:@""];
        [self.currentMeal setValue:descriptionString forKey:@"description"];
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
	[delegate canteenParser:self didFailWithError:connectionError forCanteenID:self.requestedCanteenID];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    if([receivedData length] > 0){
        [self parseReceivedData:receivedData];
    }else{
    }
}
@end