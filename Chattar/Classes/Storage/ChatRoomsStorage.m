//
//  ChatRoomsStorage.m
//  Chattar
//
//  Created by kirill on 2/26/13.
//
//

#import "ChatRoomsStorage.h"

@implementation ChatRoomsStorage
@synthesize messageToSend;

-(void)dealloc{
    [messageToSend release];
    [super dealloc];
}

-(id)init{
    if (self = [super init]) {
        self.needsCaching = NO;
    }
    return self;
}


-(BOOL)isStorageEmpty{
    return ([DataManager shared].currentChatRoom.messagesHistory == nil);
}
-(void)showWorldDataFromStorage{
    if (![DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying) {
        [DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying = [[NSMutableArray alloc] init];
    }

    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying addObjectsFromArray:[DataManager shared].currentChatRoom.messagesHistory];
}


-(void)showFriendsDataFromStorage{
    NSMutableArray *friendsIds = [[[DataManager shared].myFriendsAsDictionary allKeys] mutableCopy];
    [friendsIds addObject:[DataManager shared].currentFBUserId];// add me
    
    if (![DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying) {
        [DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying = [[NSMutableArray alloc] init];
    }
    
    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
    
    for (QBChatMessage*message in [DataManager shared].currentChatRoom.messagesHistory) {
        NSNumber* senderID = @(message.senderID);
        if ([friendsIds containsObject:senderID]) {
            UserAnnotation* messageAnnotation = [[DataManager shared] convertQBMessageToUserAnnotation:message];
            [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying addObject:messageAnnotation];
        }
    }

    [friendsIds release];
}

-(void)refreshDataFromStorage{
                                        // sort QB messages by date of creation
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"datetime" ascending: NO] autorelease];
	NSArray* sortedArray = [[DataManager shared].currentChatRoom.messagesHistory sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
	[[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
                    // create new sorted and array for displaying
    for (QBChatMessage* message in sortedArray) {
        UserAnnotation* messageAnnotation = [[DataManager shared] convertQBMessageToUserAnnotation:message];
        if (![[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying containsObject:messageAnnotation]) {
            [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying addObject:messageAnnotation];
        }
    }
}

-(void)addDataToStorage:(UserAnnotation*)newData{
    if (![[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying containsObject:newData]) {
        [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying addObject:newData];
    }
}
-(void)removeLastObjectFromStorage{
    if ([DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying.count) {
        [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeLastObject];
    }
}
-(void)clearStorage{
    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
    [[DataManager shared].currentChatRoom.messagesHistory removeAllObjects];
}
-(BOOL)storageContainsObject:(UserAnnotation*)object{
    if ([[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying containsObject:object]) {
        return YES;
    }
    return NO;
}
-(UserAnnotation*)retrieveDataFromStorageWithIndex:(NSInteger)index{
    if (index >= 0 && index < [DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying.count) {
       return [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying objectAtIndex:index];
    }
    return nil;
}

-(NSInteger)storageCount{
    return [DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying.count;
}

-(NSInteger)allDataCount{
    return [DataManager shared].currentChatRoom.messagesHistory.count;
}

-(void)insertObjectToAllData:(UserAnnotation*)object atIndex:(NSInteger)index{
        
    if (((index >= 0 && index < [DataManager shared].currentChatRoom.messagesHistory.count) || !index)) {
        QBChatMessage* message = [[DataManager shared] convertUserAnnotationToQBChatMessage:object];
        
        if (![[DataManager shared].currentChatRoom.messagesHistory containsObject:message]) {
            [[DataManager shared].currentChatRoom.messagesHistory addObject:message];
        }
    }
}

-(void)insertObjectToPartialData:(UserAnnotation*)object atIndex:(NSInteger)index{
    
    if (![DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying) {
        [DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying = [[NSMutableArray alloc] init];
    }
    
    if (((index >= 0 && index < [DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying.count) || !index)) {
        if (![[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying containsObject:object]) {
            [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying insertObject:object atIndex:index];
        }
    }
}

-(void)removeAllPartialData{
    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
}

-(void)createDataInStorage:(NSDictionary *)data{
    NSString* messageText = [data objectForKey:@"messageText"];
//    NSString* quoteMark = [data objectForKey:@"quoteMark"];
    messageToSend = [[QBChatMessage alloc] init];
    [messageToSend setText:messageText];
}

@end
