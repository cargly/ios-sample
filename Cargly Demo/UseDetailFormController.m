//
//  DetailViewController.m
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import "UseDetailFormController.h"
#import "EntityAttributeField.h"


@implementation UseDetailFormController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveObject:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    NSMutableArray* section = [self addFormSection];
    [self addCellToSection:section cellId:@"carCell" withAttr:@"vehicle" withVisibility:TRUE];
    NSMutableDictionary* cellInfo = [self addCellToSection:section cellId:@"carPickerCell" withAttr:@"vehicle" withVisibility:FALSE];
    
    [self addCellToSection:section cellId:@"startOdoCell" withAttr:@"odometer" withVisibility:TRUE];
    [self addCellToSection:section cellId:@"startDateCell" withAttr:@"occurred" withVisibility:TRUE];
    [self addCellToSection:section cellId:@"startDatePickerCell" withAttr:@"occurred" withVisibility:FALSE];


    section = [self addFormSection];
    [self addCellToSection:section cellId:@"purposeCell" withAttr:@"purpose" withVisibility:TRUE];
    [self addCellToSection:section cellId:@"destinationCell" withAttr:@"destination" withVisibility:TRUE];
    
    section = [self addFormSection];
    [self addCellToSection:section cellId:@"deleteCell" withAttr:nil withVisibility:TRUE];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)saveObject:(id)sender
{
    
    [self storeToEntityByCellId:@"carCell"];
    [self storeToEntityByCellId:@"startOdoCell"];
    [self storeToEntityByCellId:@"purposeCell"];
    [self storeToEntityByCellId:@"destinationCell"];
    [self.detailItem setValue:[NSDate date] forKey:@"occurred"];
    
    [self saveDetailItem];
}

-(void) saveDetailItem
{
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    else {
        [self.navigationController popViewControllerAnimated:TRUE];
    }
}

#pragma mark - Table view data source


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.reuseIdentifier isEqualToString:@"startDateCell"]) {
        [self.view endEditing:TRUE];
        [self initCellMutation];
        NSMutableDictionary* cellInfo = [self cellInfoForMutation:@"startDatePickerCell"];
        [self toggleCellVisiblity:cellInfo];
        [self performCellMutation];
        [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"carCell"]) {
        [self.view endEditing:TRUE];
        [self initCellMutation];
        NSMutableDictionary* cellInfo = [self cellInfoForMutation:@"carPickerCell"];
        [self toggleCellVisiblity:cellInfo];
        [self performCellMutation];
        [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
    }
    else if ([cell.reuseIdentifier isEqualToString:@"deleteCell"]) {
        [self.view endEditing:TRUE];
        [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
    }
}

-(void) fieldChanged:(EntityAttributeField*)field
{
    if ([field.attributeName isEqual:@"vehicle"]) {
        // move data from the picker to the label field
        NSMutableDictionary* carCellInfo = [self cellInfoForCellId:@"carCell"];
        NSMutableDictionary* carPickerCellInfo = [self cellInfoForCellId:@"carPickerCell"];
        EntityAttributeField* carField = [carCellInfo objectForKey:@"cell"];
        EntityAttributeField* carPickerField = [carPickerCellInfo objectForKey:@"cell"];
        carField.currentValue = carPickerField.currentValue;
        [carField loadFromEntity];
        [self reloadCellById:@"carCell"];
    }
}

-(void) fieldTouched:(EntityAttributeField*)field
{
    if ([field.reuseIdentifier isEqual:@"deleteCell"]) {
        [self.managedObjectContext deleteObject: self.detailItem];
        [self saveDetailItem];
    }
}

/*
 #pragma mark - Navigation
 
 // In a story board-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 
 */

@end
