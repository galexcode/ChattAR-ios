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
@synthesize loadingIndicator = _loadingIndicator;
@synthesize mainHeaderSection;
@synthesize nearbyHeaderSection;
@synthesize trendingHeaderSection;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Chats", @"Chats");
        self.tabBarItem.image = [UIImage imageNamed:@"dialogsTab.png"];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveChatRooms) name:kDataIsReadyForDisplaying object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNeedDisplayChatRoomsController) name:kNeedToDisplayChatRoomController object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doCreateNewRoom) name:kNewChatRoomCreated object:nil];
    }
    return self;
}

- (void)viewDidLoad
{

    [super viewDidLoad];
    [_newConversationTextField setDelegate:self];
    NSArray* segments = @[@"Pick up your chat", @"Dialogs"];
    
    [self.navigationItem.backBarButtonItem setAction:@selector(exitChatRoom:)];
    
    UISegmentedControl* segmentControl = [[UISegmentedControl alloc] initWithItems:segments];
    [segmentControl setSegmentedControlStyle:UISegmentedControlStyleBar];
    [segmentControl setFrame:CGRectMake(20, 7, 280, 30)];
    [segmentControl addTarget:self action:@selector(segmentValueDidChanged:) forControlEvents:UIControlEventValueChanged];
    [segmentControl setSelectedSegmentIndex:0];
    self.navigationItem.titleView = segmentControl;
    
    
    [segmentControl release];

    MessagesViewController* messagesVC = [[MessagesViewController alloc] initWithNibName:@"MessagesViewController" bundle:nil];
    
    dialogsController = [[UINavigationController alloc] initWithRootViewController:messagesVC];
    
    [messagesVC release];
    dialogsController.navigationBarHidden = YES;
    
    [dialogsController setDelegate:self];
    
    expandedSections = [[NSMutableIndexSet alloc] init];
    
    UIBarButtonItem* btn = [[[UIBarButtonItem alloc] initWithTitle:@"Chat Rooms" style:UIBarButtonItemStyleBordered target:nil action:@selector(exitChatRoom:)] autorelease];
    self.navigationItem.backBarButtonItem = btn;
}

-(void)viewWillAppear:(BOOL)animated{
    if ([DataManager shared].qbChatRooms.count == 0 && [DataManager shared].roomsWithAdditionalInfo.count == 0) {
        [[BackgroundWorker instance] requestAdditionalChatRoomsInfo];
        [self addSpinner];
        
        NSLog(@"%@",self.navigationItem.titleView);

        
        // additional request for checkins
        if ([DataManager shared].allCheckins.count == 0) {
            [[BackgroundWorker instance] retrieveCachedFBCheckinsAndRequestNewCheckins];
        }        
    }
    else
        [_roomsTableView reloadData];
    
    [self.roomsTableView deselectRowAtIndexPath:[self.roomsTableView indexPathForSelectedRow] animated:YES];
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
    [_loadingIndicator release];
    [expandedSections release];
    
    [mainHeaderSection release];
    [trendingHeaderSection release];
    [nearbyHeaderSection release];
    [tapRecognizer release];
    
    [_displayView release];
    [super dealloc];
}

- (void)viewDidUnload {
    [self setRoomsTableView:nil];
    [self setNewConversationTextField:nil];
    [self setLoadingIndicator:nil];
    [self setDisplayView:nil];
    [super viewDidUnload];
}
- (IBAction)startButtonTap:(UIButton *)sender {
    NSString* roomName = _newConversationTextField.text;
    if ([Helper isStringCorrect:roomName]) {
        [[BackgroundWorker instance] createChatRoom:roomName];
    }
    else{
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Incorrect chat room name" message:@"Please enter valid chat room name" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alert show];
        [alert release];
    }
}

#pragma mark -
#pragma mark Interface based methods

- (UIImageView*)viewWithLastActiveUsers{
    UIImageView* viewWithLastActiveUsers = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    NSSortDescriptor* sortOrder = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
    
    NSArray* sortedByDateChatMessages = [[DataManager shared].allChatPoints sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
    __block int userViewXPosition = -10;
    __block NSMutableArray* usedURLsArray = [[[NSMutableArray alloc] init] autorelease];
    
    [sortedByDateChatMessages enumerateObjectsUsingBlock:^(UserAnnotation* obj, NSUInteger idx, BOOL *stop) {        
        NSString* userImageURL = nil;
        if ([obj.userPhotoUrl isKindOfClass:[NSString class]]){
            userImageURL = obj.userPhotoUrl;
        }else{
            NSDictionary* pic = (NSDictionary*)obj.userPhotoUrl;
            userImageURL = [[pic objectForKey:kData] objectForKey:kUrl];
        }

        
        if (![usedURLsArray containsObject:userImageURL]) {
            AsyncImageView* activeUserView = [[[AsyncImageView alloc] initWithFrame:CGRectMake(userViewXPosition, 5, SIZE_OF_USER_PICTURE, SIZE_OF_USER_PICTURE)] autorelease];
            [activeUserView loadImageFromURL:[NSURL URLWithString:userImageURL]];
            [viewWithLastActiveUsers addSubview:activeUserView];
            userViewXPosition += activeUserView.frame.size.width + PADDING;
            [usedURLsArray addObject:userImageURL];
        }
        
        if (usedURLsArray.count == NUMBER_OF_USERS_TO_DISPLAY) {
            *stop = YES;
        }

    }];
    
    return viewWithLastActiveUsers;
}

- (void)addExpandedSeeAllButton:(UIButton*) seeAllButton isButtonExpanded:(BOOL)isExpanded {
    // remove old button
    [[seeAllButton viewWithTag:SEE_ALL_IMAGE_TAG] removeFromSuperview];
    UIImage* seeAllButtonImage = nil;
    
    if (isExpanded) {
        seeAllButtonImage = [UIImage imageNamed:@"seeAllExpanded.png"];
    }
    else
        seeAllButtonImage = [UIImage imageNamed:@"seeAllButton"];
    
    UIImageView* seeAllButtonImageView = [[[UIImageView alloc] initWithImage:seeAllButtonImage] autorelease];
    CGRect newFrame = seeAllButtonImageView.frame;
    [seeAllButtonImageView setTag:SEE_ALL_IMAGE_TAG];
    
    newFrame.origin.x += 20;
    newFrame.origin.y -= 5;
    seeAllButtonImageView.frame = newFrame;
    
    [seeAllButton addSubview:seeAllButtonImageView];    
}

- (void) removeKeyBoard:(UITapGestureRecognizer*)recognizer {
    [self animateTextField:_newConversationTextField up:NO];
    [_newConversationTextField resignFirstResponder];
    [self.displayView removeGestureRecognizer:recognizer];
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const float movementDuration = 0.3f;
    const int movementDistance = 170;
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}


-(void)showChatController{
    ChatRoomsStorage* dataStorage = [[[ChatRoomsStorage alloc] init] autorelease];

    ChatViewController* chatViewController = [[[ChatViewController alloc] initWithNibName:@"ChatViewController" bundle:nil] autorelease];
    [chatViewController setDataStorage:dataStorage];
    
    chatViewController.controllerReuseIdentifier = [[NSString alloc] initWithString:chatRoomsViewControllerIdentifier];
    chatViewController.title = NSLocalizedString([DataManager shared].currentChatRoom.roomName, nil);
    [self.navigationController pushViewController:chatViewController animated:YES];

}

- (BOOL)canCollapseSection:(NSInteger)section
{
    if (section == nearbySection) {
        return ([DataManager shared].nearbyRooms.count > 2);
    }
    else if (section == trendingSection){
        return ([DataManager shared].trendingRooms.count > 2);
    }
    
    return NO;
}

-(void)addSpinner{
    if (!_loadingIndicator) {
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    if (![self.view viewWithTag:INDICATOR_TAG]) {
        [self.view addSubview:_loadingIndicator];
        [_loadingIndicator startAnimating];
    }
    
    _loadingIndicator.center = self.view.center;
    [self.view bringSubviewToFront:_loadingIndicator];
    
    [_loadingIndicator setTag:INDICATOR_TAG];
}

-(UIView*)createHeaderForSection:(NSInteger)section{    
    switch (section) {
        case mainChatSection:{
            if (!mainHeaderSection) {
                mainHeaderSection = [[self createViewWithTitle:@"mainHeader.png" forSection:section] retain];
            }
            return mainHeaderSection;
        }
            break;
        case trendingSection:{
            if (!trendingHeaderSection) {
                trendingHeaderSection = [[self createViewWithTitle:@"trendingHeader.png" forSection:section] retain];
            }
            return trendingHeaderSection;
        }
            break;

        case nearbySection:{
            if (!nearbyHeaderSection) {
                nearbyHeaderSection = [[self createViewWithTitle:@"nearbyHeader.png" forSection:section] retain];
            }
            return nearbyHeaderSection;
        }
            break;

        default:
            break;
    }
    return nil;
}

- (UIImageView*)createViewWithTitle:(NSString*)headerTitle forSection:(NSInteger)section{
    UIImageView* viewForHeaderInSection = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.roomsTableView.bounds.size.width, 30)] autorelease];
        
    UIImageView* headerView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:headerTitle]] autorelease];
    CGRect newFrame = headerView.frame;
    newFrame.origin.x = 15;
    headerView.frame = newFrame;
    [viewForHeaderInSection addSubview:headerView];

    

    UILabel* seeAllText = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    [seeAllText setBackgroundColor:[UIColor clearColor]];
    CGSize seeAllTextSize = [@"See All" sizeWithFont:seeAllText.font];
    [seeAllText setTextColor:[UIColor redColor]];
    [seeAllText setFont:[UIFont fontWithName:@"Helvetica" size:15]];

    [seeAllText setFrame:CGRectMake(-28, 0, seeAllTextSize.width, seeAllTextSize.height)];
    [seeAllText setTextColor:[UIColor grayColor]];
    [seeAllText setText:@"See All"];

    if (section != mainChatSection) {
        UIButton* seeAllButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [seeAllButton setFrame:CGRectMake(_roomsTableView.bounds.size.width-60, 5, seeAllText.frame.size.width + 20, seeAllText.frame.size.height)];
        
        [self addExpandedSeeAllButton:seeAllButton isButtonExpanded:NO];
        
        if (section == nearbySection) {
            [seeAllButton setTag:NEARBY_SECTION_INDEX];
        }
        else if (section == trendingSection){
            [seeAllButton setTag:TRENDING_SECTION_INDEX];
        }
        
        [seeAllButton addTarget:self action:@selector(expandSection:) forControlEvents:UIControlEventTouchDown];
        [seeAllButton addSubview:seeAllText];
        [seeAllButton bringSubviewToFront:seeAllText];
        
        [viewForHeaderInSection addSubview:seeAllButton];
        [viewForHeaderInSection bringSubviewToFront:seeAllButton];
        [viewForHeaderInSection setUserInteractionEnabled:YES];
    }
    
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

-(void)expandSection:(UIButton*)sender{
    NSInteger currentSection = -1;
                    // determine section
    if (sender.tag == NEARBY_SECTION_INDEX) {
        currentSection = nearbySection;
    }

    else if (sender.tag == TRENDING_SECTION_INDEX){
        currentSection = trendingSection;
    }
    
    if ([self canCollapseSection:currentSection]) {
        BOOL currentlyExpanded = [expandedSections containsIndex:currentSection];
        
        NSInteger rows;
        
        NSMutableArray *tmpArray = [NSMutableArray array];
        
        if (currentlyExpanded){
            rows = [self tableView:_roomsTableView numberOfRowsInSection:currentSection];
            [expandedSections removeIndex:currentSection];
        }
        
        else{
            [expandedSections addIndex:currentSection];
            rows = [self tableView:_roomsTableView numberOfRowsInSection:currentSection];
        }
        
        for (int i = NUMBER_OF_ROWS_BY_DEFAULT; i < rows; i++){
            NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i
                                                           inSection:currentSection];
            [tmpArray addObject:tmpIndexPath];
        }
        
        if (currentlyExpanded) {
            [self addExpandedSeeAllButton:sender isButtonExpanded:NO];
            [_roomsTableView deleteRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
        }
        
        else{
            [self addExpandedSeeAllButton:sender isButtonExpanded:YES];
            [_roomsTableView insertRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
        }
        
    }
}

-(void)showChats{
    if ([dialogsController.view superview]) {
        [dialogsController.view removeFromSuperview];
    }
    
}

-(void)showDialogs{
    if ([dialogsController.view superview] == nil) {
        [self.displayView addSubview:dialogsController.view];
    }
    
}

#pragma mark -
#pragma mark UITableViewDataSource 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([self canCollapseSection:section])
    {
        if ([expandedSections containsIndex:section])
        {
            if (section == nearbySection) {
                return [DataManager shared].nearbyRooms.count;
            }
            else if (section == trendingSection){
                return [DataManager shared].trendingRooms.count;
            }
        }
        
        return NUMBER_OF_ROWS_BY_DEFAULT; 
    }
    
    return (section == mainChatSection) ? 1 : NUMBER_OF_ROWS_BY_DEFAULT;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString* identifier = @"CellIdentifier";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    switch (indexPath.section) {
        case trendingSection:{
            if (indexPath.row < [DataManager shared].trendingRooms.count) {
                ChatRoom* room = [[DataManager shared].trendingRooms objectAtIndex:indexPath.row];
                NSString* cellText = [NSString stringWithFormat:@"%@",room.roomName];
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
                NSString* cellText = [NSString stringWithFormat:@"%d kms",(int)room.distanceFromUser/1000];
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
            
        case mainChatSection:{
            [cell.textLabel setText:@"Public Chat"];
            [cell setAccessoryView:[self viewWithLastActiveUsers]];
        }
        break;
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

    ChatRoom* selectedChatRoomWithAdditionalInfo = nil;
    switch (indexPath.section) {
        case nearbySection:
            selectedChatRoomWithAdditionalInfo = [[DataManager shared].nearbyRooms objectAtIndex:indexPath.row];
            break;
        case trendingSection:
            selectedChatRoomWithAdditionalInfo = [[DataManager shared].trendingRooms objectAtIndex:indexPath.row];
        default:
            break;
    }
    QBChatRoom* selectedChatRoom = [[DataManager shared] findQBRoomWithName:selectedChatRoomWithAdditionalInfo.roomName];
    
    if (selectedChatRoomWithAdditionalInfo) {
        
        if (![DataManager shared].currentChatRoom) {
            [DataManager shared].currentChatRoom = [[ChatRoom alloc] init];
            [DataManager shared].currentChatRoom.isSendingMessage = NO;
        }
        
        // save current chat room
        [DataManager shared].currentChatRoom = selectedChatRoomWithAdditionalInfo;
    }

    
    if (![selectedChatRoom isJoined]) {
        if (selectedChatRoom) {
            [[BackgroundWorker instance] joinRoom:selectedChatRoom];
        }
    }
    else{
        [self doNeedDisplayChatRoomsController];
    }
    
}

#pragma mark -
#pragma mark Notifications Reactions

-(void)doCreateNewRoom{
    [self showChatController];
}

-(void)doReceiveChatRooms{
    [(UIActivityIndicatorView*)([self.view viewWithTag:INDICATOR_TAG]) removeFromSuperview];
    
    [_roomsTableView reloadData];
}

-(void)doNeedDisplayChatRoomsController{
    [self showChatController];
}

#pragma mark -
#pragma mark UITextField Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self animateTextField:textField up:YES];
    [textField becomeFirstResponder];
    
    if (!tapRecognizer) {
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeKeyBoard:)];
    }
    
    [self.displayView addGestureRecognizer:tapRecognizer];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self animateTextField:textField up:NO];
    [textField resignFirstResponder];
    [self.displayView removeGestureRecognizer:tapRecognizer];
    return YES;
}


#pragma mark - 
#pragma mark UINavigationControllerDelegate methods
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [viewController viewWillAppear:animated];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
    [viewController viewDidAppear:animated];
}
@end
