//
//  ChatViewController.m
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 3/27/12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#define messageWidth 250
#define getMoreChatMessages @"getMoreChatMessages"
#define getQuotedId			@"getQuotedId"

#import "ChatViewController.h"
#import "ARMarkerView.h"
#import "WebViewController.h"
#import "ProvisionManager.h"
#import "AppDelegate.h"

@interface ChatViewController ()

@end

@implementation ChatViewController

@synthesize messageField, messagesTableView, sendMessageActivityIndicator;
@synthesize quoteMark, quotePhotoTop;
@synthesize delegate;
@synthesize dataStorage;
@synthesize controllerReuseIdentifier;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.title = NSLocalizedString(@"Public Chat", nil);
		self.tabBarItem.image = [UIImage imageNamed:@"chatTab.png"];

                    // logout
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutDone) name:kNotificationLogout object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doUpdate:) name:kWillUpdate object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doScrollToTop:) name:kWillScrollToTop object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doClearMessageField:) name:kWillClearMessageField object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doRemoveLastChatPoint:) name:kWillRemoveLastChatPoint object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotReceiveNewChatPoints:) name:kDidNotReceiveNewChatPoints object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveErrorLoadingNewChatPoints:) name:kdidReceiveErrorLoadingNewChatPoints object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doSuccessfulMessageSending:) name:kDidSuccessfulMessageSending object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doShowAllFriends) name:kWillShowAllFriends object:nil ];

//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doChatEndRetrievingData:) name:kChatEndOfRetrievingInitialData object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doWillSetAllFriendsSwitchEnabled:) name:kWillSetAllFriendsSwitchEnabled object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doWillSetMessageFieldEnabled:) name:kWillSetMessageFieldEnabled object:nil ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doChatNotReceiveNewFBChatUsers:) name:kDidNotReceiveNewFBChatUsers object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doClearCache) name:kDidClearCache object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveUserProfilePictures:) name:kDidReceiveUserProfilePicturesURL object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doAddNewPointToChat:) name:kWillAddNewMessageToChat object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doUpdateChatRoomsController:) name:kNeedToUpdateChatRoomController object:nil];
        
        isPanelDisplayed = NO;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 0)];
    messageField.leftViewMode = UITextFieldViewModeAlways;
    messageField.leftView = paddingView;
    [paddingView release];
    
    // message bubble
    messageBGImage = [[[UIImage imageNamed:@"cellBodyBG.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:22] retain];
    messageBGImage2 = [[[UIImage imageNamed:@"bubble_green-1.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:22] retain];
    
    distanceImage = [[UIImage imageNamed:@"kmBG.png"] retain];
    distanceImage2 = [[UIImage imageNamed:@"kmBG2.png"] retain];

    // current page of geodata
    page = 1;
	
    // YES when is getting new messages
	isLoadingMoreMessages = NO;    
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound && [self.controllerReuseIdentifier isEqualToString:chatRoomsViewControllerIdentifier]) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        QBChatRoom* currentChatRoom = [[DataManager shared] findQBRoomWithName:[DataManager shared].currentChatRoom.roomName];
        [[BackgroundWorker instance] exitChatRoom:currentChatRoom];
    }
    
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    if ([self.controllerReuseIdentifier isEqualToString:chatRoomsViewControllerIdentifier]) {
        [self cleanData];
    }
}


- (void)removeQuote
{
    messageField.rightView = nil;
    quotePhotoTop = nil;
	self.quoteMark = nil;
    
    [messageField resignFirstResponder];
}

- (void)viewDidUnload
{
    self.messageField = nil;
    self.messagesTableView = nil;
    self.sendMessageActivityIndicator = nil;

    [messageBGImage release];
    messageBGImage = nil;
    [messageBGImage2 release];
    messageBGImage2 = nil;
    [distanceImage release];
    distanceImage = nil;
    [distanceImage2 release];
    distanceImage2 = nil;
    
    [self setLoadingIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


-(void)viewWillAppear:(BOOL)animated{   
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [self checkForShowingData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [dataStorage release];
    [controllerReuseIdentifier release];
    [super dealloc];
}

#pragma mark -
#pragma mark Interface based methods

- (void)cleanData{
    // clean data
    [[DataManager shared].currentChatRoom.messagesAsUserAnnotationForDisplaying removeAllObjects];
    [[DataManager shared].currentChatRoom.messagesHistory removeAllObjects];
    [messagesTableView reloadData];

}

- (void)addMessageToChatTable: (UserAnnotation*)message toTableTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable{

    if ([self.controllerReuseIdentifier isEqualToString:chatViewControllerIdentifier]) {
        __block BOOL addedToCurrentChatState = NO;
        NSArray *friendsIds = [[DataManager shared].myFriendsAsDictionary allKeys];
        
        // New messages
        if (toTop){
            [dataStorage insertObjectToAllData:message atIndex:0];
            if([self isAllShowed] || [friendsIds containsObject:message.fbUserId] ||
               
               [message.fbUserId isEqualToString:[DataManager shared].currentFBUserId]){
                
                [dataStorage insertObjectToPartialData:message atIndex:0];
                addedToCurrentChatState = YES;
            }
            
            // old messages
        }
        else {
            [dataStorage insertObjectToAllData:message atIndex:([dataStorage allDataCount] > 0) ?
             ([dataStorage allDataCount]-1):
             0];
            
            if([self isAllShowed] || [friendsIds containsObject:message.fbUserId] ||
               [message.fbUserId isEqualToString:[DataManager shared].currentFBUserId]){
                
                [dataStorage insertObjectToPartialData:message atIndex:[dataStorage storageCount] > 0 ? ([dataStorage storageCount]-1): 0];
                addedToCurrentChatState = YES;
            }
        }
        if(addedToCurrentChatState && reloadTable){
            // on main thread
            
            [self.messagesTableView reloadData];
            
        }
    }
    
    else if ([self.controllerReuseIdentifier isEqualToString:chatRoomsViewControllerIdentifier]){
        if (toTop) {
            [dataStorage insertObjectToAllData:message atIndex:0];
            [dataStorage insertObjectToPartialData:message atIndex:0];
        }
        else{
            int index =  ([dataStorage allDataCount] > 0) ? ([dataStorage allDataCount]-1) : 0;
            [dataStorage insertObjectToAllData:message atIndex:index];
            
            index = ([dataStorage storageCount] > 0) ? ([dataStorage storageCount]-1) : 0;
            [dataStorage insertObjectToPartialData:message atIndex:index];
        }
        
        [self.messagesTableView reloadData];
    }
    

}

-(void)checkForShowingData{
    if ([dataStorage isStorageEmpty]) {
        [messagesTableView reloadData];
        [[BackgroundWorker instance] requestDataForDataStorage:self.dataStorage];
        [self addSpinner];
    }

    else{
        if ([[self allFriendsSwitch] value] == friendsValue) {
            [self showFriends];
        }
        
        else
            [self showWorld];
        
        if ([dataStorage isKindOfClass:[ChatRoomsStorage class]] && !isPanelDisplayed) {
            NSLog(@"%@",self.navigationItem.leftBarButtonItem);
            [self addUserPicturesToPanel];
            isPanelDisplayed = YES;            
        }
    }
}

-(void)addUserPicturesToPanel{
    UIImageView* occupantsPanel = [[[UIImageView alloc] initWithFrame:CGRectMake(0, messageField.frame.size.height+12, 320, 50)] autorelease];
    [occupantsPanel setBackgroundColor:[UIColor blueColor]];
    
    __block int x = 20;
    [[DataManager shared].currentChatRoom.usersPictures enumerateObjectsUsingBlock:^(NSDictionary* userData, NSUInteger index, BOOL *stop) {
        AsyncImageView* occupantImage = [[[AsyncImageView alloc] initWithFrame:CGRectMake(x, 5, 40, 40)] autorelease];
        
        NSString* currentPictureURL = [userData objectForKey:@"pictureURL"];
         
        
        [occupantImage loadImageFromURL:[NSURL URLWithString:currentPictureURL]];
        [occupantsPanel addSubview:occupantImage];
        x += occupantImage.bounds.size.width + 15;
    }];
    
    [self.view insertSubview:occupantsPanel aboveSubview:messagesTableView];
    CGRect tableFrame = messagesTableView.frame;
    tableFrame.origin.y += occupantsPanel.frame.size.height;
    tableFrame.size.height -= occupantsPanel.frame.size.height;
    messagesTableView.frame = tableFrame;
}

- (IBAction)sendMessageDidPress:(id)sender{
                                                // check internet connection
    if (![Reachability internetConnected]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"No internet connection."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    // check for empty
    if ([[messageField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        return;
    }
    if([sendMessageActivityIndicator isAnimating]){
        if([Reachability internetConnected]){
            [sendMessageActivityIndicator stopAnimating];
        }else{
            return;
        }
    }
    
    [sendMessageActivityIndicator startAnimating];
    
    // remove | and @ symbols
    messageField.text = [messageField.text  stringByReplacingOccurrencesOfString:@"|" withString:@""];
    messageField.text = [messageField.text  stringByReplacingOccurrencesOfString:@"@" withString:@""];
        
    NSMutableDictionary* data = [NSMutableDictionary dictionary];
    [data setObject:messageField.text forKey:@"messageText"];
    if (quoteMark) {
        [data setObject:quoteMark forKey:@"quoteMark"];
    }

    [dataStorage createDataInStorage:data];
    
    [DataManager shared].currentChatRoom.isSendingMessage = YES;
    
    [[BackgroundWorker instance] postInformationWithDataStorage:dataStorage];
    
    if(quotePhotoTop){
        [quotePhotoTop removeFromSuperview];
        quotePhotoTop = nil;
    }else{
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        messageField.rightViewMode = UITextFieldViewModeAlways;
        messageField.rightView = view;
        [view release];
    }

	self.quoteMark = nil;    
}

-(void)showWorld{
    [dataStorage showWorldDataFromStorage];
    
    [self refresh];
}

-(void)showFriends{
    [dataStorage showFriendsDataFromStorage];
    
    [self refresh];
}


- (void)addQuote
{
    // pattern
    // @fbid=<FB_id>@name=<user_name>@date=<created_at>@photo=<url>@qbid=<QB_id>@msg=<text>|<message_text>
    //
    
    NSString *userStatus = [self selectedUserAnnotation].userStatus;
    
    NSString *text = [[DataManager shared] originMessageFromQuote:userStatus];
	
    NSDate* date = [self selectedUserAnnotation].createdAt;
    NSString* authorName = [self selectedUserAnnotation].userName;
    NSString* photoLink = [[self selectedUserAnnotation].fbUser objectForKey:kPicture];
	if ([photoLink isKindOfClass:[NSDictionary class]])
	{
		photoLink = [[[[self selectedUserAnnotation].fbUser objectForKey:kPicture] objectForKey:kData] objectForKey:kUrl];
	}
    NSString* fbid = [self selectedUserAnnotation].fbUserId;
    NSUInteger qbid = [self selectedUserAnnotation].qbUserID;
	

    self.quoteMark = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%u%@%@%@", fbidIdentifier, fbid,nameIdentifier, authorName, dateIdentifier, date, photoIdentifier, photoLink, qbidIdentifier, qbid, messageIdentifier, text, quoteDelimiter];
    
    
    // add Quote user photo
	quotePhotoTop = [[AsyncImageView alloc] initWithFrame:CGRectMake(-2, 0, 18, 18)];
	UITapGestureRecognizer* recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeQuote)];
	[quotePhotoTop addGestureRecognizer:recognizer];
    quotePhotoTop.clipsToBounds = YES;
    quotePhotoTop.layer.cornerRadius = 2;
	[recognizer release];
	UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
	[view addSubview:quotePhotoTop];
    [quotePhotoTop release];
	messageField.rightViewMode = UITextFieldViewModeAlways;
	messageField.rightView = view;
	[view release];
	[quotePhotoTop loadImageFromURL:[NSURL URLWithString:photoLink]];
}

- (void)refresh{
    
    [dataStorage refreshDataFromStorage];
	
	messagesTableView.delegate = self;
    messagesTableView.dataSource = self;
    [messagesTableView reloadData];
    [messagesTableView setUserInteractionEnabled:YES];
    
	isLoadingMoreMessages = NO;
}

- (void)getMoreMessages
{
	++page;
    
    [[BackgroundWorker instance] retrieveMoreChatMessages:page];
}


- (void)didSelectedQuote:(CustomButtonWithQuote *)sender
{
    UserAnnotation *annotation = [[UserAnnotation alloc] init];
    annotation.fbUserId = [sender.quote objectForKey:kFbID];
    annotation.qbUserID = [[sender.quote objectForKey:kQbID] integerValue];
    annotation.fbUser = [NSDictionary dictionaryWithObjectsAndKeys:[sender.quote objectForKey:kName], kName, [sender.quote objectForKey:kFbID], kId, [sender.quote objectForKey:kPhoto], kPicture, nil];
    annotation.userStatus = [sender.quote objectForKey:kMessage];
    annotation.userName = [sender.quote objectForKey:kName];
    annotation.createdAt = [sender.quote objectForKey:kDate];

    self.selectedUserAnnotation = annotation;
    [annotation release];
    
    // show action sheet   
    [super showActionSheetWithTitle:annotation.userName andSubtitle:annotation.userStatus];
}
#pragma mark -
#pragma mark Markers

/*
 Touch on marker
 */
- (void)touchOnMarker:(UIView *)marker{
    // get user name & id
    NSString *userName = nil;
    if([marker isKindOfClass:UITableViewCell.class]){ 
        userName = ((UILabel *)[marker viewWithTag:1105]).text;
        self.selectedUserAnnotation = [dataStorage retrieveDataFromStorageWithIndex:marker.tag];
    }
	
	NSString* title;
	NSString* subTitle;
	
	title = userName;
	if ([super.selectedUserAnnotation.userStatus length] >=6)
	{
		if ([[self.selectedUserAnnotation.userStatus substringToIndex:6] isEqualToString:fbidIdentifier])
		{
			subTitle = [self.selectedUserAnnotation.userStatus substringFromIndex:[self.selectedUserAnnotation.userStatus rangeOfString:quoteDelimiter].location+1];
		}
		else
		{
			subTitle = self.selectedUserAnnotation.userStatus;
		}
	}
	else
	{
		subTitle = self.selectedUserAnnotation.userStatus;
	}
	
	subTitle = [NSString stringWithFormat:@"''%@''", subTitle];
    
    // show action sheet
    [self showActionSheetWithTitle:title andSubtitle:subTitle];
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    // show back view
    if(backView == nil){
        backView = [[ViewTouch alloc] initWithFrame:CGRectMake(0, 44, 320, 154) selector:@selector(touchOnView:) target:self];
        [self.view addSubview:backView];
        [backView release];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [backView removeFromSuperview];
    backView = nil;
}

- (void)touchOnView:(UIView *)view{
    [messageField resignFirstResponder];
}


#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    UserAnnotation *currentAnnotation = [dataStorage retrieveDataFromStorageWithIndex:indexPath.row];
    
    // regular chat cell
	if ([currentAnnotation isKindOfClass:[UserAnnotation class]]){
		CGSize boundingSize = CGSizeMake(messageWidth-25, 10000000);
		
		CGSize itemFrameSize = [currentAnnotation.userStatus sizeWithFont:[UIFont systemFontOfSize:15]
								constrainedToSize:boundingSize
									lineBreakMode:UILineBreakModeWordWrap];
		
		if(itemFrameSize.height < 50){
			itemFrameSize.height = 50;
		}
		
        // if quote
		if ([currentAnnotation.quotedUserName length]){
			return itemFrameSize.height + 95;
		}
		
		return itemFrameSize.height + 45;
	
    // get more chat messages cell
    }else {
		return 60;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [dataStorage storageCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *friendsIds = [[DataManager shared].myFriendsAsDictionary allKeys];
    
    UserAnnotation *currentAnnotation = nil;
    
    if ([dataStorage storageCount] > [indexPath row]) {
        currentAnnotation = [dataStorage retrieveDataFromStorageWithIndex:indexPath.row];
    }
        
    if ([currentAnnotation isKindOfClass:[UITableViewCell class]]){
		return (UITableViewCell*)currentAnnotation;
	}

    // get height
    CGSize boundingSize = CGSizeMake(messageWidth-25, 10000000);
    
    CGSize itemFrameSize = [currentAnnotation.userStatus sizeWithFont:[UIFont systemFontOfSize:15]
                                             constrainedToSize:boundingSize
                                                 lineBreakMode:UILineBreakModeWordWrap];
    float textHeight = itemFrameSize.height + 7;
    
    static NSString *reuseIdentifier = @"ChatMessageCell";
    
    // create cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    AsyncImageView *userPhoto;
    UIImageView *messageBGView;
    UIImageView *distanceView;
    UILabel *distanceLabel;
    UITextView *userMessage;
    UILabel *userName;
    UILabel *datetime;
    CustomButtonWithQuote* quoteBG;
    AsyncImageView* quotedUserPhoto;
    UILabel* quotedMessageDate;
    UILabel* quotedMessageText;
    UILabel* quotedUserName;
    UIImageView* replyArrow;
    
    if(cell == nil){
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // quoted user's photo
        quotedUserPhoto = [[AsyncImageView alloc] init];
        quotedUserPhoto.layer.masksToBounds = YES;
        quotedUserPhoto.userInteractionEnabled =YES;
        quotedUserPhoto.tag = 1109;
        quotedUserPhoto.hidden = YES;
        [cell.contentView addSubview:quotedUserPhoto];
        [quotedUserPhoto release];
        
        // quoted message's creation date
        quotedMessageDate = [[UILabel alloc] init];
        quotedMessageDate.hidden = YES;
        quotedMessageDate.tag = 1111;
        [quotedMessageDate setTextAlignment:UITextAlignmentRight];
        [quotedMessageDate setFont:[UIFont systemFontOfSize:11]];
        [quotedMessageDate setTextColor:[UIColor grayColor]];
        quotedMessageDate.numberOfLines = 1;
        [quotedMessageDate setBackgroundColor:[UIColor clearColor]];
        [cell.contentView addSubview:quotedMessageDate];
        [quotedMessageDate release];
//        quotedMessageDate.layer.borderWidth = 1;
//        quotedMessageDate.layer.borderColor = [[UIColor redColor] CGColor];
        
        // quoted user name
        quotedUserName = [[UILabel alloc] init];
        quotedUserName.tag = 1112;
        quotedUserName.hidden = YES;
        [quotedUserName setFont:[UIFont boldSystemFontOfSize:11]];
        [quotedUserName setBackgroundColor:[UIColor clearColor]];
        [quotedUserName setTextColor:[UIColor grayColor]];
        [cell.contentView addSubview:quotedUserName];
        [quotedUserName release];
//        quotedUserName.layer.borderWidth = 1;
//        quotedUserName.layer.borderColor = [[UIColor redColor] CGColor];
        
        //
        // user photo
        userPhoto = [[AsyncImageView alloc] init];
        userPhoto.layer.masksToBounds = YES;
        userPhoto.userInteractionEnabled =YES;
        userPhoto.tag = 1101;
        [cell.contentView addSubview:userPhoto];
        [userPhoto release];
        
        // distance BG
        if([friendsIds containsObject:[currentAnnotation.fbUser objectForKey:kId]])
        {
            distanceView = [[UIImageView alloc] initWithImage:distanceImage];
        }
        else
        {
            distanceView = [[UIImageView alloc] initWithImage:distanceImage2];
        }
        distanceView.layer.masksToBounds = YES;
        distanceView.userInteractionEnabled = YES;
        distanceView.tag = 1106;
        [cell.contentView addSubview:distanceView];
        [distanceView release];
        
        // distance label
        distanceLabel = [[UILabel alloc] init];
        distanceLabel.tag = 1107;
        [distanceLabel setFont:[UIFont boldSystemFontOfSize:12]];
        distanceLabel.numberOfLines = 1;
        [distanceLabel setBackgroundColor:[UIColor clearColor]];
        [distanceLabel setTextColor:[UIColor whiteColor]];
        [distanceLabel setTextAlignment:UITextAlignmentCenter];
        [cell.contentView addSubview:distanceLabel];
        [distanceLabel release];
        
        // user message
        //
        // background
        
        messageBGView = [[UIImageView alloc] init];
        messageBGView.tag = 1102;
        
        if([friendsIds containsObject:[currentAnnotation.fbUser objectForKey:kId]])
        {
             [messageBGView setImage:messageBGImage];
        }
        else
        {
            [messageBGView setImage:messageBGImage2];
        }
        
         messageBGView.userInteractionEnabled =YES;
        [cell.contentView addSubview:messageBGView];
        [messageBGView release];
        //
        // label
        userMessage = [[UITextView alloc] init];
        userMessage.tag = 1103;
        [userMessage setFont:[UIFont systemFontOfSize:14]];
        userMessage.editable = NO;
        userMessage.scrollEnabled = NO;
        userMessage.dataDetectorTypes = UIDataDetectorTypeLink;
        [userMessage setBackgroundColor:[UIColor clearColor]];
        [messageBGView addSubview:userMessage];
        userMessage.contentInset = UIEdgeInsetsMake(-11,-8,0,-8);
        [userMessage release];
//        userMessage.layer.borderWidth = 1;
//        userMessage.layer.borderColor = [[UIColor redColor] CGColor];
        
        
        // datetime
        datetime = [[UILabel alloc] init];
        datetime.tag = 1104;
        [datetime setTextAlignment:UITextAlignmentRight];
        datetime.numberOfLines = 1;
        [datetime setFont:[UIFont systemFontOfSize:11]];
        [datetime setBackgroundColor:[UIColor clearColor]];
        [datetime setTextColor:[UIColor grayColor]];
        [cell.contentView addSubview:datetime];
        [datetime release];
//        datetime.layer.borderWidth = 1;
//        datetime.layer.borderColor = [[UIColor redColor] CGColor];
//        
        // label
        userName = [[UILabel alloc] init];
        userName.tag = 1105;
        [userName setFont:[UIFont boldSystemFontOfSize:11]];
        [userName setBackgroundColor:[UIColor clearColor]];
        [cell.contentView addSubview:userName];
        [userName release];
//        userName.layer.borderWidth = 1;
//        userName.layer.borderColor = [[UIColor redColor] CGColor];
        
        // quote BG
        quoteBG = [[CustomButtonWithQuote alloc] init];
        [quoteBG setBackgroundImage:[UIImage imageNamed:@"replyCellBodyBG.png"] forState:UIControlStateNormal];
        [quoteBG setBackgroundImage:[UIImage imageNamed:@"replyCellBodyBG_Pressed.png"] forState:UIControlStateHighlighted];
        quoteBG.tag = 1108;
        [quoteBG addTarget:self action:@selector(didSelectedQuote:) forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchUpInside];
        quoteBG.hidden = YES;
        [cell.contentView addSubview:quoteBG];
        [quoteBG release];
        
        // quoted message
        quotedMessageText = [[UILabel alloc] init];
        quotedMessageText.tag = 1110;
        quotedMessageText.hidden = YES;
        [quotedMessageText setFont:[UIFont systemFontOfSize:13]];
        [quotedMessageText setTextColor:[UIColor grayColor]];
        quotedMessageText.numberOfLines = 1;
        [quotedMessageText setBackgroundColor:[UIColor clearColor]];
        [quoteBG addSubview:quotedMessageText];
        [quotedMessageText release];
//        quotedMessageText.layer.borderWidth = 1;
//        quotedMessageText.layer.borderColor = [[UIColor redColor] CGColor];
        
        // add replay arroy
        replyArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"replyArrow.png"]];
        replyArrow.tag = 1113;
        replyArrow.userInteractionEnabled = YES;
        replyArrow.hidden = YES;
        [cell.contentView addSubview:replyArrow];
        [replyArrow release];

    }else{
        userPhoto = (AsyncImageView *)[cell.contentView viewWithTag:1101];
        messageBGView = (UIImageView *)[cell.contentView viewWithTag:1102];
        userMessage = (UITextView *)[messageBGView viewWithTag:1103];
        datetime = (UILabel *)[cell.contentView viewWithTag:1104];
        userName = (UILabel *)[cell.contentView viewWithTag:1105];
        distanceView = (UIImageView*)[cell.contentView viewWithTag:1106];
        distanceLabel = (UILabel*)[cell.contentView viewWithTag:1107];
        quoteBG = (CustomButtonWithQuote*)[cell.contentView viewWithTag:1108];
        quotedUserPhoto = (AsyncImageView*)[cell.contentView viewWithTag:1109];
        quotedMessageText = (UILabel*)[cell.contentView viewWithTag:1110];
        quotedMessageDate = (UILabel*)[cell.contentView viewWithTag:1111];
        quotedUserName = (UILabel*)[cell.contentView viewWithTag:1112];
        replyArrow = (UIImageView*)[cell.contentView viewWithTag:1113];
        
        if([friendsIds containsObject:[currentAnnotation.fbUser objectForKey:kId]])
        {
            [messageBGView setImage:messageBGImage];
            [distanceView setImage:distanceImage];
        }
        else
        {
            [messageBGView setImage:messageBGImage2];
            [distanceView setImage:distanceImage2];
        }
    }
    
    int shift = 0;
    
    // hide quote views
    if ([currentAnnotation.quotedUserName length]){
        quoteBG.hidden = NO;
        quotedUserName.hidden = NO;
        quotedMessageDate.hidden = NO;
        quotedMessageText.hidden = NO;
        quotedUserPhoto.hidden = NO;
        replyArrow.hidden = NO;
        
        shift = 50;
    }else{
        quoteBG.hidden = YES;
        quotedUserName.hidden = YES;
        quotedMessageDate.hidden = YES;
        quotedMessageText.hidden = YES;
        quotedUserPhoto.hidden = YES;
        replyArrow.hidden = YES;
    }
    
    
    
    // set user photo
    [userPhoto setFrame:CGRectMake(5, 5+shift, 50, 50)];
	
	id picture = currentAnnotation.userPhotoUrl;
	if ([picture isKindOfClass:[NSString class]])
	{
		[userPhoto loadImageFromURL:[NSURL URLWithString:currentAnnotation.userPhotoUrl]];
	}
	else
	{
		NSDictionary* pic = (NSDictionary*)picture;
		NSString* url = [[pic objectForKey:kData] objectForKey:kUrl];
		[userPhoto loadImageFromURL:[NSURL URLWithString:url]];
		currentAnnotation.userPhotoUrl = url;
	}
    
    // set distance bg
    [distanceView setFrame:CGRectMake(5, userPhoto.frame.origin.y+userPhoto.frame.size.height, 50, 25)];
    
    // distance label
    [distanceLabel setFrame:CGRectMake(5, distanceView.frame.origin.y+5, 50, 15)];
    if ([[DataManager shared].currentFBUserId isEqualToString:[currentAnnotation.fbUser objectForKey:kId]]){
        
        distanceLabel.hidden = YES;
        distanceView.hidden = YES;
        
        [messageBGView setImage:messageBGImage];

    }else{
        if(currentAnnotation.distance < 0){
            distanceLabel.hidden = YES;
            distanceView.hidden = YES;
            
        }else{
            distanceLabel.hidden = NO;
            distanceView.hidden = NO;
            
            if (currentAnnotation.distance > 1000){
                if(currentAnnotation.distance/1000 > 10000){
                    [distanceLabel setFont:[UIFont boldSystemFontOfSize:10]];
                }else{
                    [distanceLabel setFont:[UIFont boldSystemFontOfSize:12]];
                }
                distanceLabel.text = [NSString stringWithFormat:@"%i km", currentAnnotation.distance/1000];
            } else if(currentAnnotation.distance == 0){
                 distanceLabel.text = [NSString stringWithFormat:@"-"];
            }else{
                distanceLabel.text = [NSString stringWithFormat:@"%i m", currentAnnotation.distance];
            }
        }
    }

    // set bg
    [messageBGView setFrame:CGRectMake(62, 5+shift, messageWidth, textHeight+15)];
    
    // set message
    [userMessage setFrame:CGRectMake(21, 22, messageBGView.frame.size.width-24, messageBGView.frame.size.height-26)];
    userMessage.text = currentAnnotation.userStatus;
//    [userMessage sizeToFit];
    
    // sate date
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setLocale:[NSLocale currentLocale]];
    formatter.timeZone = [NSTimeZone systemTimeZone];
    [formatter setDateFormat:@"d MMMM HH:mm"];
    datetime.text = [formatter stringFromDate:currentAnnotation.createdAt];
    [datetime setFrame:CGRectMake(messageWidth-41, 11+shift, 101, 12)];
    [formatter release];
    
    // set user name
    [userName setFrame:CGRectMake(83, 10+shift, 125, 12)];
    userName.text = currentAnnotation.userName;
    
    // set quote BG
    [quoteBG setFrame:CGRectMake(messageBGView.frame.origin.x+15, 5, 250, 70)];
    [cell.contentView insertSubview:quoteBG belowSubview:messageBGView];
    //
    if (currentAnnotation.quotedUserFBId){
        [quoteBG.quote setObject:currentAnnotation.quotedUserFBId forKey:kFbID];
    }
    if (currentAnnotation.quotedUserQBId){
        [quoteBG.quote setObject:currentAnnotation.quotedUserQBId forKey:kQbID];
    }
    if (currentAnnotation.quotedUserName){
        [quoteBG.quote setObject:currentAnnotation.quotedUserName forKey:kName];
    }
    if (currentAnnotation.quotedMessageText){
        [quoteBG.quote setObject:currentAnnotation.quotedMessageText forKey:kMessage];
    }
    if (currentAnnotation.quotedUserPhotoURL){
        [quoteBG.quote setObject:currentAnnotation.quotedUserPhotoURL forKey:kPhoto];
    }
    if (currentAnnotation.quotedMessageDate){
        [quoteBG.quote setObject:currentAnnotation.quotedMessageDate forKey:kDate];
    }
    
    // set quoted user's photo
    [quotedUserPhoto setFrame:CGRectMake(quoteBG.frame.origin.x+22, quoteBG.frame.origin.y+8, 20, 20)];
    [cell.contentView bringSubviewToFront:quotedUserPhoto];
    if ([currentAnnotation.quotedUserPhotoURL length]){
        [quotedUserPhoto loadImageFromURL:[NSURL URLWithString:currentAnnotation.quotedUserPhotoURL]];
    }
    
    // set date of quoted message
    [quotedMessageDate setFrame:CGRectMake(messageWidth-30, quoteBG.frame.origin.y+12, 90, 12)];
    NSDateFormatter* qformatter = [[NSDateFormatter alloc] init];
	[qformatter setLocale:[NSLocale currentLocale]];
    [qformatter setDateFormat:@"d MMMM HH:mm"];
    qformatter.timeZone = [NSTimeZone systemTimeZone];
    quotedMessageDate.text = [qformatter stringFromDate:currentAnnotation.quotedMessageDate];
    [cell.contentView bringSubviewToFront:quotedMessageDate];
    [qformatter release];
    
    // set quoted user name
    [quotedUserName setFrame:CGRectMake(quotedUserPhoto.frame.origin.x+26, quotedUserPhoto.frame.origin.y+5, 95, 12)];
    quotedUserName.text = currentAnnotation.quotedUserName;
    [cell.contentView bringSubviewToFront:quotedUserName];
    
    // set quoted message's text
    [quotedMessageText setFrame:CGRectMake(22, quoteBG.frame.origin.y+25, 200, 20)];
    quotedMessageText.text = currentAnnotation.quotedMessageText;
    
    // add reply arrow
    [replyArrow setFrame:CGRectMake(72, 24, 11, 14)];
    [cell.contentView bringSubviewToFront:replyArrow];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.tag = [indexPath row];
    [self performSelector:@selector(touchOnMarker:) withObject:cell];
}

#pragma mark -
#pragma mark UIScrollViewDelegate

// Get More messages feature
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(messagesTableView.tag == tableIsUpdating){
        return;
    }
    CGFloat thresholdToAction = [messagesTableView contentSize].height-300;
		
    if (([scrollView contentOffset].y >= thresholdToAction) && !isLoadingMoreMessages) {

		isLoadingMoreMessages = YES;
		
        // add load cell 
		UITableViewCell* cell = [[UITableViewCell alloc] init];
		UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(150, 7, 20, 20)];
		[loading setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
		[loading startAnimating];
		[cell.contentView addSubview:loading];
//		[[DataManager shared].chatPoints addObject:cell];
//        [dataStorage addDataToStorage:cell];
        [cell release];
		[loading release];
		//
		[messagesTableView reloadData];
		
        // get more messages
		[self getMoreMessages];
    }
}

#pragma mark -
#pragma mark Notifications Reaction

-(void)doUpdateChatRoomsController:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        [messagesTableView reloadData];
    }
}

-(void)doClearCache{
    showAllUsers  = NO;
    
    [self.allFriendsSwitch setValue:1.0f];
    isDataRetrieved = NO;
    
    [self.messageField setText:nil];
    [self.messagesTableView reloadData];
}

-(void)doChatNotReceiveNewFBChatUsers:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        [(UIActivityIndicatorView*)([self.view viewWithTag:INDICATOR_TAG]) removeFromSuperview];
        [self refresh];
        
        if ([self.allFriendsSwitch value] == friendsValue) {
            [self showFriends];
        }
        else
            [self showWorld];
    }
    
}

-(void)doReceiveUserProfilePictures:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier] &&
                        [self.controllerReuseIdentifier isEqualToString:chatRoomsViewControllerIdentifier]
                        && !isPanelDisplayed) {
        [self addUserPicturesToPanel];
        isPanelDisplayed = YES;
    }
}

-(void)doWillSetAllFriendsSwitchEnabled:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        BOOL enabled = [[[notification userInfo] objectForKey:@"switchEnabled"] boolValue];
        [self.allFriendsSwitch setEnabled:enabled];
    }
}

-(void)doWillSetMessageFieldEnabled:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];

    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        BOOL enabled = [[[notification userInfo] objectForKey:@"messageFieldEnabled"] boolValue];
        [messageField setEnabled:enabled];
    }
}

-(void)doShowAllFriends{
    [self showWorld];
}
-(void)doSuccessfulMessageSending:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        [sendMessageActivityIndicator stopAnimating];
        messageField.rightView = nil;
        quotePhotoTop = nil;
    }
}

-(void)doChatEndRetrievingData:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];

    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        messageField.enabled = YES;
        isDataRetrieved = YES;
        
        [self.allFriendsSwitch setEnabled:YES];
        [(UIActivityIndicatorView*)([self.view viewWithTag:INDICATOR_TAG]) removeFromSuperview];
        
        [self refresh];
        
        if ([self.allFriendsSwitch value] == friendsValue) {
            [self showFriends];
        }
        else
            [self showWorld];
    }
    
    if ([context isEqualToString:chatRoomsViewControllerIdentifier]) {
        [[BackgroundWorker instance] requestMessagesRecipientsPictures];
    }
}

-(void)doUpdate:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        [self refresh];
    }
}

-(void)doScrollToTop:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
                // if this is action not for this controller skip it
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        // scroll to top
        if([dataStorage storageCount] > 0){
            [messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }

    }
}

-(void)doClearMessageField:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        // clear text
        messageField.text = @"";
        [messageField resignFirstResponder];
    }
}

-(void)doAddNewPointToChat:(NSNotification*) notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        
        UserAnnotation* message = [notification.userInfo objectForKey:@"newMessage"];
        BOOL toTop = [[notification.userInfo objectForKey:@"addToTop"] boolValue];
        BOOL reloadTable = [[notification.userInfo objectForKey:@"reloadTable"] boolValue];
        BOOL isFBCheckin = [[notification.userInfo objectForKey:@"isFBCheckin"] boolValue];
        self.messagesTableView.tag = tableIsUpdating;

        [self addMessageToChatTable:message toTableTop:toTop withReloadTable:reloadTable];

            
        if(message.geoDataID != -1 && [self.controllerReuseIdentifier isEqualToString:chatViewControllerIdentifier]){
            [[DataManager shared].chatMessagesIDs addObject:[NSString stringWithFormat:@"%d", message.geoDataID]];
        }
        
        
        // Save to cache
        //
        if(!isFBCheckin && [dataStorage needsCaching] && [dataStorage isKindOfClass:[ChatPointsStorage class]]){
            [[DataManager shared] addChatMessageToStorage:message];
        }


        
        self.messagesTableView.tag = 0;
        [self.messagesTableView reloadData];
    }
}

-(void)doRemoveLastChatPoint:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];

    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        if ([dataStorage storageCount] != 0) {
            [dataStorage removeLastObjectFromStorage];
        }
    }
    
}

-(void)doNotReceiveNewChatPoints:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        [dataStorage removeLastObjectFromStorage];
        [messagesTableView reloadData];
        isLoadingMoreMessages = NO;
    }
}

-(void)doReceiveErrorLoadingNewChatPoints:(NSNotification*)notification{
    NSString* context = [notification.userInfo objectForKey:@"context"];
    
    if ([context isEqualToString:self.controllerReuseIdentifier]) {
        [messagesTableView reloadData];
    }
}

- (void)logoutDone{
    showAllUsers  = NO;
    
    [self.allFriendsSwitch setValue:1.0f];
    isDataRetrieved = NO;
    
    [self.messageField setText:nil];
    
    [self.messagesTableView reloadData];
    [self clear];
}

-(void)clear{
    [dataStorage clearStorage];
    
    [[DataManager shared].myFriends removeAllObjects];
    [[DataManager shared].myPopularFriends removeAllObjects];
    [[DataManager shared].myFriendsAsDictionary removeAllObjects];

}

#pragma mark -
#pragma mark Helpers
- (BOOL)isAllShowed{
    if(self.allFriendsSwitch.value >= worldValue){
        return YES;
    }
    
    return NO;
}
#pragma mark -
#pragma mark ActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    int buttonsNum = actionSheet.numberOfButtons;
    
    switch (buttonIndex) {
        case 0:{
            // quote action
            [self addQuote];
            [self.messageField becomeFirstResponder];
        }
            
            break;
            
        case 1: {
            if(buttonsNum == 3){
                // View personal FB page
                [super actionSheetViewFBProfile];
            }else{
                // Send FB message
                [super actionSheetSendPrivateFBMessage];
            }
        }
            break;
            
        case 2: {
            // View personal FB page
            if(buttonsNum != 3){
                [self actionSheetViewFBProfile];
            }
        }
			
            break;
            
        default:
            break;
    }
    
    [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
}
@end
