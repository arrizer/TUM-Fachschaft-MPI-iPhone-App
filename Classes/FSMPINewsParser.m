#import "FSMPINewsParser.h"


@implementation FSMPINewsParser

@synthesize currentNewsItemKey, currentNewsItemValue, delegate;

- (void)loadAndParseNews
{
	NSString *urlString = @"http://mpi.fs.tum.de/fsmpi/RSS";
	NSURL *url = [NSURL URLWithString:urlString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
	urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
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
	inEntryTag = NO;
}

-  (void)parser:(NSXMLParser *)parser 
didStartElement:(NSString *)elementName 
   namespaceURI:(NSString *)namespaceURI 
  qualifiedName:(NSString *)qName 
	 attributes:(NSDictionary *)attributeDict
{
	if(inEntryTag){
		self.currentNewsItemKey = elementName;
		self.currentNewsItemValue = [[NSMutableString alloc] init];
	}else if([elementName isEqualToString:@"item"]){
		// New news item begins
		inEntryTag = YES;
		currentNewsItem = [[NSMutableDictionary alloc] init];
	}
}

-  (void)parser:(NSXMLParser *)parser 
foundCharacters:(NSString *)string
{
	if(inEntryTag) [self.currentNewsItemValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser 
 didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI 
 qualifiedName:(NSString *)qName
{
	if(inEntryTag){
		//NSLog(@"%@ - %@", currentNewsItemKey, currentNewsItemValue);
		if(currentNewsItemValue != nil && currentNewsItemKey != nil){
			[currentNewsItem setObject:self.currentNewsItemValue forKey:self.currentNewsItemKey];
		}
		self.currentNewsItemValue = nil;
		self.currentNewsItemKey = nil;
	}
	if([elementName isEqualToString:@"item"]){
		inEntryTag = NO;
		[self.delegate newsParser:self didParseNewsItem:currentNewsItem];
	}
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	[self.delegate newsParserDidFinishParsing:self];
}

#pragma mark URLConnection Delegate

- (void)connection:(NSURLConnection *)connection 
didReceiveResponse:(NSURLResponse *)response
{
	receivedData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection 
	didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
	//NSLog(@"Received more data: %d\n", [data length]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if([receivedData length] > 0){
        [self parseReceivedData:receivedData];
    }else{
    }
}

- (void)connection:(NSURLConnection *)connection 
  didFailWithError:(NSError *)error
{
	//NSLog(@"News parser error: %s", [error description]);
	[self.delegate newsParser:self didFailWithError:error];
}

@end
