//
//  EntityAttributeField.h
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EntityAttributeField : UITableViewCell<UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) id delegate;
@property (nonatomic, strong) IBOutlet UIView* attributeView;
@property (nonatomic, strong) NSString* attributeName;
@property (nonatomic, strong) NSManagedObject* entity;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSArray* choices;
@property (nonatomic, strong) id currentValue;

-(void)bindAttribute:(NSManagedObject*) entity attributeName:(NSString*)attributeName;
-(void)storeToEntity;
-(void)loadFromEntity;

-(IBAction) valueChanged:(id) sender;
-(IBAction) cellTouched:(id) sender;
@end
