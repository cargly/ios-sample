//
//  CarglyApiRquest.m
//  TestCarglyWebAuth
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>

#import "CarglyApiRequest.h"
#import "CarglyApiRequestDelegate.h"

@implementation CarglyApiRequest


-(void) httpGet:(NSString*)path
       withParams:(NSDictionary*)params
        withToken:(NSString*)token
     withDelegate:(id)delegate
     withSelector:(SEL)selector
{	
	requestDelegate = delegate;
    self.callbackSelector = selector;
	
	NSString* urlPathNQuery = nil;
	
    if (params && [params count]) {
        urlPathNQuery = [[NSString alloc]
                         initWithFormat:@"/developers/api/v1%@?%@",
                         path,
                         [self encodeDictionary:params]];
    }
    else {
        urlPathNQuery = [[NSString alloc]
                        initWithFormat:@"/developers/api/v1%@",
                        path];
    }

	
	NSLog(@"HTTP GET %@", urlPathNQuery);
	// Create NSURL string from formatted string
	NSURL* url = [CarglyApiRequest makeFullUrl:urlPathNQuery];
	
	// Setup and start async download
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL: url];
    [request setValue:[NSString stringWithFormat:@"OAuth oauth_token=\"%@\"", token] forHTTPHeaderField:@"Authorization"];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection) {
		jsonData = [NSMutableData data];
	}
}

-(void) httpPostParams:(NSString*)path
       withParams:(NSDictionary*)params
        withToken:(NSString*)token
     withDelegate:(id)delegate
     withSelector:(SEL)selector
{
	requestDelegate = delegate;
    self.callbackSelector = selector;
	
	NSString* urlPathNQuery = nil;
	urlPathNQuery = [[NSString alloc]
                         initWithFormat:@"/developers/api/v1%@",
                         path];
	
	NSLog(@"HTTP POST %@", urlPathNQuery);
	// Create NSURL string from formatted string
	NSURL* url = [CarglyApiRequest makeFullUrl:urlPathNQuery];
	
	// Setup and start async download
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"OAuth oauth_token=\"%@\"", token] forHTTPHeaderField:@"Authorization"];

    if (params) {
        NSData *postData = [[self encodeDictionary:params] dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:postData];
    }
    
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection) {
		jsonData = [NSMutableData data];
	}
}

-(void) httpPostJson:(NSString*)path
            withJson:(id)objects
             withToken:(NSString*)token
          withDelegate:(id)delegate
          withSelector:(SEL)selector
{
	requestDelegate = delegate;
    self.callbackSelector = selector;
	
	NSString* urlPathNQuery = nil;
	urlPathNQuery = [[NSString alloc]
                     initWithFormat:@"/developers/api/v1%@",
                     path];
	
	NSLog(@"HTTP POST %@", urlPathNQuery);
	// Create NSURL string from formatted string
	NSURL* url = [CarglyApiRequest makeFullUrl:urlPathNQuery];
	
	// Setup and start async download
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"OAuth oauth_token=\"%@\"", token] forHTTPHeaderField:@"Authorization"];

    if (objects) {
        //FIXME: not encoding correctly
        NSString* jsonString = [CarglyApiRequest toJson:objects];
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [data length]] forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody: data];
    }
    
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection) {
		jsonData = [NSMutableData data];
	}
}


- (NSString*)encodeDictionary:(NSDictionary*)dictionary {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in dictionary) {
        NSString *encodedValue = [[dictionary objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    return encodedDictionary;
//    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}

-(void) doLocationRequest:(id)delegate withLat:(double)lat withLon:(double)lon {
	requestDelegate = delegate;
	
	// Build the string to call the CarglyNineTenths API
//	NSString* urlString = @"http://carglyninetenths.appspot.com/search?lat=29.555114&lon=-98.668783";
	NSString* urlString = [[NSString alloc] 
						   initWithFormat:@"http://carglyninetenths.appspot.com/search?lat=%3.6f&lon=%3.6f&sic=554", lat, lon];
	
	// Create NSURL string from formatted string
	NSURL* url = [NSURL URLWithString:urlString];
	
	// Setup and start async download
	NSURLRequest* request = [[NSURLRequest alloc] initWithURL: url];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection) {
		jsonData = [NSMutableData data];
	}
}

-(void) doTaxDeductionRequest:(id)delegate  {
	requestDelegate = delegate;
	
	// Build the string to call the CarglyNineTenths API
//	NSString* urlString = [[NSString alloc] 
//						   initWithFormat:@"http://carglyonline.appspot.com/tax_deduction.json"];
	NSString* urlString = [[NSString alloc] initWithFormat:@"%@/tax_deduction.json", [CarglyApiRequest carglyBaseUrl]];
	
	// Create NSURL string from formatted string
	NSURL* url = [NSURL URLWithString:urlString];
	
	// Setup and start async download
	NSURLRequest* request = [[NSURLRequest alloc] initWithURL: url];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection) {
		jsonData = [NSMutableData data];
	}
}


-(void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
		int statusCode = [httpResponse statusCode];
		if (statusCode >= 400) {
			[conn cancel];
			NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:
							NSLocalizedString(@"Server returned status code %d",@""), statusCode]
							forKey:NSLocalizedDescriptionKey];
			NSError *statusError = [NSError errorWithDomain:NSURLErrorDomain code:statusCode userInfo:errorInfo];
			[self connection:conn didFailWithError:statusError];
		}
		return;
	}
	
	[jsonData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (jsonData) {
		[jsonData appendData:data];
	}
}

-(void)connection:(NSURLConnection *)conn didFailWithError:(NSError*)error
{
	jsonData = nil;
	
	if (requestDelegate) {
		[requestDelegate carglyRequestFailure:error forRequest:self];
	}
}


- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	if (jsonData == nil) return;
	
	// Store incoming data into a string
	NSString* jsonString = [[NSString alloc] initWithBytes:[jsonData mutableBytes] 
													length:[jsonData length] 
												  encoding:NSUTF8StringEncoding];
	
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
	//id jsonObject = [jsonString JSONValue];
    NSError *e = nil;
    self.responseData = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];
	/*
	NSArray* locations = [jsonString JSONValue];
	for (NSDictionary *location in locations) {
		NSLog(@"%@", [location objectForKey:@"name"]);
	}*/
	
    [requestDelegate performSelector:self.callbackSelector withObject:self afterDelay:0];    
}

+ (NSString *)urlEncodeValue:(NSString *)str
{
	NSString *result = (__bridge_transfer NSString * ) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
        (__bridge CFStringRef)str, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
	return result;
}

+(NSString *) md5:(NSString *)str {
	const char *cStr = [str UTF8String];
	unsigned char result[16];
	CC_MD5( cStr, strlen(cStr), result );
	return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			]; 
}


+(NSString*) carglyBaseUrl {
	static NSString* carglyBaseUrl = @"http://localhost:8888";
	//static NSString* carglyBaseUrl = @"https://carglyplatform.appspot.com";
	return carglyBaseUrl;
}

+(NSString*) makeFullUrlString:(NSString*)pathQueryFragment {
	return [NSString stringWithFormat:@"%@%@", [self carglyBaseUrl], pathQueryFragment];
}

+(NSURL*) makeFullUrl:(NSString*)pathQueryFragment {
	NSURL* url = [NSURL URLWithString:[self makeFullUrlString:pathQueryFragment]];
	return url;
}

+(NSString*) toJson:(id)dictOrArray
{
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictOrArray options:NSJSONWritingPrettyPrinted error:&err];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+(id) fromJson:(NSString*)json
{
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    return [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &err];
}

@end
