//
//  CarglyApi.h
//  TestCarglyWebAuth
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CarglyApiRequestDelegate.h"
#import "CarglyApiRequest.h"
#import "Reachability.h"

typedef enum {
	UnknownFuelType = 0,
	RegularFuelType,
	SuperFuelType,
	PremiumFuelType,
	DieselFuelType
} FuelType;

typedef enum {
	DeductionTypeNone = 0,
	DeductionTypeBusiness,
	DeductionTypeMedical,
	DeductionTypeCharitiable,
	DeductionTypeMoving
} DeductionType;

@interface CarglyApi : NSObject <CarglyApiRequestDelegate> {
	double currentLat;
	double currentLon;
	
	NetworkStatus remoteHostStatus;
	Reachability* hostReachability;
	
	double businessTaxRate;
	double medicalTaxRate;
	double charitableTaxRate;
	double movingTaxRate;
}

@property (nonatomic) BOOL syncingChanges;
@property (nonatomic, strong) NSString* authToken;
@property (nonatomic, strong) NSString* userId;
@property (nonatomic, strong) NSString* email;

@property (nonatomic, strong) NSNumber* syncBookmark;
@property (nonatomic) BOOL hasMoreUpdates;
@property (nonatomic, strong) NSMutableArray* itemsToBulkUpdate;

@property (nonatomic) int retryCount;

@property (nonatomic, strong) NSMutableArray* nearbyLocations;
@property (nonatomic, strong) NSMutableArray* favoriteLocations;

@property (nonatomic, strong) id syncDelegate;
@property (nonatomic, strong) NSString* appId;

@property (nonatomic) double businessTaxRate;
@property (nonatomic) double medicalTaxRate;
@property (nonatomic) double charitableTaxRate;
@property (nonatomic) double movingTaxRate;


// static helpers
+(CarglyApi*) singleton;
+(NSString*) stringForfuelType:(FuelType)fuelType;
+(FuelType) fuelTypeForString:(NSString*)typeString;
+(NSDateFormatter*) dateFormatter;
+(NSDateFormatter*) timestampFormatter;

// api calls
-(void) sync;
-(void) logout;
//-(void) getNearbyFuel:(double)lat andLon:(double)lon;
-(void) checkTaxDeductionRates;
-(void) storeTaxDeductionRates:(id)jsonObject;
-(BOOL) loadTaxDeductionRates;

// other
-(void) openAuthUrl;
-(BOOL) isDisconnected;
- (void)reachabilityChanged:(NSNotification *)note;
-(void) processNearby:(id)json;
-(void) processFavorites:(id)json;
-(NSMutableArray*) addDistanceToLocations:(id)locations;
-(double) calcDistance:(double)lat1 long1:(double)lng1 la2:(double)lat2 long2:(double)lng2;
-(double) rad:(double)d;
-(NSString*) documentsPath;
-(void) loadConfig;
-(void) storeConfig;
-(BOOL) needsAuthToken;

@end
