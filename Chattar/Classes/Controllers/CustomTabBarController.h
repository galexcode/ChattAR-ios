//
//  CustomTabBarController.h
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import <UIKit/UIKit.h>
#import "BackgroundWorker.h"
#import "ChatRoom.h"
@interface CustomTabBarController : UITabBarController<FBDataDelegate,DataDelegate,ChatControllerDelegate,
                                    MapControllerDelegate,ARControllerDelegate, QBChatDelegate,ChatRoomDataDelegate>
@end
