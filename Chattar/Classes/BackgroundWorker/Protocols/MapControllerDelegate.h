//
//  MapControllerDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import "MapViewController.h"
#import "UserAnnotation.h"
@protocol MapControllerDelegate <NSObject>

@optional
-(void) didReceiveCachedMapPoints:(NSArray*)cachedMapPoints;
-(void) didReceiveCachedMapPointsIDs:(NSArray*)cachedMapIDs;
-(void) willAddNewPoint:(UserAnnotation*)point isFBCheckin:(BOOL)isFBCheckin;
-(void) willUpdatePointStatus:(UserAnnotation*)newPoint;
@end

