//
//  MessagesViewController.h
//  ChattAR for facebook
//
//  Created by QuickBlox developers on 03.05.12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBServiceResultDelegate.h"
#import "AsyncImageView.h"
#import "ViewTouch.h"
#import "MBProgressHUD.h"

#import "FBChatViewController.h"


@class Conversation;
@class ContactsController;

@protocol MessagesNavigationDelegate <NSObject>

-(void) showConversation:(Conversation*)conversation;

@end



@interface MessagesViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,  MBProgressHUDDelegate , MessagesNavigationDelegate>
{	
    
    ViewTouch				*backView;
    
    BOOL isInitialized;
}

@property (retain, nonatomic) IBOutlet UITableView				*messageTableView;
@property (retain, nonatomic) ContactsController * contactsController;

@end
