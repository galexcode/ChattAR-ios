//
//  ChatRoom.m
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import "ChatRoom.h"

@implementation ChatRoom
@synthesize createdAt;
@synthesize ownerLocation;
@synthesize roomID;
@synthesize roomName;
@synthesize roomRating;
@synthesize distanceFromUser;
@synthesize roomUsers;
@synthesize messagesHistory;
@synthesize usersPictures;
@synthesize messagesAsUserAnnotationForDisplaying;
@synthesize isSendingMessage;

-(void)dealloc{
    [roomUsers release];
    [messagesHistory release];
    [usersPictures release];
    [roomID release];
    [roomName release];
    [createdAt release];
    [super dealloc];
}

-(NSString*)description{
    return [NSString stringWithFormat:@"room name - %@ \n room rating - %f \n number of room users - %d \n room messages - %@\n room location - %f %f",roomName,roomRating,roomUsers.count,messagesHistory, ownerLocation.latitude,ownerLocation.longitude];
}
+(ChatRoom*)createRoomWithAdditionalInfoWithName:(NSString*)_roomName coordinates:(CLLocationCoordinate2D)coordinates{
    ChatRoom* room = [[[ChatRoom alloc] init] autorelease];
    [room setOwnerLocation:coordinates];
    [room setCreatedAt:[NSDate date]];
    [room setRoomName:_roomName];
    [room setIsSendingMessage:NO];
    
    if (!room.messagesHistory) {
        room.messagesHistory = [[NSMutableArray alloc] init];
    }
    
    if (!room.messagesAsUserAnnotationForDisplaying) {
        room.messagesAsUserAnnotationForDisplaying = [[NSMutableArray alloc] init];
    }
    return room;
}
@end
