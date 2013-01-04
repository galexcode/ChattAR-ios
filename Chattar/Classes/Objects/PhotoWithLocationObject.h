//
//  PhotoWithLocationObject.h
//  Chattar
//
//  Created by kirill on 12/28/12.
//
//

#import <Foundation/Foundation.h>
#import "AsyncImageView.h"
@interface PhotoWithLocationObject : NSObject
@property(nonatomic,retain) NSDecimalNumber* locationID;
@property(assign) CLLocationCoordinate2D photoLocation;
@property(nonatomic,retain) AsyncImageView* photoThumbNail;
@property(nonatomic,retain) AsyncImageView* fullPhoto;
@property(nonatomic,retain) NSString* locationName;
@end
