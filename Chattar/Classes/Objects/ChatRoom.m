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

-(void)dealloc{
    [roomUsers release];
    [messagesHistory release];
    [usersPictures release];
    [roomID release];
    [roomName release];
    [createdAt release];
    [super dealloc];
}

@end
