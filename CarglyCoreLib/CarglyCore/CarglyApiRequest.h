//
//  CarglyApiRquest.h
//  TestCarglyWebAuth
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface CarglyApiRequest : NSObject {
	
	id requestDelegate;
	id apiDelegate;
	
	NSMutableData* jsonData;
	NSURLConnection* connection;
	
}

@property (nonatomic) SEL callbackSelector;
@property (nonatomic, strong) id responseData;


-(void) httpGet:(NSString*)path
     withParams:(NSDictionary*)params
      withToken:(NSString*)token
   withDelegate:(id)delegate
   withSelector:(SEL)selector;

-(void) httpPostParams:(NSString*)path
            withParams:(NSDictionary*)params
             withToken:(NSString*)token
          withDelegate:(id)delegate
          withSelector:(SEL)selector;

-(void) httpPostJson:(NSString*)path
            withJson:(id)objects
           withToken:(NSString*)token
        withDelegate:(id)delegate
        withSelector:(SEL)selector;

-(void) doLocationRequest:(id)delegate withLat:(double)lat withLon:(double)lon;
-(void) doTaxDeductionRequest:(id)delegate;

+(NSString *) urlEncodeValue:(NSString *)str;
+(NSString *) md5:(NSString *)str;
+(NSString*) carglyBaseUrl;
+(NSString*) makeFullUrlString:(NSString*)pathQueryFragment;
+(NSURL*) makeFullUrl:(NSString*)pathQueryFragment;

@end
