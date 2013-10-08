//
//  MasterViewController.h
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

@interface ActivityMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) IBOutlet UIBarButtonItem* activityBarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* activityBarLabelItem;

@property (strong, nonatomic) UIActivityIndicatorView* activityView;
@property (strong, nonatomic) UILabel* activityLabel;

-(void)setSyncActivity:(BOOL)active;
-(void)setSyncError:(NSString*)error;

@end
