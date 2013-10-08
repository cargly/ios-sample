//
//  CarglySyncDelegate.h
//  CarglyCore
//
//  Copyright (c) 2013 Granite Dome LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CarglySyncDelegate <NSObject>

// Called the very first time a client is synchronized with the Cargly Service. This allows the client to make whatever
// preparations are necessary before the first sync. For example, in the Demo App all sync-able object have to be iterated and
// for each one a SyncEntry object must be created. In the Demo App, SyncEntry objects are used to track all changes that are
// waiting to be synchronized.
-(void) carglyInitialize;

// Called at the start of each synchronization session. A session might included multiple requests to the Cargly Service. This
// method is a good place to put any logic to clean up any previous failed sync attempts. Also, the client can use this callback
// to kick off an activity indicator.
-(void) carglySyncStart;

// Called at the end of each synchronization session. This callback is useful to stop any activity indicators.
-(void) carglySyncComplete;

// Callback for any errors that occur. The client should uset this callback to stop any activity indicators and to notify the user
// that something went wrong.
-(void) carglyError;

// Callback to notify the client app that reachability has changed. While the network is unreachable, attempting to sync will result
// in a no-op.
-(void)reachabilityDidChange:(BOOL)isReachable;

// This method is called by CarglyCore and is passed a dictionary containing the keys & values for an object that was
// updated or created on the server. The app should store these values in its database. Each dictionary has a 'type' value that
// can be used when deciding when type of object is being updated or created.
-(void) carglyUpdateObject:(NSDictionary*)user;

// This method is called by CarglyCore in order to collect new parent objects that need to be synchronized to
// the Cargly Web Service. This method must return a dictionary in the format required by cargly for an object that
// was created locally and hasn't been synchronized to the cargly service yet. If there are no new parent objects that
// need to be synced, this method should return nil. The typical use case for this method is to sync new vehicles that
// need to be creted on the server. Since other object such as refuelings depend on vehicles existing, CarlyCore will
// sync any objects returned by this method first, and then move on to requesting updated objects by calling
// carglyGetUpdatedObject once this method returns nil.
-(NSDictionary*) carglyGetNewParentObject;

// This method is called by CarglyCore in order to collect the updated objects that need to be synchronized to the
// Cargly Web Service. This method must return a dictionary in the format required by cargly for an object that
// was updated locally and hasn't been synchronized to the cargly service yet. If there are no objects that need to be
// synchronzied because no changes have been made, then it should return nil. This method can return dictionaries for both
// objects that were created or updated as long as any created objects aren't parents or other objects.
-(NSDictionary*) carglyGetUpdatedObject;

// This method is called by Cargly Core once for each object that was synchronized up to the service. The result dictionary contains
// a "status" key that contains "success" or "error". If an error is returned for an object, the client must ensure that
// the object in question is still a candidate for synchronizing the next time a sync is attempted.
-(void) carglySyncStatus:(NSDictionary*)result;

@end
