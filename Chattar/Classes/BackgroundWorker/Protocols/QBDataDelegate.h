//
//  QBDataDelegate.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <Foundation/Foundation.h>
#import "ChatViewController.h"
#import "MapViewController.h"

@protocol QBDataDelegate <NSObject>
@optional

-(void)didReceiveCachedChatPoints:(NSArray*)cachedChatPoints;
-(void)didReceiveCachedChatMessagesIDs:(NSArray*)cachedChatMessagesIDs;

@end
