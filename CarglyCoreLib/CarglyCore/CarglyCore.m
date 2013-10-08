//
//  CarglyCore.m
//  CarglyCore
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import "CarglyCore.h"
#import "CarglyApi.h"


@implementation CarglyCore


+(void) initCargly:(NSString*)appId withSyncDelegate:(id)delegate
{
    [CarglyApi singleton].appId = appId;
    [CarglyApi singleton].syncDelegate = delegate;
    [[CarglyApi singleton] loadConfig];
}

+(BOOL) syncEnabled
{
    return [CarglyApi singleton].userId != nil;
}

+(BOOL) isSyncingChanges
{
    return [CarglyApi singleton].syncingChanges;
}

+(void) saveAuthToken: (NSURL *)redirectUrl
{
    if (![CarglyApi singleton].authToken) {
        NSString * q = [redirectUrl query];
        NSArray * pairs = [q componentsSeparatedByString:@"&"];
        NSMutableDictionary * kvPairs = [NSMutableDictionary dictionary];
        for (NSString * pair in pairs) {
            NSArray * bits = [pair componentsSeparatedByString:@"="];
            NSString * key = [[bits objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString * value = [[bits objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [kvPairs setObject:value forKey:key];
        }
     
        if ([kvPairs objectForKey:@"access_token"]) {
            [CarglyApi singleton].authToken = [kvPairs objectForKey:@"access_token"];
            [[CarglyApi singleton] storeConfig];
        }
    }
}

+(void) syncNow
{
    [[CarglyApi singleton] sync];
}

+(BOOL) versionAllowsUpdate:(NSNumber*)remoteVersion localVersion:(NSNumber*)localVersion
{
    return localVersion == 0 ||
        ([remoteVersion compare:localVersion] == NSOrderedDescending);
}

+(NSDateFormatter*) getTimestampFormatter
{
    static NSDateFormatter* timestampFormatter = nil;
	if (!timestampFormatter) {
		timestampFormatter = [[NSDateFormatter alloc] init];
		[timestampFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
	}
    return timestampFormatter;
}


+(NSString*)toCarglyTimestamp:(NSDate*)timestamp
{
    return [[CarglyCore getTimestampFormatter] stringFromDate:timestamp];
}

+(NSDate*) fromCarglyTimestamp:(NSString*)timestamp
{
    return [[CarglyCore getTimestampFormatter] dateFromString:timestamp];
}

@end
