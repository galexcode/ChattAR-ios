//
//  PhotoWithLocationModel.h
//  Chattar
//
//  Created by kirill on 1/8/13.
//
//

#import <CoreData/CoreData.h>

@interface PhotoWithLocationModel : NSManagedObject
@property (nonatomic, retain) NSDecimalNumber* locationId;
@property (nonatomic, retain) NSString* fullImageURL;
@property (nonatomic, retain) NSString* thumbnailURL;
@property (nonatomic, retain) NSDecimalNumber* locationLatitude;
@property (nonatomic, retain) NSDecimalNumber* locationLongitude;
@property (nonatomic, retain) NSString* locationName;
@property (nonatomic, retain) NSDecimalNumber* photoTimeStamp;
@property (nonatomic, retain) NSString* photoId;
@property (nonatomic, retain) NSDecimalNumber* ownerId;
@end
