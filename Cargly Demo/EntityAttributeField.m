//
//  EntityAttributeField.m
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import "EntityAttributeField.h"
#import "EntityFieldDelegate.h"

@implementation EntityAttributeField

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if(self = [super initWithCoder:aDecoder]) {

 
    }
    
    return self;
}

-(void)bindAttribute:(NSManagedObject*) entity attributeName:(NSString*)attributeName
{
    self.entity = entity;
    self.attributeName = attributeName;
    [self loadFromEntity];
}

-(void)loadFromEntity
{
    if (self.attributeView && self.entity && self.attributeName) {
        
        if (!self.currentValue) {
            self.currentValue = [self.entity valueForKey:self.attributeName];
        }
        
        // now push the value into the control
        if ([self.attributeView isKindOfClass:[UITextField class]]) {
            UITextView* textView = (UITextView*)self.attributeView;
            if ([self.currentValue isKindOfClass:[NSString class]]) {
                textView.text = self.currentValue;
            }
            else {
                textView.text = [self.currentValue stringValue];
            }
        }
        else if ([self.attributeView isKindOfClass:[UILabel class]]) {
            UILabel* label = (UILabel*)self.attributeView;
            if (!self.currentValue) {
                label.text = @"Touch to select";
            }
            else if ([self.currentValue isKindOfClass: [NSManagedObject class]]) {
                NSString* temp = [self.currentValue valueForKey:@"name"];
                label.text = temp;
            }
            else {
                label.text = self.currentValue ? self.currentValue : @"No Value";
            }
            
        }
        else if ([self.attributeView isKindOfClass:[UIPickerView class]]) {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            // Edit the entity name as appropriate.
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Vehicle" inManagedObjectContext:self.managedObjectContext];
            [fetchRequest setEntity:entity];
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
            NSArray *sortDescriptors = @[sortDescriptor];
            
            [fetchRequest setSortDescriptors:sortDescriptors];
            NSError *error;
            self.choices = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (self.currentValue) {
                NSInteger index = [self.choices indexOfObject:self.currentValue];
                UIPickerView* pickerView = (UIPickerView*)self.attributeView;
                [pickerView selectRow:index inComponent:0 animated:TRUE];
            }
        }
    }
}


-(void)storeToEntity
{
    if (self.attributeView && self.entity && self.attributeName) {
        // get type info for the attribute
        NSDictionary *attributes = [[self.entity entity] attributesByName];
        NSDictionary *relationships = [[self.entity entity] relationshipsByName];
        NSAttributeDescription *attr = [attributes objectForKey:self.attributeName];
        NSRelationshipDescription* relation = [relationships objectForKey:self.attributeName];
        
        if ([self.attributeView isKindOfClass:[UITextField class]]) {
            UITextView* textView = (UITextView*)self.attributeView;
            self.currentValue = textView.text;
            
            if (attr) {
                if ([attr attributeType] == NSStringAttributeType) {
                    [self.entity setValue:self.currentValue forKey:self.attributeName];
                }
                else if ([attr attributeType] == NSDecimalAttributeType) {
                    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
                    [f setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSNumber *num = [f numberFromString:self.currentValue];
                    [self.entity setValue:num forKey:self.attributeName];
                }
            }
        }
        else if ([self.attributeView isKindOfClass:[UILabel class]]) {
            if (relation) {
                [self.entity setValue:self.currentValue forKey:self.attributeName];
            }
        }
    }
}

-(IBAction) valueChanged:(id) sender
{
    [self.delegate fieldChanged:self];
}

-(IBAction) cellTouched:(id) sender
{
    [self.delegate fieldTouched:self];
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.choices count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self.choices objectAtIndex:row] valueForKey:@"name"];
//    return @"testing";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.currentValue = [self.choices objectAtIndex:row];
//    [self.entity setValue:[self.choices objectAtIndex:row] forKey:self.attributeName];
    [self.delegate fieldChanged:self];
}

@end
