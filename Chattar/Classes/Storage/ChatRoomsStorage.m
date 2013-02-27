//
//  ChatRoomsStorage.m
//  Chattar
//
//  Created by kirill on 2/26/13.
//
//

#import "ChatRoomsStorage.h"

@implementation ChatRoomsStorage

-(BOOL)isStorageEmpty{
    return ([DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying.count == 0);
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
        if ([friendsIds containsObject:message.senderID]) {
            UserAnnotation* messageAnnotation = [[DataManager shared] convertQBMessageToUserAnnotation:message];
            [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying addObject:messageAnnotation];
        }
    }

    [friendsIds release];
}

-(void)refreshDataFromStorage{
                                        // sort QB messages by date of creation
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"dateTime" ascending: NO] autorelease];
	NSArray* sortedArray = [[DataManager shared].currentChatRoom.messagesHistory sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
	[[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
                    // create new sorted and array for displaying
    for (QBChatMessage* message in sortedArray) {
        UserAnnotation* messageAnnotation = [[DataManager shared] convertQBMessageToUserAnnotation:message];
        [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying addObject:messageAnnotation];
    }
}

-(void)addDataToStorage:(UserAnnotation*)newData{
    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying addObject:newData];
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
    if (index >= 0 && index < [DataManager shared].currentChatRoom.messagesHistory.count) {
        QBChatMessage* message = [[DataManager shared] convertUserAnnotationToQBChatMessage:object];
        [[DataManager shared].currentChatRoom.messagesHistory addObject:message];
    }
}


-(void)insertObjectToPartialData:(UserAnnotation*)object atIndex:(NSInteger)index{
    if (index >= 0 && index < [DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying.count) {
        [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying insertObject:object atIndex:index];
    }
}

-(void)removeAllPartialData{
    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
}

@end
