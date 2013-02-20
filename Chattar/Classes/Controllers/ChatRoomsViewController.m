//
//  ChatRoomsViewController.m
//  Chattar
//
//  Created by kirill on 2/20/13.
//
//

#import "ChatRoomsViewController.h"

@interface ChatRoomsViewController ()

@end

@implementation ChatRoomsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Chat Rooms", @"Chat Rooms");
        self.tabBarItem.image = [UIImage imageNamed:@"dialogsTab.png"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveChatRooms) name:kDidReceiveChatRooms object:nil];
    }
    return self;
}

- (void)viewDidLoad
{

    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [_newConversationTextField setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [_roomsTableView release];
    [_newConversationTextField release];
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
#pragma mark UITableViewDataSource 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case trendingSection:
            return [DataManager shared].trendingChatRooms.count;
            break;
            
        case nearbySection:
            return [DataManager shared].nearbyChatRooms.count;
            break;
        default:
            return 1;
            break;
    }
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
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case mainChatSection:
            return @"Main Chat";
        case trendingSection:
            return @"Trending";
        case nearbySection:
            return @"Nearby";
        default:
            break;
    }
    return nil;
}

#pragma mark -
#pragma mark UITableViewDelegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    #warning unimplemented
    return nil;
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
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}
@end
