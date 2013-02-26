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
@synthesize xmppName;
@synthesize roomRating;
@synthesize distanceFromUser;
@synthesize roomUsers;
@synthesize messagesHistory;

-(void)dealloc{
    [roomUsers release];
    [roomID release];
    [xmppName release];
    [createdAt release];
    [super dealloc];
}

@end
