//
//  MasterViewController.m
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ActivityMasterViewController.h"
#import "UseDetailFormController.h"
#import "VehicleMasterViewController.h"
#import "SettingsFormController.h"
#import "CarglyCore.h"
//#import "DetailViewController.h"

@interface ActivityMasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ActivityMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;

    
    [self.navigationController setToolbarHidden:NO];
    
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [self.activityView stopAnimating];
    [self.activityBarItem setCustomView:self.activityView];
    
    self.activityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
    [self.activityLabel setFont:[UIFont systemFontOfSize:11]];
    self.activityLabel.text = @"";
    [self.activityLabel setTextColor:[UIColor grayColor]];
    [self.activityBarLabelItem setCustomView:self.activityLabel];
    
    
//    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(insertNewObject:)];
//    
//    [self setToolbarItems:[NSArray arrayWithObjects:actionButton, nil]];

}

-(void)setSyncActivity:(BOOL)active
{
    if (active) {
        [self.activityView startAnimating];
        self.activityLabel.text = @"Updating...";
    }
    else {
        [self.activityView stopAnimating];
        self.activityLabel.text = @"";
    }
}

-(void)setSyncError:(NSString*)error
{
    [self.activityView stopAnimating];
    self.activityLabel.text = error;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"created"];
    [newManagedObject setValue:[NSDate date] forKey:@"occurred"];
    [newManagedObject setValue:@"use" forKey:@"type"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (IBAction)showActionSheet:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Manage Cars", @"Sync With Cargly", @"Settings", nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    [actionSheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
/*     NSURL *url = [NSURL URLWithString:@"https://carglyplatform.appspot.com/oauth?response_type=token&client_id=1fFLMv9rjD6oEnBpLRasgEU4IcCdSzOC&redirect_uri=cargly9999%3A%2F%2F%2F"];
  */
     switch (buttonIndex) {
     case 0:
             [self performSegueWithIdentifier:@"showCars" sender:self];
     break;
     case 1:
             [CarglyCore syncNow];
//             if (![[UIApplication sharedApplication] openURL:url]) {
//                 NSLog(@"%@%@",@"Failed to open url:",[url description]);
//             }
     break;
     case 2:
             [self performSegueWithIdentifier:@"showSettings" sender:self];
     break;
     case 3:

     break;
     }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([[object valueForKey:@"type"] isEqualToString:@"refueling"]) {
        [self performSegueWithIdentifier:@"showDescription" sender:self];
    }
    else if ([[object valueForKey:@"type"] isEqualToString:@"expense"]) {
        [self performSegueWithIdentifier:@"showDescription" sender:self];
    }
    else if ([[object valueForKey:@"type"] isEqualToString:@"use"]) {
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        UseDetailFormController *controller = (UseDetailFormController*)[segue destinationViewController];
        controller.managedObjectContext = self.managedObjectContext;
        [controller setDetailItem:object];
//        [[segue destinationViewController] setDetailItem:object];
    }
    else if ([[segue identifier] isEqualToString:@"showCars"]) {
        UINavigationController *navigationController = (UINavigationController *)[segue destinationViewController];
        VehicleMasterViewController *controller = (VehicleMasterViewController *)navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
//        [[segue destinationViewController] setManagedObjectContext:self.managedObjectContext];
    }
    else if ([[segue identifier] isEqualToString:@"showDescription"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        UIViewController *controller = (UIViewController *)[segue destinationViewController];
        UITextView* v = [[controller.view subviews] objectAtIndex:0];
        v.text = [object description];
    }
    else if ([[segue identifier] isEqualToString:@"showSettings"]) {
        UINavigationController *navigationController = (UINavigationController *)[segue destinationViewController];
        SettingsFormController *controller = (SettingsFormController *)navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Activity" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"occurred" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

+(NSDateFormatter*) dateFormatter {
	static NSDateFormatter* formatter = nil;
	if (!formatter) {
		formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy-MM-dd"];
	}
	
	return formatter;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString* caption = [[NSString alloc] initWithFormat:@"%@ - %@ - %@",
                         [object valueForKey:@"type"],
                         [[object valueForKey:@"vehicle"] valueForKey:@"name"],
                         [[ActivityMasterViewController dateFormatter] stringFromDate:[object valueForKey:@"occurred"]]
                        ];
    cell.textLabel.text = caption;
}

@end
