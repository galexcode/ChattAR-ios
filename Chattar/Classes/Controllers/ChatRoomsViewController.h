//
//  ChatRoomsViewController.h
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import <UIKit/UIKit.h>
#import "BackgroundWorker.h"
#import "CustomTabBarController.h"
#import "Helper.h"
#import "MessagesViewController.h"
#import "ChatRoomsStorage.h"
#import "Storage.h"
#import "ChatViewController.h"

@interface ChatRoomsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UINavigationControllerDelegate>
@property (retain, nonatomic) IBOutlet UITableView *roomsTableView;
@property (retain, nonatomic) IBOutlet UITextField *newConversationTextField;
- (IBAction)startButtonTap:(UIButton *)sender;

@property (nonatomic, retain) UINavigationController* dialogsController;

@end
enum TableSections {
    mainChatSection = 0,
    trendingSection = 1,
    nearbySection = 2
};