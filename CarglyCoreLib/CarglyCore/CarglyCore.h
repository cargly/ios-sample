//
//  CarglyCore.h
//  CarglyCore
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CarglySyncDelegate.h"

@interface CarglyCore : NSObject

+(void) initCargly:(NSString*)appId withSyncDelegate:(id)delegate;

+(void) saveAuthToken:(NSURL *)redirectUrl;

+(void) syncNow;

+(BOOL) versionAllowsUpdate:(NSNumber*)remoteVersion localVersion:(NSNumber*)localVersion;

// Useful to determine if the client has been synced with the cargly service
+(BOOL) syncEnabled;

// Returns true only while CarglyCore is calling CarglySyncDelegate methods. If you're hooking CoreData notifcations
// to track changes, use this method to ignore notifications for changes that don't need to be synced.
+(BOOL) isSyncingChanges;

+(NSString*)toCarglyTimestamp:(NSDate*)timestamp;

+(NSDate*) fromCarglyTimestamp:(NSString*)timestamp;

@end
