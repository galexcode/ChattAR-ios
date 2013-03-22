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
@synthesize onlineRoomUsers;
@synthesize messagesHistory;
@synthesize messagesAsUserAnnotationForDisplaying;
@synthesize isSendingMessage;
@synthesize allRoomUsers;
@synthesize fbRoomUsers;

- (void)dealloc{
    [onlineRoomUsers release];
    [messagesHistory release];
    [roomID release];
    [roomName release];
    [createdAt release];
    [allRoomUsers release];
    [fbRoomUsers release];
    
    [super dealloc];
}

- (NSString*)description{
    return [NSString stringWithFormat:@"room name - %@ \n room rating - %f \n number of room users - %d \n room messages - %@\n room location - %f %f",roomName,roomRating,onlineRoomUsers.count,messagesHistory, ownerLocation.latitude,ownerLocation.longitude];
}
+ (ChatRoom*)createRoomWithAdditionalInfoWithName:(NSString*)_roomName coordinates:(CLLocationCoordinate2D)coordinates{
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
