//
//  EntityFormViewController.m
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import "EntityFormViewController.h"
#import "EntityFieldDelegate.h"
#import "EntityAttributeField.h"

@interface EntityFormViewController ()

@end

@implementation EntityFormViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(NSMutableArray*) addFormSection {
    if (!self.formSections) {
        self.formSections = [[NSMutableArray alloc] init];
    }
    NSMutableArray* section = [[NSMutableArray alloc] init];
    [self.formSections addObject:section];
    return section;
}

-(NSMutableDictionary*) addCellToSection:(NSMutableArray*)section cellId:(NSString*)cellId withAttr:(NSString*)attrName withVisibility:(BOOL)visible
{
    NSMutableDictionary* cellInfo = [[NSMutableDictionary alloc] init];
    [cellInfo setObject:cellId forKey:@"cellId"];
    if (attrName) {
        [cellInfo setObject:attrName forKey:@"attrName"];
    }
    [cellInfo setObject:[[NSNumber alloc] initWithBool:visible] forKey:@"visible"];
    [section addObject:cellInfo];
    return cellInfo;
}

-(NSInteger) visibleCellsInSection:(NSMutableArray*) section
{
    int ct = 0;
    NSMutableDictionary* cellInfo = nil;
    for (int i = 0; i < [section count]; i++) {
        cellInfo = [section objectAtIndex:i];
        if ([[cellInfo objectForKey:@"visible"] boolValue]) {
            ct++;
        }
    }
    return ct;
}

-(NSInteger) visibleSections
{
    int ct = 0;
    for (int i = 0; i < [self.formSections count];i++) {
        if ([self visibleCellsInSection:[self.formSections objectAtIndex:i]]) {
            ct++;
        }
    }
    return ct;
}

-(NSMutableDictionary*) visibleCellInfoAtIndex:(NSMutableArray*) section andIndex:(NSInteger)index
{
    int ct = 0;
    NSMutableDictionary* cellInfo = nil;
    for (int i = 0; i < [section count]; i++) {
        cellInfo = [section objectAtIndex:i];
        if ([[cellInfo objectForKey:@"visible"] boolValue]) {
            if (ct == index) {
                return cellInfo;
            }
            ct++;
        }
    }
    return nil;
}

-(NSMutableArray*) visibleSectionAtIndex:(NSInteger) index
{
    int ct = 0;
    for (int i = 0; i < [self.formSections count];i++) {
        if ([self visibleCellsInSection:[self.formSections objectAtIndex:i]]) {
            if (ct == index) {
                return [self.formSections objectAtIndex:i];
            }
            ct++;
        }
    }
    return nil;
}

-(NSMutableDictionary*) cellInfoForMutation:(NSString*) cellId
{
    int visibleSectionCt = 0;
    NSMutableDictionary* cellInfo = nil;
    for (int s = 0; s < [self.formSections count]; s++) {
        NSMutableArray* section  = [self.formSections objectAtIndex:s];
        int visibleCellCt = 0;
        for (int c = 0; c < [section count]; c++) {
            cellInfo = [section objectAtIndex:c];
            if ([[cellInfo objectForKey:@"visible"] boolValue]) {
                if ([[cellInfo objectForKey:@"cellId"] isEqual:cellId]) {
                    if (!visibleCellCt) {
                        [self.sectionIndexesToRemove addIndex:visibleSectionCt];
                    }
                    [self.cellIndexesToRemove addObject:[NSIndexPath indexPathForRow:visibleCellCt inSection:visibleSectionCt]];
                    return cellInfo;
                }
                visibleCellCt++;
            }
            else if ([[cellInfo objectForKey:@"cellId"] isEqual:cellId]) {
                if (!visibleCellCt) {
                    [self.sectionIndexesToAdd addIndex:visibleSectionCt];
                }
                [self.cellIndexesToAdd addObject:[NSIndexPath indexPathForRow:visibleCellCt inSection:visibleSectionCt]];
                return cellInfo;
            }
        }
        if (visibleCellCt) {
            visibleSectionCt++;
        }
    }
    return nil;
}


-(NSIndexPath*) indexPathForCellId:(NSString*) cellId
{
    int visibleSectionCt = 0;
    NSMutableDictionary* cellInfo = nil;
    for (int s = 0; s < [self.formSections count]; s++) {
        NSMutableArray* section  = [self.formSections objectAtIndex:s];
        int visibleCellCt = 0;
        for (int c = 0; c < [section count]; c++) {
            cellInfo = [section objectAtIndex:c];
            if ([[cellInfo objectForKey:@"visible"] boolValue]) {
                if ([[cellInfo objectForKey:@"cellId"] isEqual:cellId]) {
                    return [NSIndexPath indexPathForRow:visibleCellCt inSection:visibleSectionCt];
                }
                visibleCellCt++;
            }
            else if ([[cellInfo objectForKey:@"cellId"] isEqual:cellId]) {
                return [NSIndexPath indexPathForRow:visibleCellCt inSection:visibleSectionCt];
            }
        }
        if (visibleCellCt) {
            visibleSectionCt++;
        }
    }
    return nil;
}

-(void) reloadCellById:(NSString*) cellId {
    NSIndexPath* path = [self indexPathForCellId:cellId];
    NSArray* array = [NSArray arrayWithObject:path];
    UITableView* tableView = (UITableView*)self.view;
    [tableView reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationNone];
}

-(void) initCellMutation
{
    self.sectionIndexesToAdd = [[NSMutableIndexSet alloc] init];
    self.cellIndexesToAdd = [[NSMutableArray alloc] init];
    self.sectionIndexesToRemove = [[NSMutableIndexSet alloc] init];
    self.cellIndexesToRemove = [[NSMutableArray alloc] init];
}

-(void) performCellMutation
{
    [self.tableView beginUpdates];
    if (self.sectionIndexesToAdd) [self.tableView insertSections:self.sectionIndexesToAdd withRowAnimation:UITableViewRowAnimationFade];
    if (self.cellIndexesToAdd) [self.tableView insertRowsAtIndexPaths:self.cellIndexesToAdd withRowAnimation:UITableViewRowAnimationFade];
    if (self.sectionIndexesToRemove) [self.tableView deleteSections:self.sectionIndexesToRemove withRowAnimation:UITableViewRowAnimationFade];
    if (self.cellIndexesToRemove) [self.tableView deleteRowsAtIndexPaths:self.cellIndexesToRemove withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

-(NSMutableDictionary*) cellInfoForCellId:(NSString*) cellId
{
    NSMutableDictionary* cellInfo = nil;
    for (int s = 0; s < [self.formSections count]; s++) {
        NSMutableArray* section  = [self.formSections objectAtIndex:s];
        for (int c = 0; c < [section count]; c++) {
            cellInfo = [section objectAtIndex:c];
            if ([[cellInfo objectForKey:@"cellId"] isEqual:cellId]) {
                return cellInfo;
            }
        }
    }
    return nil;
}

-(void) storeToEntityByCellId:(NSString*)cellId
{
    NSMutableDictionary* cellInfo = [self cellInfoForCellId:cellId];
    EntityAttributeField* field = [cellInfo objectForKey:@"cell"];
    [field storeToEntity];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self visibleSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray* sectionItems = [self visibleSectionAtIndex:section];
    return [self visibleCellsInSection:sectionItems];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	return cell.frame.size.height;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* sectionCells = [self visibleSectionAtIndex:[indexPath indexAtPosition:0]];
    NSMutableDictionary* cellInfo = [self visibleCellInfoAtIndex:sectionCells andIndex:[indexPath indexAtPosition:1]];
    
    UITableViewCell* cell = [cellInfo objectForKey:@"cell"];
    if (!cell) {
        cell = [tableView dequeueReusableCellWithIdentifier: [cellInfo objectForKey:@"cellId"]];
    }
    
    
    if ([cell isKindOfClass:[EntityAttributeField class]]) {
        EntityAttributeField* boundField = (EntityAttributeField*)cell;
        [cellInfo setObject:boundField forKey:@"cell"];
        boundField.delegate = self;
        boundField.managedObjectContext = self.managedObjectContext;
        NSString* attrName = [cellInfo objectForKey:@"attrName"];
        if (attrName) {
            [boundField bindAttribute:self.detailItem attributeName:attrName];
        }
    }
    
    return cell;
}


-(void) toggleCellVisiblity:(NSMutableDictionary*) cellInfo
{
    if ([[cellInfo objectForKey:@"visible"] boolValue]) {
        [cellInfo setObject:[[NSNumber alloc] initWithBool:FALSE] forKey:@"visible"];
    }
    else {
        [cellInfo setObject:[[NSNumber alloc] initWithBool:TRUE] forKey:@"visible"];
    }
}

@end
