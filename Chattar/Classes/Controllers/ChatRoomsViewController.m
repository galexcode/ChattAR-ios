//
//  ChatRoomsViewController.m
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import "ChatRoomsViewController.h"
#import "ChatRoom.h"
#import "DataManager.h"


@interface ChatRoomsViewController ()

@end

@implementation ChatRoomsViewController
@synthesize dialogsController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Chat Rooms", @"Chat Rooms");
        self.tabBarItem.image = [UIImage imageNamed:@"dialogsTab.png"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveChatRooms) name:kDataIsReadyForDisplaying object:nil];
    }
    return self;
}

- (void)viewDidLoad
{

    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_newConversationTextField setDelegate:self];
    
    UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                                      NSLocalizedString(@"Pick your chat",nil),
                                                                                      NSLocalizedString(@"My Dialogs",nil),
                                                                                      nil]];
    [segmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [segmentedControl setFrame:CGRectMake(20, 7, 280, 30)];
    [segmentedControl addTarget:self action:@selector(segmentValueDidChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = segmentedControl;
    [segmentedControl release];
    
    dialogsController = [[MessagesViewController alloc] initWithNibName:@"MessagesViewController" bundle:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_roomsTableView release];
    [_newConversationTextField release];
    [dialogsController release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setRoomsTableView:nil];
    [self setNewConversationTextField:nil];
    [super viewDidUnload];
}
- (IBAction)startButtonTap:(UIButton *)sender {
    NSString* roomName = _newConversationTextField.text;
    if ([Helper isStringCorrect:roomName]) {
        [[BackgroundWorker instance] createChatRoom:roomName];
    }
}

#pragma mark -
#pragma mark Interface based methods
-(UIView*)createHeaderForSection:(NSInteger)section{
    UILabel* header = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    [header setBackgroundColor:[UIColor clearColor]];
    [header setTextColor:[UIColor whiteColor]];
    CGSize titleViewSize;
    
    switch (section) {
        case mainChatSection:{
            [header setText:@"Main"];
        }
            break;
        case trendingSection:{
            [header setText:@"Trending"];
        }
            break;
            
        case nearbySection:{
            [header setText:@"Nearby"];
        }
            break;
            
        default:
            break;
    }
    
    titleViewSize = [header.text sizeWithFont:header.font];
    [header setFrame:CGRectMake(10, 5, titleViewSize.width, titleViewSize.height)];
    UIView* sectionTitleView = [[[UIView alloc] initWithFrame:CGRectMake(20, 0, titleViewSize.width + 20, 30)] autorelease];
    
    
    [sectionTitleView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"headerBGColor"]]];
    [sectionTitleView.layer setCornerRadius:5];

    [sectionTitleView addSubview:header];
    
    UIImageView* viewForHeaderInSection = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.roomsTableView.bounds.size.width, 30)] autorelease];
    [viewForHeaderInSection addSubview:sectionTitleView];
    
    UILabel* seeAllText = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    [seeAllText setBackgroundColor:[UIColor clearColor]];
    CGSize seeAllTextSize = [@"See All" sizeWithFont:seeAllText.font];
    
    [seeAllText setFrame:CGRectMake(_roomsTableView.bounds.size.width-95, 5, seeAllTextSize.width, seeAllTextSize.height)];
    [seeAllText setTextColor:[UIColor grayColor]];
    [seeAllText setText:@"See All"];
    [viewForHeaderInSection addSubview:seeAllText];
    
    UIButton* seeAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [seeAllButton setFrame:CGRectMake(_roomsTableView.bounds.size.width-40, 5, 20, 20)];
    [seeAllButton setImage:[UIImage imageNamed:@"seeAllButton.png"] forState:UIControlStateNormal];
    
    [viewForHeaderInSection addSubview:seeAllButton];
    
    return viewForHeaderInSection;
}

-(void)segmentValueDidChanged:(UISegmentedControl*)sender{
    switch (sender.selectedSegmentIndex) {
        case 0:
            [self showChats];
            break;
            
        case 1:
            [self showDialogs];
            break;
            
        default:
            break;
    }
}

-(void)showChats{
    [dialogsController.view removeFromSuperview];
}

-(void)showDialogs{
    if ([dialogsController.view superview] == nil) {
        [self.view addSubview:dialogsController.view];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section != mainChatSection) {
        return 2;
    }
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* identifier = @"CellIdentifier";
    UITableViewCell* cell = [_roomsTableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
        
    switch (indexPath.section) {
        case trendingSection:{
            if (indexPath.row < [DataManager shared].trendingRooms.count) {
                ChatRoom* room = [[DataManager shared].trendingRooms objectAtIndex:indexPath.row];
                NSString* cellText = [NSString stringWithFormat:@"%@",room.xmppName];
                UIImageView* accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"occupantsCounter.png"]] autorelease];
                UILabel* counter = [[[UILabel alloc] initWithFrame:CGRectMake(20, -1, 20, 20)] autorelease];
                [counter setText:[NSString stringWithFormat:@"%d",room.roomUsers.count]];
                [counter setBackgroundColor:[UIColor clearColor]];
                [accessoryView addSubview:counter];
                [cell setAccessoryView:accessoryView];
                [cell.textLabel setText:cellText];
                
            }
            break;
        }
        case nearbySection:{
            if (indexPath.row < [DataManager shared].nearbyRooms.count) {
                ChatRoom* room = [[DataManager shared].nearbyRooms objectAtIndex:indexPath.row];
                NSString* cellText = [NSString stringWithFormat:@"%f",room.distanceFromUser];
                UIImageView* accessoryView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"occupantsCounter.png"]] autorelease];
                UILabel* counter = [[[UILabel alloc] initWithFrame:CGRectMake(20, -1, 20, 20)] autorelease];
                [counter setBackgroundColor:[UIColor clearColor]];
                [counter setText:[NSString stringWithFormat:@"%d",room.roomUsers.count]];
                [accessoryView addSubview:counter];
                [cell setAccessoryView:accessoryView];
                [cell.textLabel setText:cellText];
            }
            break;
        }
        default:
            break;
    }
    
    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [self createHeaderForSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    #warning unimplemented
}

#pragma mark -
#pragma mark Notifications Reactions
-(void)doReceiveChatRooms{
    [_roomsTableView reloadData];
}

#pragma mark -
#pragma mark UITextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [textField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [_newConversationTextField resignFirstResponder];
    return YES;
}
@end
