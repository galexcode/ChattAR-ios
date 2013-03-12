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

#define NUMBER_OF_ROWS_BY_DEFAULT 2
#define NEARBY_SECTION_INDEX 1 
#define TRENDING_SECTION_INDEX 2

#define NEARBY_SECTION_EXPANDED 4
#define TRENDING_SECTION_EXPANDED 5

@interface ChatRoomsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UINavigationControllerDelegate>{
    NSMutableIndexSet* expandedSections;
    UITapGestureRecognizer* tapRecognizer;
}

@property (retain, nonatomic) IBOutlet UITableView *roomsTableView;
@property (retain, nonatomic) IBOutlet UITextField *newConversationTextField;

@property (retain, nonatomic) UIImageView* mainHeaderSection;
@property (retain, nonatomic) UIImageView* nearbyHeaderSection;
@property (retain, nonatomic) UIImageView* trendingHeaderSection;

- (IBAction)startButtonTap:(UIButton *)sender;

@property (nonatomic, retain) UINavigationController* dialogsController;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (retain, nonatomic) IBOutlet UIView *displayView;

@end
enum TableSections {
    mainChatSection = 0,
    trendingSection = 1,
    nearbySection = 2
};