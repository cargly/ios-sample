//
//  VehicleMasterViewController.h
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VehicleMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
