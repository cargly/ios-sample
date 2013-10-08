//
//  EntityFieldDelegate.h
//  Cargly Demo
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EntityAttributeField;

@protocol EntityFieldDelegate <NSObject>
@optional
-(void) fieldChanged:(EntityAttributeField*)field;
-(void) fieldTouched:(EntityAttributeField*)field;
@end
