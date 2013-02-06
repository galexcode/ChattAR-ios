//
//  FBDataDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>

@protocol FBDataDelegate <NSObject>
@optional
-(void)didReceiveFBCheckins:(NSArray*)fbCheckins;
-(void)didReceiveNewPhotosWithlocations:(NSArray*)photosWithLocations;
-(void)didReceiveCachedPhotosWithLocations:(NSArray*)photosWithLocations;

@end
