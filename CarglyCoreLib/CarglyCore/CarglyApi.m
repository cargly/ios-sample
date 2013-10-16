//
//  CarglyApi.m
//  TestCarglyWebAuth
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import "CarglyCore.h"
#import "CarglyApi.h"

#define kHostName @"www.cargly.com"

@interface CarglyApi()
+(NSString*) toJson:(id)dictOrArray;
+(id) fromJson:(NSString*)json;
@end


@implementation CarglyApi

@synthesize syncDelegate;
@synthesize nearbyLocations;
@synthesize favoriteLocations;
@synthesize businessTaxRate;
@synthesize medicalTaxRate;
@synthesize charitableTaxRate;
@synthesize movingTaxRate;


-(id) initWithReachability {
	id api = [super init];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    hostReachability = [Reachability reachabilityWithHostname:kHostName];

	[hostReachability startNotifier];
	remoteHostStatus = [hostReachability currentReachabilityStatus];
	
	return api;
}

-(void) openAuthUrl
{
    NSString *authUrl = [NSString
                         stringWithFormat:@"/oauth?response_type=token&redirect_uri=%@&client_id=%@",
                         [[NSString stringWithFormat:@"cargly%@:///", self.appId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                         self.appId];

    NSURL* url = [CarglyApiRequest makeFullUrl:authUrl];
    
    if (![[UIApplication sharedApplication] openURL:url]) {
        NSLog(@"%@%@",@"Failed to open url:",[url description]);
    }
}

-(void) sync {
    if (![self isDisconnected]) {
        self.retryCount = 0;
        if (!self.authToken) {
            [self openAuthUrl];
        }
        else {
            if (!self.userId) {
                [syncDelegate carglyInitialize];
            }
            [syncDelegate carglySyncStart];
            [self getUpdates];
        }
    }
}

// Not currently used as users are synced just like all other objects.
-(void) getUser {
	CarglyApiRequest* request = [[CarglyApiRequest alloc] init];
    request.callbackSelector = @selector(handleGetUser:);
    [request httpGet:@"/user"
            withParams:nil
           withToken:self.authToken
          withDelegate:self
          withSelector:@selector(handleGetUser:)];
}

-(void) handleGetUser:(CarglyApiRequest*) request {
	id jsonObject = request.responseData;
    
    id userId = [jsonObject objectForKey:@"id"];
    // if we don't have a user stored yet, the user ids match, or we haven't sync'd yet, let this sync proceed.
    if (self.userId == nil || [self.userId isEqual:userId] || self.syncBookmark == nil) {
        self.userId = [jsonObject objectForKey:@"id"];
        self.email = [jsonObject objectForKey:@"email"];
        [self storeConfig];
        [syncDelegate carglySyncStart];
        @try {
            self.syncingChanges = YES;
            [syncDelegate carglyUpdateObject:jsonObject];
        }
        @finally {
            self.syncingChanges = NO;
        }
        
        [self getUpdates];
    }
    else {
        // it looks like this app was previously sync'd with a different user's account
        [self logout];
    }
}

-(void) getUpdates {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.syncBookmark != nil) {
        [params setObject:[self.syncBookmark stringValue] forKey:@"bookmark"];
    }
    
	CarglyApiRequest* request = [[CarglyApiRequest alloc] init];
    [request httpGet:@"/updates"
          withParams:params
           withToken:self.authToken
        withDelegate:self
        withSelector:@selector(handleGetUpdates:)];
}

-(void) handleGetUpdates:(CarglyApiRequest*) request
{
    self.hasMoreUpdates = NO;
    @try {
        self.syncingChanges = YES;
        for (id obj in request.responseData) {
            NSString* type = [obj objectForKey:@"type"];
            if ([type isEqual: @"sync"]) {
                self.syncBookmark = [obj objectForKey:@"bookmark"];
                id b = [obj objectForKey:@"hasMoreUpdates"];
                self.hasMoreUpdates = b && [b isEqual:@"true"];
            }
            else if ([type isEqual: @"user"]) {
                id userId = [obj objectForKey:@"path"];
                // if we don't have a user stored yet, the user ids match, or we haven't sync'd yet, let this sync proceed.
                if (self.userId == nil || [self.userId isEqual:userId] || self.syncBookmark == nil) {
                    self.userId = [obj objectForKey:@"path"];
                    self.email = [obj objectForKey:@"email"];
                    [self storeConfig];
                    [syncDelegate carglyUpdateObject:obj];
                }
                else {
                    // it looks like this app was previously sync'd with a different user's account
                    [self logout];
                    break;
                }
                [syncDelegate carglyUpdateObject:obj];
            }
            else {
                [syncDelegate carglyUpdateObject:obj];
            }
            
        }
    }
    @finally {
        self.syncingChanges = NO;
    }

    [self storeConfig];
    
    // if we were returned a cursor, then there's more events to fetch
    if (self.hasMoreUpdates) {
        [self getUpdates];
    }
    else {
        // otherwise, it's time to send any changes to the server
        [self bulkUpdate];
    }
}

-(void) bulkUpdate
{
    // must have a bookmark at this point
    if (self.syncBookmark == nil) return;

    // get items to send
    self.itemsToBulkUpdate = [[NSMutableArray alloc] init];
    NSDictionary* item = nil;
    BOOL hasNewVehicle = FALSE;
    BOOL firstCheck = TRUE;

    @try {
        self.syncingChanges = YES;
        
        // check for vehicles needing to be sync'd
        while ((firstCheck || item != nil) && [self.itemsToBulkUpdate count] < 10) {
            firstCheck = FALSE;
            item = [syncDelegate carglyGetNewParentObject];
            // nil will terminate the, empty dictionary is just ignored
            if (item && [item count] > 0) {
                if (![item valueForKey:@"path"]) {
                    hasNewVehicle = TRUE;
                }
                [self.itemsToBulkUpdate addObject:item];
            }
        }

        // if we aren't adding any new parent objects, then it is okay to update all other types of records
        if (!hasNewVehicle) {
            // check for other objects needing update
            firstCheck = TRUE;
            while ((firstCheck || item != nil) && [self.itemsToBulkUpdate count] < 10) {
                firstCheck = FALSE;
                item = [syncDelegate carglyGetUpdatedObject];
                if (item && [item count] > 0) {
                    [self.itemsToBulkUpdate addObject:item];
                }
            }
        }
    }
    @finally {
        self.syncingChanges = NO;
    }
    
    // add sync bookmark
    item = [[NSMutableDictionary alloc] init];
    [item setValue:@"sync" forKey:@"type"];
    [item setValue:self.syncBookmark forKey:@"bookmark"];
    [self.itemsToBulkUpdate addObject:item];
    
    
    if ([self.itemsToBulkUpdate count] > 1) {
        CarglyApiRequest* request = [[CarglyApiRequest alloc] init];
        [request httpPostJson:@"/updates"
                     withJson:self.itemsToBulkUpdate
                    withToken:self.authToken
                 withDelegate:self
                 withSelector:@selector(handleBulkUpdates:)];
    }
    else {
        [syncDelegate carglySyncComplete];
    }
}

-(void) handleBulkUpdates:(CarglyApiRequest*) request {
    int index = 0;
    int errorCount = 0;
    @try {
        self.syncingChanges = YES;
        for (id obj in request.responseData) {
            NSMutableDictionary* sentItem = [self.itemsToBulkUpdate objectAtIndex:index++];
            [obj setObject:[sentItem valueForKey:@"localId"] forKey:@"localId"];
            if ([[obj valueForKey:@"status"] isEqual:@"error"]) {
                errorCount++;
            }
            if (![[obj valueForKey:@"type"] isEqual:@"sync"]) {
                [syncDelegate carglySyncStatus:obj];
            }
        }
    }
    @finally {
        self.syncingChanges = NO;
    }

    if (errorCount == 0) {
        [self bulkUpdate];
    }
    else {
        self.retryCount++;
        if (self.retryCount > 2) {
            [syncDelegate carglyError];
        }
        else {
            // reset and try the sync again
            self.syncBookmark = nil;
            [syncDelegate carglySyncStart];
            [self getUpdates];
        }
    }
}


-(void) logout {
	if (![self isDisconnected]) {
//		CarglyApiRequest* request = [[CarglyApiRequest alloc] init];
//		[request doRequest:self.userId withToken:self.authToken withDelegate:self withMethod:@"logout" withParams:@"" withJSON:nil];
	}
	else {
		self.authToken = nil;
		[self storeConfig];
	}
}

-(void) carglyRequestFailure:(NSError*)error forRequest:(CarglyApiRequest*) request {
    if (self.itemsToBulkUpdate != nil) {
        for (id sentItem in self.itemsToBulkUpdate) {
            if (![[sentItem valueForKey:@"type"] isEqual:@"sync"]) {
                NSMutableDictionary* obj = [[NSMutableDictionary alloc] init];
                [obj setObject:[sentItem valueForKey:@"localId"] forKey:@"localId"];
                [obj setObject:@"error" forKey:@"status"];
                [obj setObject:@"Rolling back synchronization session." forKey:@"message"];
                [syncDelegate carglySyncStatus:obj];
            }
        }
    }
    
	if (error && [[error domain] compare:NSURLErrorDomain] == 0 && [error code] == 401) {
		// handle unauthorized by logging them out
		self.authToken = nil;
		[self storeConfig];
	}
    
    // send notifications
    [syncDelegate carglyError];
}

-(NSString*) documentsPath {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0]; 
}

-(NSDictionary*) loadConfigDictionary {
    NSDictionary* dict = nil;
	NSString* fileName = [[self documentsPath] stringByAppendingPathComponent:@"CarglyConfig.plist"];
	// try to load auth token from file first
	if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
		dict = [[NSDictionary alloc] initWithContentsOfFile:fileName];
	}
    return dict;
}

-(void) loadConfig {
    NSDictionary* dict = [self loadConfigDictionary];
    if (dict) {
        self.authToken = [dict valueForKey:@"authToken"];
        self.userId = [dict valueForKey:@"userId"];
        self.email = [dict valueForKey:@"email"];
        self.syncBookmark = [dict valueForKey:@"bookmark"];
        id hasMoreUpdates = [dict valueForKey:@"hasMoreUpdates"];
        self.hasMoreUpdates = hasMoreUpdates && [hasMoreUpdates isEqual:@"true"];
    }
}

-(void) storeConfig {
	NSString* fileName = [[self documentsPath] stringByAppendingPathComponent:@"CarglyConfig.plist"];

	NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
	if (self.authToken) [dict setObject:self.authToken forKey:@"authToken"];
	if (self.userId) [dict setObject:self.userId forKey:@"userId"];
	if (self.email) [dict setObject:self.email forKey:@"email"];
   	if (self.syncBookmark) {
        [dict setObject:self.syncBookmark forKey:@"bookmark"];
        [dict setObject:(self.hasMoreUpdates ? @"true" : @"false") forKey:@"hasMoreUpdates"];
    }
	
	[dict writeToFile:fileName atomically:YES];
}


-(void) storeTaxDeductionRates:(id)jsonObject {
	NSString* fileName = [[self documentsPath] stringByAppendingPathComponent:@"taxDeductionRates.json"];
    [[CarglyApi toJson:jsonObject] writeToFile:fileName atomically:YES encoding:NSUTF8StringEncoding error:nil];
	[self loadTaxDeductionRates];
}

-(BOOL) loadTaxDeductionRates {
	// get a string with today's year
	NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy"];
	NSString* stringYear = [formatter stringFromDate:now];
	
	NSString* fileName = [[self documentsPath] stringByAppendingPathComponent:@"taxDeductionRates.json"];
	// try to load auth token from file first
	if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
		
		NSString* jsonString = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
		NSDictionary* yearDict = [CarglyApi fromJson:jsonString];
		NSDictionary* rateDict = [yearDict objectForKey:stringYear];
		if (rateDict) {
			businessTaxRate = [[rateDict objectForKey:@"business"] doubleValue];
			medicalTaxRate = [[rateDict objectForKey:@"medical"] doubleValue];
			charitableTaxRate = [[rateDict objectForKey:@"charitable"] doubleValue];
			movingTaxRate = [[rateDict objectForKey:@"moving"] doubleValue];
			return TRUE;
		}
	}
	return FALSE;
}

-(void) checkTaxDeductionRates {
	if (![self loadTaxDeductionRates]) {
		CarglyApiRequest* request = [[CarglyApiRequest alloc] init];
		[request doTaxDeductionRequest:self];		
	}
}


-(BOOL) needsAuthToken {
	return self.authToken == nil || [self.authToken length] == 0;
}


-(void) processNearby:(id)json {

	NSMutableArray* locations = [[NSMutableArray alloc] init];
	NSMutableDictionary* existing = [[NSMutableDictionary alloc] init];
	if (self.favoriteLocations) {
		for (NSDictionary *favLoc in self.favoriteLocations) {
			NSDecimalNumber* latNum = [[favLoc objectForKey:@"latitude"] isKindOfClass:[NSDecimalNumber class]] ? [favLoc objectForKey:@"latitude"] : nil;
			NSDecimalNumber* lonNum = [[favLoc objectForKey:@"longitude"] isKindOfClass:[NSDecimalNumber class]] ? [favLoc objectForKey:@"longitude"] : nil;
			
			if (latNum != nil && lonNum != nil) {
				NSNumber* distance = [favLoc objectForKey:@"distance"];
				if ([distance doubleValue] < 10) {				
					[locations addObject:favLoc];
				
					NSString* key = [[NSString alloc] initWithFormat:@"%3.6f,%3.6f", [latNum doubleValue], [lonNum doubleValue]];
					[existing setObject:favLoc forKey:key];
				}
			}
		}
	}
	
	
	for (NSDictionary *location in json) {
		NSMutableDictionary* locCopy = [[NSMutableDictionary alloc] init];
		[locCopy setObject:@"Fuel" forKey:@"type"];
		[locCopy setObject:[location objectForKey:@"name"] forKey:@"name"];
		[locCopy setObject:[location objectForKey:@"address"] forKey:@"address"];
		[locCopy setObject:[location objectForKey:@"city"] forKey:@"city"];
		[locCopy setObject:[location objectForKey:@"state"] forKey:@"state"];
		[locCopy setObject:[location objectForKey:@"zip"] forKey:@"zip"];
		[locCopy setObject:[location objectForKey:@"lat"] forKey:@"latitude"];
		[locCopy setObject:[location objectForKey:@"lon"] forKey:@"longitude"];	
		
		NSString* latStr = [[locCopy objectForKey:@"latitude"] isKindOfClass:[NSNull class]] ? nil : [locCopy objectForKey:@"latitude"];
		NSString* lonStr = [[locCopy objectForKey:@"longitude"] isKindOfClass:[NSNull class]] ? nil : [locCopy objectForKey:@"longitude"];
		
		if (latStr != nil && lonStr != nil) {
			double lat = [latStr doubleValue];
			double lon = [lonStr doubleValue];			
			double distance = [self calcDistance:currentLat long1:currentLon la2:lat long2:lon];
			
			NSNumber* number = [[NSNumber alloc] initWithDouble:distance];
			[locCopy setValue:number forKey:@"distance"];
			
			NSString* key = [[NSString alloc] initWithFormat:@"%3.6f,%3.6f", lat, lon];
			if ([existing objectForKey:key] == nil) {
				[locations addObject:locCopy];
			}

		}
	}
	
	NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance" ascending:YES];
	[locations sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

	self.nearbyLocations = locations;
}

-(void) processFavorites:(id)json {
	self.favoriteLocations = [self addDistanceToLocations:json];
}

-(NSMutableArray*) addDistanceToLocations:(id)json {
	NSMutableArray* locations = [[NSMutableArray alloc] init];
	for (NSDictionary *location in json) {
		NSMutableDictionary* locCopy = [location mutableCopy];
		
		NSDecimalNumber* latNum = [[locCopy objectForKey:@"latitude"] isKindOfClass:[NSDecimalNumber class]] ? [locCopy objectForKey:@"latitude"] : nil;
		NSDecimalNumber* lonNum = [[locCopy objectForKey:@"longitude"] isKindOfClass:[NSDecimalNumber class]] ? [locCopy objectForKey:@"longitude"] : nil;
		
		if (latNum != nil && lonNum != nil) {
			double lat = [latNum doubleValue];
			double lon = [lonNum doubleValue];
			double distance = [self calcDistance:currentLat long1:currentLon la2:lat long2:lon];
			
			NSNumber* number = [[NSNumber alloc] initWithDouble:distance];
			[locCopy setValue:number forKey:@"distance"];
		}
		[locations addObject:locCopy];
	}
	return locations;	
}

-(double)calcDistance:(double)lat1 long1:(double)lng1 la2:(double)lat2 long2:(double)lng2 {
    //NSLog(@"latitude 1:%.7f,longitude1:%.7f,latitude2:%.7f,longtitude2:%.7f",lat1,lng1,lat2,lng2);
    double radLat1 = [self rad:lat1];
    double radLat2 = [self rad:lat2];
    double a = radLat1 - radLat2;
    double b = [self rad:lng1] -[self rad:lng2];
    double s = 2 * asin(sqrt(pow(sin(a/2),2) + cos(radLat1)*cos(radLat2)*pow(sin(b/2),2)));
    s = s * 3958.75;
    s = round(s * 10000) / 10000;
    return s;
}

-(double)rad:(double)d
{
    return d *3.14159265 / 180.0;
}

- (void)reachabilityChanged:(NSNotification *)note {
	remoteHostStatus = [hostReachability currentReachabilityStatus];    
    [syncDelegate reachabilityDidChange:![self isDisconnected]];
}

-(BOOL) isDisconnected {
	return remoteHostStatus == NotReachable;
}

+(NSDateFormatter*) dateFormatter {
	static NSDateFormatter* formatter = nil;
	if (!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd"];
	}
	
	return formatter;
}

+(NSDateFormatter*) timestampFormatter {
	static NSDateFormatter* formatter = nil;
	if (!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd HH:mm Z"];
	}
	
	return formatter;
}

+(NSString*) stringForfuelType:(FuelType)fuelType {
	switch (fuelType) {
		case UnknownFuelType:
			return @"Unknown";
		case RegularFuelType:
			return @"Regular";
		case SuperFuelType:
			return @"Super";
		case PremiumFuelType:
			return @"Premium";
		case DieselFuelType:
			return @"Diesel";
	}
	return nil;
}

+(FuelType) fuelTypeForString:(NSString*)typeString {
	if ([typeString compare:@"Regular"] == NSOrderedSame) {
		return RegularFuelType;
	}
	else if ([typeString compare:@"Super"] == NSOrderedSame) {
		return SuperFuelType;
	}
	else if ([typeString compare:@"Premium"] == NSOrderedSame) {
		return PremiumFuelType;
	}
	else if ([typeString compare:@"Diesel"] == NSOrderedSame) {
		return DieselFuelType;
	}
	return UnknownFuelType;
}

// singleton access
+(CarglyApi*) singleton {
	static CarglyApi* instance;
	
	if (!instance) {
		instance = [[CarglyApi alloc] initWithReachability];
	}
	
	return instance;
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
