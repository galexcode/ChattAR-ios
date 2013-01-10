//
//  UserAnnotation.m
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 3/28/12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import "UserAnnotation.h"
#import "Macro.h"

@implementation UserAnnotation
@synthesize userPhotoUrl, userName, userStatus, coordinate, fbUserId, geoDataID, createdAt, fbUser, quotedUserName, quotedMessageDate, quotedMessageText, quotedUserPhotoURL, distance, quotedUserFBId, quotedUserQBId, qbUserID, fbCheckinID, fbPlaceID;

@synthesize fullImageURL,locationId,locationName,thumbnailURL,photoTimeStamp,photoId,ownerId;
@synthesize locationLatitude = _locationLatitude;
@synthesize locationLongitude = _locationLongitude;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if (self = [super init])
	{
        DESERIALIZE_OBJECT(userPhotoUrl, aDecoder);
        DESERIALIZE_OBJECT(userName, aDecoder);
        DESERIALIZE_OBJECT(userStatus, aDecoder);
        DESERIALIZE_DOUBLE(coordinate.latitude, aDecoder);
        DESERIALIZE_DOUBLE(coordinate.longitude, aDecoder);
        DESERIALIZE_OBJECT(createdAt, aDecoder);
        
        DESERIALIZE_OBJECT(fbUser, aDecoder);
        DESERIALIZE_OBJECT(fbUserId, aDecoder);
        DESERIALIZE_INT(geoDataID, aDecoder);
        DESERIALIZE_OBJECT(fbCheckinID, aDecoder);
        DESERIALIZE_OBJECT(fbPlaceID, aDecoder);
        DESERIALIZE_INT(qbUserID, aDecoder);
        
        DESERIALIZE_INT(distance, aDecoder);
        
        DESERIALIZE_OBJECT(quotedUserFBId, aDecoder);
        DESERIALIZE_OBJECT(quotedUserQBId, aDecoder);
        DESERIALIZE_OBJECT(quotedUserPhotoURL, aDecoder);
        DESERIALIZE_OBJECT(quotedUserName, aDecoder);
        DESERIALIZE_OBJECT(quotedMessageDate, aDecoder);
        DESERIALIZE_OBJECT(quotedMessageText, aDecoder);
        
        DESERIALIZE_OBJECT(locationLatitude, aDecoder);
        DESERIALIZE_OBJECT(locationLongitude, aDecoder);
        DESERIALIZE_OBJECT(fullImageURL, aDecoder);
        DESERIALIZE_OBJECT(thumbnailURL, aDecoder);
        DESERIALIZE_OBJECT(locationName, aDecoder);
        DESERIALIZE_OBJECT(locationId, aDecoder);
        DESERIALIZE_OBJECT(photoId, aDecoder);
        DESERIALIZE_OBJECT(photoTimeStamp, aDecoder);
        DESERIALIZE_OBJECT(ownerId, aDecoder);
	}
	
	return self;
}
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    SERIALIZE_OBJECT(userPhotoUrl, aCoder);
    SERIALIZE_OBJECT(userName, aCoder);
    SERIALIZE_OBJECT(userStatus, aCoder);
    SERIALIZE_DOUBLE(coordinate.latitude, aCoder);
    SERIALIZE_DOUBLE(coordinate.longitude, aCoder);
    SERIALIZE_OBJECT(createdAt, aCoder);
    
    SERIALIZE_OBJECT(fbUser, aCoder);
    SERIALIZE_OBJECT(fbUserId, aCoder);
    SERIALIZE_INT(geoDataID, aCoder);
    SERIALIZE_OBJECT(fbCheckinID, aCoder);
    SERIALIZE_OBJECT(fbPlaceID, aCoder);
    SERIALIZE_INT(qbUserID, aCoder);
    
    SERIALIZE_INT(distance, aCoder);
    
    SERIALIZE_OBJECT(quotedUserFBId, aCoder);
    SERIALIZE_OBJECT(quotedUserQBId, aCoder);
    SERIALIZE_OBJECT(quotedUserPhotoURL, aCoder);
    SERIALIZE_OBJECT(quotedUserName, aCoder);
    SERIALIZE_OBJECT(quotedMessageDate, aCoder);
    SERIALIZE_OBJECT(quotedMessageText, aCoder);
    
    SERIALIZE_OBJECT(locationLatitude, aCoder);
    SERIALIZE_OBJECT(locationLongitude, aCoder);
    SERIALIZE_OBJECT(fullImageURL, aCoder);
    SERIALIZE_OBJECT(thumbnailURL, aCoder);
    SERIALIZE_OBJECT(locationName, aCoder);
    SERIALIZE_OBJECT(locationId, aCoder);
    SERIALIZE_OBJECT(photoTimeStamp, aCoder);
    SERIALIZE_OBJECT(photoId, aCoder);
    SERIALIZE_OBJECT(ownerId, aCoder);
}

- (void)dealloc
{
	[quotedMessageDate release];
	[quotedMessageText release];
	[quotedUserName release];
	[quotedUserPhotoURL release];
	[quotedUserFBId release];
    [quotedUserQBId release];
    
    [userPhotoUrl release];
    [userName release];
    [userStatus release];
    [createdAt release];
    [fbUserId release];
    [fbUser release];
    [fbCheckinID release];
    [fbPlaceID release];
    
    [fullImageURL release];
    [locationName release];
    [thumbnailURL release];
    [locationId release];
    [photoId release];
    [photoTimeStamp release];
    [ownerId release];
    
    [super dealloc];
}

- (NSString *)description{
    
    NSString *desc = [NSString stringWithFormat:
                      @"%@\
                      \n\tuserName:%@\
                      \n\tuserStatus:%@\
                      \n\tqbUserID:%u\
                      \n\tfbUser:%@\
                      \n\tgeoDataID:%d\
                      \n\tfbCheckinID:%@\
                      \n\tfbPlaceID:%@\
                      \n\tcreatedAt:%@",
                      
                      [super description],
                      userName,
                      userStatus,
                      qbUserID,
                      fbUser,
                      geoDataID,
                      fbCheckinID,
                      fbPlaceID,
                      createdAt];
    
    return desc;
}

#pragma mark -
#pragma mark NSCopying

-(id)copyWithZone:(NSZone *)zone
{
    UserAnnotation *copy = [[[self class] allocWithZone:zone] init];
    
    copy.userPhotoUrl       = [[self.userPhotoUrl copyWithZone:zone] autorelease];
    copy.userName           = [[self.userName copyWithZone:zone] autorelease];
    copy.userStatus         = [[self.userStatus copyWithZone:zone] autorelease];
    copy.coordinate         = self.coordinate;
    copy.createdAt          = [[self.createdAt copyWithZone:zone] autorelease];
    
    copy.fbUser             = [[self.fbUser copyWithZone:zone] autorelease];
    copy.fbUserId           = [[self.fbUserId copyWithZone:zone] autorelease];
    copy.geoDataID          = self.geoDataID;
    copy.fbCheckinID        = [[self.fbCheckinID copyWithZone:zone] autorelease];
    copy.fbPlaceID          = [[self.fbPlaceID copyWithZone:zone] autorelease];
    copy.qbUserID           = self.qbUserID;
    
    copy.distance           = self.distance;
    
    copy.quotedUserFBId     = [[self.quotedUserFBId copyWithZone:zone] autorelease];
    copy.quotedUserPhotoURL = [[self.quotedUserPhotoURL copyWithZone:zone] autorelease];
    copy.quotedUserName     = [[self.quotedUserName copyWithZone:zone] autorelease];
    copy.quotedMessageDate  = [[self.quotedMessageDate copyWithZone:zone] autorelease];
    copy.quotedMessageText  = [[self.quotedMessageText copyWithZone:zone] autorelease];
    
    copy.locationId = [[self.locationId copyWithZone:zone] autorelease];
    copy.fullImageURL = [[self.fullImageURL copyWithZone:zone] autorelease];
    copy.thumbnailURL = [[self.thumbnailURL copyWithZone:zone] autorelease];
    copy.locationName = [[self.locationName copyWithZone:zone] autorelease];
    copy.locationLatitude = [[self.locationLatitude copyWithZone:zone] autorelease];
    copy.locationLongitude = [[self.locationLongitude copyWithZone:zone] autorelease];
    copy.photoId = [[self.photoId copyWithZone:zone] autorelease];
    copy.photoTimeStamp = [[self.photoTimeStamp copyWithZone:zone] autorelease];
    copy.ownerId = [[self.ownerId copyWithZone:zone] autorelease];
    
    return copy;
}

@end
