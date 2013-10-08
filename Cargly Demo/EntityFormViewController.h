//
//  EntityFormViewController.h
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EntityFieldDelegate.h"

// Base class to make adding and removing form cells easier.
@interface EntityFormViewController : UITableViewController<EntityFieldDelegate>

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) NSMutableArray* cellIndexesToAdd;
@property (strong, nonatomic) NSMutableIndexSet* sectionIndexesToAdd;
@property (strong, nonatomic) NSMutableArray* cellIndexesToRemove;
@property (strong, nonatomic) NSMutableIndexSet* sectionIndexesToRemove;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property(nonatomic, strong) NSMutableArray* formSections;


-(NSMutableArray*) addFormSection;

-(NSMutableDictionary*) addCellToSection:(NSMutableArray*)section cellId:(NSString*)cellId withAttr:(NSString*)attrName withVisibility:(BOOL)visible;

-(NSInteger) visibleCellsInSection:(NSMutableArray*) section;

-(NSInteger) visibleSections;

-(NSMutableDictionary*) visibleCellInfoAtIndex:(NSMutableArray*) section andIndex:(NSInteger)index;

-(NSMutableArray*) visibleSectionAtIndex:(NSInteger) index;

-(NSMutableDictionary*) cellInfoForMutation:(NSString*) cellId;

-(NSIndexPath*) indexPathForCellId:(NSString*) cellId;

-(void) reloadCellById:(NSString*) cellId;

-(void) initCellMutation;

-(void) performCellMutation;

-(NSMutableDictionary*) cellInfoForCellId:(NSString*) cellId;

-(void) storeToEntityByCellId:(NSString*)cellId;

-(void) toggleCellVisiblity:(NSMutableDictionary*) cellInfo;

@end
