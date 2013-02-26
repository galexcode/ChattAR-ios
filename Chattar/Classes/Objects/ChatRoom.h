//
//  ChatRoom.h
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import <Foundation/Foundation.h>

@interface ChatRoom : NSObject
@property (nonatomic,retain) NSString* xmppName;
@property (nonatomic, assign) CLLocationCoordinate2D ownerLocation;
@property (nonatomic,retain) NSString* roomID;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, assign) double roomRating;
@property (nonatomic, assign) double distanceFromUser;
@property (nonatomic, retain) NSMutableArray* roomUsers;
@property (nonatomic, retain) NSMutableArray* messagesHistory;
@end
