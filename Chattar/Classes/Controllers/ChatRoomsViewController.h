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

@interface ChatRoomsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITableView *roomsTableView;
@property (retain, nonatomic) IBOutlet UITextField *newConversationTextField;
- (IBAction)startButtonTap:(UIButton *)sender;


@end
enum TableSections {
    mainChatSection = 0,
    trendingSection = 1,
    nearbySection = 2
};