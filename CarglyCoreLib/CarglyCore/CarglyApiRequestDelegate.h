//
//  CarglyApiRequestDelegate.h
//  TestCarglyWebAuth
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarglyApiRequest;

@protocol CarglyApiRequestDelegate
@optional
-(void) carglyRequestFailure:(NSError*)error forRequest:(CarglyApiRequest*) request;

@end
