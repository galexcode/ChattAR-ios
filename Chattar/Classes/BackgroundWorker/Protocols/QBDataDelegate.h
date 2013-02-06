//
//  QBDataDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>

@protocol QBDataDelegate <NSObject>
@optional
-(void)didReceiveQBGeodatas:(NSArray*)qbGeodatas;

-(void)didReceiveCachedChatPoints:(NSArray*)cachedChatPoints;
-(void)didReceiveCachedChatMessagesIDs:(NSArray*)cachedChatMessagesIDs;
-(void)didReceiveQBChatMessages:(NSArray*)qbChatMessages;

@end
