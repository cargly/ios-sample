//
//  AppDelegate.h
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CarglySyncDelegate.h"
#import "ActivityMasterViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, CarglySyncDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ActivityMasterViewController *controller;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
