//
//  AppDelegate.m
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import "AppDelegate.h"

#import "ActivityMasterViewController.h"
#import "CarglyCore.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	if ([[url description] rangeOfString:@"access_token"].length > 0) {
        [CarglyCore saveAuthToken: url];
        [CarglyCore syncNow];
    }
    return TRUE;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    self.controller = (ActivityMasterViewController *)navigationController.topViewController;
    self.controller.managedObjectContext = self.managedObjectContext;
    
    // init cargly
    
    [CarglyCore initCargly:@"RQ9cUrUCnoWRCEiMlDfO69VXmWnZlKx3" withSyncDelegate:self]; // dev test
    
    // listen for changes to core data object
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDataModelChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if ([CarglyCore syncEnabled]) {
        [CarglyCore syncNow];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
//        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Cargly_Demo" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Cargly_Demo.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }    
    
    return _persistentStoreCoordinator;
}

-(NSManagedObject*) findFirstOrCreateEntityByPredicate:(NSString*)entityName
                                    withPredicate:(NSString*)predicate
                                 allowCreate:(BOOL)canCreate
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    if (predicate) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:predicate];
        [request setPredicate:pred];
    }
    
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if ([objects count] == 0) {
        if (canCreate) {
            return [NSEntityDescription insertNewObjectForEntityForName:[entityDesc name]
                                                 inManagedObjectContext:self.managedObjectContext];
        }
        else {
            return nil;
        }

    } else {
        return [objects objectAtIndex:0];
    }
}

-(NSManagedObject*) findOrCreateEntityByAttr:(NSString*)entityName
                                    withAttr:(NSString*)attrName withValue:(id)value
                                 allowCreate:(BOOL)canCreate
{
    if ([entityName isEqualToString:@"User"]) {
        // ignore the predicate for the User object - there should be only one
        return [self findFirstOrCreateEntityByPredicate:entityName withPredicate:nil allowCreate:canCreate];
    }
    else {
        NSString *predicateString = [NSString stringWithFormat:@"(%@ == '%@')", attrName, value];
        return [self findFirstOrCreateEntityByPredicate:entityName withPredicate:predicateString allowCreate:canCreate];
    }
}

-(NSManagedObject*) findByUriString:(NSString*)uriString
{
    NSError *error;
    NSURL* urlId = [[NSURL alloc] initWithString:uriString];
    NSManagedObjectID* moID = [[self.managedObjectContext persistentStoreCoordinator] managedObjectIDForURIRepresentation:urlId];
    NSManagedObject* localObj = [self.managedObjectContext existingObjectWithID:moID error:&error];
    if (error) {
        return nil;
    }
    return localObj;
}

-(NSString*) getUriStringForManagedObject:(NSManagedObject*)object
{
    [self.managedObjectContext obtainPermanentIDsForObjects:@[object] error:nil];
    NSManagedObjectID *moID = [object objectID];
    NSURL* moUrl = [moID URIRepresentation];
    return [moUrl absoluteString];
}

-(void)saveSyncLogEntry:(NSManagedObject*)object withOp:(NSString*)op withEntryCache:(NSMutableDictionary*)syncEntries
{
    // skip sync log entries
    if ([[object entity].name isEqualToString:@"SyncLog"]) return;
    if ([[object entity].name isEqualToString:@"WorkDetail"]) return;
    
    NSString* localId = [self getUriStringForManagedObject:object];

    // make sure we don't create multiple uncommitted entries for the same object
    
    NSManagedObject* syncLog = nil;
    if (syncEntries) {
        syncLog = [syncEntries objectForKey:localId];
        if (!syncLog) {
            syncLog = [self findOrCreateEntityByAttr:@"SyncLog" withAttr:@"localId" withValue:localId allowCreate:TRUE];
            [syncEntries setObject:syncLog forKey:localId];
        }
    }
    else {
        syncLog = [self findOrCreateEntityByAttr:@"SyncLog" withAttr:@"localId" withValue:localId allowCreate:TRUE];
    }
    
    if ([object valueForKey:@"cid"] == nil && [op isEqualToString:@"deleted"]) {
        // don't need to sync when a deleted object had never been synced to the server. just
        // delete the sync log entry
        [self.managedObjectContext deleteObject:syncLog];
    }
    else {
        [syncLog setValue:[object valueForKey:@"cid"] forKey:@"cid"];
        [syncLog setValue:[object valueForKey:@"cver"] forKey:@"cver"];
        if ([[object entity].name isEqualToString:@"Vehicle"]) {
            [syncLog setValue:@"vehicle" forKey:@"type"];
        }
        else if ([[object entity].name isEqualToString:@"Activity"]) {
            [syncLog setValue:[object valueForKey:@"type"] forKey:@"type"];
        }
        else if ([[object entity].name isEqualToString:@"User"]) {
            [syncLog setValue:[object valueForKey:@"type"] forKey:@"type"];
        }
        [syncLog setValue:localId forKey:@"localId"];
        [syncLog setValue:[NSNumber numberWithBool:NO] forKey:@"syncing"];
        [syncLog setValue:op forKey:@"op"];
    }
}

- (void)handleDataModelChange:(NSNotification *)note
{
    // this will get called whenever a change to the coredata model is changed.
    if ([CarglyCore syncEnabled] && ![CarglyCore isSyncingChanges])
    {
        NSMutableDictionary* syncEntries = [[NSMutableDictionary alloc] init];
        
        NSSet *updatedObjects = [[note userInfo] objectForKey:NSUpdatedObjectsKey];
        NSSet *deletedObjects = [[note userInfo] objectForKey:NSDeletedObjectsKey];
        NSSet *insertedObjects = [[note userInfo] objectForKey:NSInsertedObjectsKey];
        
        for (id obj in updatedObjects) {
            [self saveSyncLogEntry:obj withOp:@"updated" withEntryCache:syncEntries];
        }
        
        for (id obj in insertedObjects) {
            [self saveSyncLogEntry:obj withOp:@"inserted" withEntryCache:syncEntries];
        }
        
        for (id obj in deletedObjects) {
            [self saveSyncLogEntry:obj withOp:@"deleted" withEntryCache:syncEntries];
        }
        
        if ([syncEntries count] > 0) {
            // save all sync log entries
            NSError *error = nil;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
        }
    }
}

-(void) markEntitiesForSync:(NSString*)entityName
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:entityName
                                                  inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    for (id obj in objects) {
        [self saveSyncLogEntry:obj withOp:@"updated" withEntryCache:nil];
    }
}


-(void) carglyInitialize
{
    // create sync log entries for all sync-able objects in the db.
    [self markEntitiesForSync:@"User"];
    [self markEntitiesForSync:@"Vehicle"];
    [self markEntitiesForSync:@"Activity"];
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}


-(void)reachabilityDidChange:(BOOL)isReachable
{
    if ([CarglyCore syncEnabled]) {
        [CarglyCore syncNow];
    }
}

-(void) carglySyncStart
{
    [self.controller setSyncActivity:YES];
    
    // the sync is starting, so make sure that all sync log entries have syncing = NO, otherwise they'll be skipped.
    // syncing might be YES if a previous attempt to sync ran into issues.
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"SyncLog"
                                                  inManagedObjectContext:self.managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"syncing == YES"];
    
    [request setPredicate:pred];
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    for (id obj in objects) {
        [obj setValue:[NSNumber numberWithBool:NO] forKey:@"syncing"];
    }
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

-(void) carglySyncComplete
{
    [self.controller setSyncActivity:NO];
}

// handle copying values from the server to the client
-(void) carglyUpdateObject:(NSDictionary*)object
{
    NSString* type = [object objectForKey:@"type"];
    if ([type isEqualToString:@"vehicle"])
    {
        [self copyToLocalManagedObject:object withEntity:@"Vehicle"
                              withType:nil withCopier:^(NSString *type, NSManagedObject *dest, NSDictionary *src)
         {
             [dest setValue:[src objectForKey:@"odometer"] forKey:@"odometer"];
             [dest setValue:[src objectForKey:@"name"] forKey:@"name"];
             [dest setValue:[src objectForKey:@"postal_code"] forKey:@"postalCode"];
         }];
    }
    else if ([type isEqualToString:@"user"]) {
        [self copyToLocalManagedObject:object withEntity:@"User"
                              withType:@"user" withCopier:^(NSString *type, NSManagedObject *dest, NSDictionary *src)
         {
             // Users are slightly special: only set the value if the server sent one. on the very first sync, the server
             // is careful to only send settings if vehicles already exist on the server.
             if ([src objectForKey:@"email"]) [dest setValue:[src objectForKey:@"email"] forKey:@"email"];
             if ([src objectForKey:@"full_name"]) [dest setValue:[src objectForKey:@"full_name"] forKey:@"fullName"];
             if ([src objectForKey:@"distance_units"]) [dest setValue:[src objectForKey:@"distance_units"] forKey:@"distanceUnits"];
             if ([src objectForKey:@"fuel_units"]) [dest setValue:[src objectForKey:@"fuel_units"] forKey:@"fuelUnits"];
         }];
    }
    else if ([type isEqualToString:@"refueling"]) {
        [self copyToLocalManagedObject:object withEntity:@"Activity"
                              withType:@"refueling" withCopier:^(NSString *type, NSManagedObject *dest, NSDictionary *src)
         {
             [dest setValue:[CarglyCore fromCarglyTimestamp:[src objectForKey:@"occurred"]] forKey:@"occurred"];
             [dest setValue:[src objectForKey:@"odometer"] forKey:@"odometer"];
             [dest setValue:[src objectForKey:@"location_name"] forKey:@"locationName"];
             [dest setValue:[src objectForKey:@"cost"] forKey:@"cost"];
             [dest setValue:[src objectForKey:@"fuel"] forKey:@"fuel"];
             [dest setValue:[src objectForKey:@"fuel_units"] forKey:@"fuelUnits"];
             [dest setValue:[src objectForKey:@"fuel_kind"] forKey:@"fuelKind"];
         }];
    }
    else if ([type isEqualToString:@"expense"]) {
        [self copyToLocalManagedObject:object withEntity:@"Activity"
                              withType:@"expense" withCopier:^(NSString *type, NSManagedObject *dest, NSDictionary *src)
         {
             [dest setValue:[CarglyCore fromCarglyTimestamp:[src objectForKey:@"occurred"]] forKey:@"occurred"];
             [dest setValue:[src objectForKey:@"odometer"] forKey:@"odometer"];
             [dest setValue:[src objectForKey:@"summary"] forKey:@"summary"];
             [dest setValue:[src objectForKey:@"location_name"] forKey:@"locationName"];
             [dest setValue:[src objectForKey:@"cost"] forKey:@"cost"];
             
             NSArray* details = [src objectForKey:@"detail_items"];
             if (details) {
                 [[dest mutableSetValueForKey:@"workDetails"] removeAllObjects];
                 for (id detail in details) {
                     NSManagedObject* localDetail = [NSEntityDescription insertNewObjectForEntityForName:@"WorkDetail"
                                                                                  inManagedObjectContext:self.managedObjectContext];
                     [localDetail setValue:[detail objectForKey:@"cost"] forKey:@"cost"];
                     [localDetail setValue:[detail objectForKey:@"maintenance_key"] forKey:@"workCode"];
                     [localDetail setValue:[detail objectForKey:@"notes"] forKey:@"details"];
                     [localDetail setValue:[detail objectForKey:@"other_name"] forKey:@"otherLabel"];
                     [[dest mutableSetValueForKey:@"workDetails"] addObject:localDetail];
                 }
             }
             
         }];
    }
    else if ([type isEqualToString:@"use"]) {
        [self copyToLocalManagedObject:object withEntity:@"Activity"
                              withType:@"use" withCopier:^(NSString *type, NSManagedObject *dest, NSDictionary *src)
         {
             [dest setValue:[src objectForKey:@"purpose"] forKey:@"purpose"];
             [dest setValue:[src objectForKey:@"destination"] forKey:@"destination"];
             [dest setValue:[src objectForKey:@"driver"] forKey:@"driver"];
             
             [dest setValue:[CarglyCore fromCarglyTimestamp:[src objectForKey:@"start_time"]] forKey:@"occurred"];
             [dest setValue:[src objectForKey:@"start_odo"] forKey:@"odometer"];
             [dest setValue:[CarglyCore fromCarglyTimestamp:[src objectForKey:@"end_time"]] forKey:@"completedTime"];
             [dest setValue:[src objectForKey:@"end_odo"] forKey:@"completedOdometer"];
         }];
    }
}

-(NSDictionary*) getUpdatedVehicle:(BOOL)newOnly
{
    return [self copyToRemoteDictionary:@"vehicle" withParent:nil withNewOnly:newOnly
                             withCopier:^(NSString *type, NSMutableDictionary *dest, NSManagedObject *src)
            {
                if ([src valueForKey:@"odometer"]) [dest setObject:[src valueForKey:@"odometer"] forKey:@"odometer"];
                if ([src valueForKey:@"name"]) [dest setObject:[src valueForKey:@"name"] forKey:@"name"];
                if ([src valueForKey:@"postalCode"]) [dest setObject:[src valueForKey:@"postalCode"] forKey:@"postal_code"];
            }];
}

-(NSDictionary*) carglyGetNewParentObject
{
    // Here, we look specifically for only new vehicles. Updates to existing vehicles are handled in carglyGetUpdatedObject.
    return [self getUpdatedVehicle:YES];
}

-(NSDictionary*) carglyGetUpdatedObject
{
    NSDictionary* obj = [self copyToRemoteDictionary:@"user" withParent:nil withNewOnly:NO
                                      withCopier:^(NSString *type, NSMutableDictionary *dest, NSManagedObject *src)
                     {
                         if ([src valueForKey:@"email"]) [dest setObject:[src valueForKey:@"email"] forKey:@"email"];
                         if ([src valueForKey:@"fullName"]) [dest setObject:[src valueForKey:@"fullName"] forKey:@"full_name"];
                         if ([src valueForKey:@"distanceUnits"]) [dest setObject:[src valueForKey:@"distanceUnits"] forKey:@"distance_units"];
                         if ([src valueForKey:@"fuelUnits"]) [dest setObject:[src valueForKey:@"fuelUnits"] forKey:@"fuel_units"];
                     }];

    if (!obj) obj = [self getUpdatedVehicle:NO];

    if (!obj) obj = [self copyToRemoteDictionary:@"refueling" withParent:@"vehicle" withNewOnly:NO
                                      withCopier:^(NSString *type, NSMutableDictionary *dest, NSManagedObject *src)
                     {
                         if ([src valueForKey:@"occurred"]) [dest setObject:[CarglyCore toCarglyTimestamp:[src valueForKey:@"occurred"]] forKey:@"occurred"];
                         if ([src valueForKey:@"odometer"]) [dest setObject:[src valueForKey:@"odometer"] forKey:@"odometer"];
                         if ([src valueForKey:@"locationName"]) [dest setObject:[src valueForKey:@"locationName"] forKey:@"location_name"];
                         if ([src valueForKey:@"cost"]) [dest setObject:[src valueForKey:@"cost"] forKey:@"cost"];
                         if ([src valueForKey:@"fuel"]) [dest setObject:[src valueForKey:@"fuel"] forKey:@"fuel"];
                         if ([src valueForKey:@"fuelUnits"]) [dest setObject:[src valueForKey:@"fuelUnits"] forKey:@"fuel_units"];
                         if ([src valueForKey:@"fuelKind"]) [dest setObject:[src valueForKey:@"fuelKind"] forKey:@"fuel_kind"];
                     }];
    
    if (!obj) obj = [self copyToRemoteDictionary:@"expense" withParent:@"vehicle" withNewOnly:NO
                                      withCopier:^(NSString *type, NSMutableDictionary *dest, NSManagedObject *src)
                     {
                         if ([src valueForKey:@"occurred"]) [dest setObject:[CarglyCore toCarglyTimestamp:[src valueForKey:@"occurred"]] forKey:@"occurred"];
                         if ([src valueForKey:@"odometer"]) [dest setObject:[src valueForKey:@"odometer"] forKey:@"odometer"];
                         if ([src valueForKey:@"summary"]) [dest setObject:[src valueForKey:@"summary"] forKey:@"summary"];
                         if ([src valueForKey:@"locationName"]) [dest setObject:[src valueForKey:@"locationName"] forKey:@"location_name"];
                         if ([src valueForKey:@"cost"]) [dest setObject:[src valueForKey:@"cost"] forKey:@"cost"];
                         
                         NSSet* srcDetails = [src mutableSetValueForKey:@"workDetails"];
                         if (srcDetails) {
                             NSMutableArray* destDetails = [[NSMutableArray alloc] init];
                             for (id srcDetail in srcDetails) {
                                 NSMutableDictionary* destDetail = [[NSMutableDictionary alloc] init];
                                 [destDetail setValue:[srcDetail valueForKey:@"cost"] forKey:@"cost"];
                                 [destDetail setValue:[srcDetail valueForKey:@"workCode"] forKey:@"maintenance_key"];
                                 [destDetail setValue:[srcDetail valueForKey:@"details"] forKey:@"notes"];
                                 [destDetail setValue:[srcDetail valueForKey:@"otherLabel"] forKey:@"other_name"];
                                 [destDetails addObject:destDetail];
                             }
                             [dest setObject:destDetails forKey:@"detail_items"];
                         }
                     }];
  
    if (!obj) obj = [self copyToRemoteDictionary:@"use" withParent:@"vehicle" withNewOnly:NO
                                      withCopier:^(NSString *type, NSMutableDictionary *dest, NSManagedObject *src)
                     {
                         if ([src valueForKey:@"purpose"]) [dest setObject:[src valueForKey:@"purpose"] forKey:@"purpose"];
                         if ([src valueForKey:@"destination"]) [dest setObject:[src valueForKey:@"destination"] forKey:@"destination"];
                         if ([src valueForKey:@"driver"]) [dest setObject:[src valueForKey:@"driver"] forKey:@"driver"];
                         if ([src valueForKey:@"occurred"]) {
                             [dest setObject:[CarglyCore toCarglyTimestamp:[src valueForKey:@"occurred"]] forKey:@"start_time"];
                         }
                         if ([src valueForKey:@"odometer"]) [dest setObject:[src valueForKey:@"odometer"] forKey:@"start_odo"];
                         if ([src valueForKey:@"completedTime"]) {
                             [dest setObject:[CarglyCore toCarglyTimestamp:[src valueForKey:@"completedTime"]] forKey:@"end_time"];
                         }
                         if ([src valueForKey:@"completedOdometer"]) [dest setObject:[src valueForKey:@"completedOdometer"] forKey:@"end_odo"];
                         [dest setObject:@"None" forKey:@"deductible_type"];
                     }];
    return obj;
}

-(void) carglySyncStatus:(NSDictionary*)result
{
    NSError *error = nil;
    // load the sync log entry for this change
    NSManagedObject* syncLogEntry = [self findFirstOrCreateEntityByPredicate:@"SyncLog"
                    withPredicate:[NSString stringWithFormat:@"(localId == '%@')",
                                   [result objectForKey:@"localId"]] allowCreate:FALSE];
    
    if ([[result objectForKey:@"status"] isEqual:@"success"]) {
        NSManagedObject* localObj = [self findByUriString:[result objectForKey:@"localId"]];
        if (localObj) {
            NSString* remoteUrl = [result objectForKey:@"url"];
            [localObj setValue:remoteUrl forKey:@"cid"];
            [localObj setValue:[result objectForKey:@"version"] forKey:@"cver"];
        }

        [self.managedObjectContext deleteObject: syncLogEntry];
    }
    else if ([[result objectForKey:@"status"] isEqual:@"not_found"]) {
        NSManagedObject* localObj = [self findByUriString:[result objectForKey:@"localId"]];
        // the object no longer exists on the server, so delete it here too
        if (localObj) {
            [self.managedObjectContext deleteObject: localObj];
        }
        [self.managedObjectContext deleteObject: syncLogEntry];
    }
    else {
        // an error occured, so the object still needs syncing
        [syncLogEntry setValue:[NSNumber numberWithBool:NO] forKey:@"syncing"];
    }
    
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

-(void) carglyError
{
    [self.controller setSyncError:@"Error updating"];
}

#pragma mark - Object Copy Helpers


-(void) copyToLocalManagedObject:(NSDictionary*)remoteObj withEntity:(NSString*)entityName withType:(NSString*)remoteType
                      withCopier:(void (^)(NSString* type, NSManagedObject* dest, NSDictionary* src))copier
{
    // look for car. if found, update it, otherwise create it
    NSString* remoteUrl = [remoteObj objectForKey:@"url"];
    NSManagedObject* localObj = [self findOrCreateEntityByAttr:entityName withAttr:@"cid" withValue: remoteUrl allowCreate:TRUE];

    if (localObj) {
        // find any sync log entries that might be pending. they need to be deleted
        NSString* localId = [self getUriStringForManagedObject:localObj];
        NSManagedObject* syncLogEntry = [self findFirstOrCreateEntityByPredicate:@"SyncLog"
                                                                   withPredicate:[NSString stringWithFormat:@"(localId == '%@')", localId] allowCreate:FALSE];
        
        if ([remoteObj objectForKey:@"deleted"]) {
            [self.managedObjectContext deleteObject: localObj];
        }
        // verfiy the version is newer
        else if ([CarglyCore versionAllowsUpdate:[remoteObj objectForKey:@"version"] localVersion:[localObj valueForKey:@"cver"]])
        {
            // if this object is related to a car, fix up the relationship
            if ([remoteObj objectForKey:@"vehicle_url"]) {
                NSManagedObject* localCar = [self findOrCreateEntityByAttr:@"Vehicle"
                                withAttr:@"cid" withValue: [remoteObj objectForKey:@"vehicle_url"] allowCreate:FALSE];
                [localObj setValue:localCar forKey:@"vehicle"];
            }
            
            if (remoteType) [localObj setValue:remoteType forKey:@"type"];
            [localObj setValue:[CarglyCore fromCarglyTimestamp:[remoteObj objectForKey:@"created"]] forKey:@"created"];
            [localObj setValue:remoteUrl forKey:@"cid"];
            [localObj setValue:[remoteObj objectForKey:@"version"] forKey:@"cver"];
            
            copier(remoteType, localObj, remoteObj);
        }
        
        // server changes always supercede client changes, so if a synclog record exists, delete it
        if (syncLogEntry) {
            // if the entity is a user, then don't delete the sync entry.
            if (![[syncLogEntry valueForKey:@"type"] isEqualToString:@"user"]) {
                [self.managedObjectContext deleteObject: syncLogEntry];
            }
        }

        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

// This method takes a block that should do the copying of entity-specific attribute. This method encapsulates the
// logic necessary to: 1) handle finding objects that have changed, 2) handle operation type (update versus delete),
// 3) all the bookeeping necessary to make sure objects are synchronized successfully and retried when a failure happens.
// This method is specific to the how a particluar client has decided to persist objects and also how they decide to
// track modification for synchronization.
-(NSDictionary*)copyToRemoteDictionary:(NSString*)objType withParent:(NSString*)parentAttr withNewOnly:(BOOL)newOnly
                            withCopier:(void (^)(NSString* type, NSMutableDictionary* dest, NSManagedObject* src))copier
{
    NSManagedObject* syncLogEntry = nil;
    if (newOnly) {
        syncLogEntry = [self findFirstOrCreateEntityByPredicate:@"SyncLog"
               withPredicate:[NSString stringWithFormat:@"(type == '%@' AND syncing == FALSE AND cid == nil)", objType] allowCreate:FALSE];
    }
    else {
        syncLogEntry = [self findFirstOrCreateEntityByPredicate:@"SyncLog"
               withPredicate:[NSString stringWithFormat:@"(type == '%@' AND syncing == FALSE)", objType] allowCreate:FALSE];
    }

    if (syncLogEntry) {
        NSMutableDictionary* remoteObj = [[NSMutableDictionary alloc] init];
        if ([[syncLogEntry valueForKey:@"op"] isEqualToString:@"deleted"]) {
            [remoteObj setObject:objType forKey:@"type"];
            [remoteObj setObject:[syncLogEntry valueForKey:@"cid"] forKey:@"url"];
            [remoteObj setObject:[syncLogEntry valueForKey:@"localId"] forKey:@"localId"];
            [remoteObj setObject:[syncLogEntry valueForKey:@"cver"] forKey:@"version"];
            [remoteObj setObject:@"true" forKey:@"deleted"];
            [syncLogEntry setValue:[NSNumber numberWithBool:YES] forKey:@"syncing"];
        }
        else {
            NSString* localIdString = [syncLogEntry valueForKey:@"localId"];
            NSManagedObject* localObj = [self findByUriString:localIdString];
            if (localObj) {
                [remoteObj setObject:localIdString forKey:@"localId"];
                [remoteObj setObject:objType forKey:@"type"];
                if ([localObj valueForKey:@"cid"]) {
                    [remoteObj setObject:[localObj valueForKey:@"cid"] forKey:@"url"];
                }
                else if (parentAttr) {
                    NSManagedObject* localParent = [localObj valueForKey:parentAttr];
                    [remoteObj setObject:[localParent valueForKey:@"cid"] forKey:@"url"];
                }
                [remoteObj setObject:[localObj valueForKey:@"cver"] forKey:@"version"];
                
                // call the logic to copy over entity specific attributes
                copier(objType, remoteObj, localObj);
                
                // set to syncing so the next time this method is called, this sync log entry will not be processed
                // note: the entry is only deleted once the server responds to tell us it successfully completed the sync
                [syncLogEntry setValue:[NSNumber numberWithBool:YES] forKey:@"syncing"];
            }
            else {
                // couldn't find the reference object, so delete this sync log entry
                // also, below we're going to let it return the empty remoteUse dictionary because returning nil could cause us to skip
                // any additional changes
                [self.managedObjectContext deleteObject:syncLogEntry];
            }
        }
        
        NSError *error = nil;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
        return remoteObj;
    }
    return nil;
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
