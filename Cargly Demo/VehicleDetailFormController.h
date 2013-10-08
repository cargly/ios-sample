//
//  VehicleDetailFormController.h
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntityAttributeField.h"

@interface VehicleDetailFormController : UITableViewController
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) id detailItem;
@property(nonatomic, strong) EntityAttributeField* carNameCell;
@property(nonatomic, strong) EntityAttributeField* postalCodeCell;
@end
