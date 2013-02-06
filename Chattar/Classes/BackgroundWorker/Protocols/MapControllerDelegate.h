//
//  MapControllerDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>

@protocol MapControllerDelegate <NSObject>

@optional
-(void) didReceiveCachedMapPoints:(NSArray*)cachedMapPoints;
-(void) didReceiveCachedMapPointsIDs:(NSArray*)cachedMapIDs;
-(void) willAddNewPoint:(UserAnnotation*)point isFBCheckin:(BOOL)isFBCheckin;
-(void) willAddFBCheckin:(UserAnnotation*)checkin;
-(void) willShowMap;
-(void) willUpdatePointStatus:(UserAnnotation*)newPoint;
@end

