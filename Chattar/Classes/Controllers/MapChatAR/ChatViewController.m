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

@synthesize userActionSheet;
@synthesize selectedUserAnnotation;
@synthesize allFriendsSwitch;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.title = NSLocalizedString(@"Chat", nil);
		self.tabBarItem.image = [UIImage imageNamed:@"chatTab.png"];

                    // logout
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutDone) name:kNotificationLogout object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doUpdate) name:kWillUpdate object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doScrollToTop) name:kWillScrollToTop object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doClearMessageField) name:kWillClearMessageField object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doRemoveLastChatPoint) name:kWillRemoveLastChatPoint object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doAddNewPointToChat:) name:kWillAddNewMessageToChat object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveError:) name:kDidReceiveError object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNotReceiveNewChatPoints) name:kDidNotReceiveNewChatPoints object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveErrorLoadingNewChatPoints) name:kdidReceiveErrorLoadingNewChatPoints object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doSuccessfulMessageSending) name:kDidSuccessfulMessageSending object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doShowAllFriends) name:kWillShowAllFriends object:nil ];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doChatEndRetrievingData) name:kChatEndOfRetrievingInitialData object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doWillSetAllFriendsSwitchEnabled:) name:kWillSetAllFriendsSwitchEnabled object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doWillSetMessageFieldEnabled:) name:kWillSetMessageFieldEnabled object:nil ];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doChatNotReceiveNewFBChatUsers) name:kDidNotReceiveNewFBChatUsers object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doClearCache) name:kDidClearCache object:nil];
        
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
    
    allFriendsSwitch = [CustomSwitch customSwitch];
    [allFriendsSwitch setAutoresizingMask:(UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin)];
    
    if(IS_HEIGHT_GTE_568){
        [allFriendsSwitch setCenter:CGPointMake(280, 448)];
    }else{
        [allFriendsSwitch setCenter:CGPointMake(280, 360)];
    }
    
    [allFriendsSwitch setValue:worldValue];
    [allFriendsSwitch scaleSwitch:0.9];
    [allFriendsSwitch addTarget:self action:@selector(allFriendsSwitchValueDidChanged:) forControlEvents:UIControlEventValueChanged];
	[allFriendsSwitch setBackgroundColor:[UIColor clearColor]];
	[self.view addSubview:allFriendsSwitch];
    
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
    if ([DataManager shared].isFirstStartApp) {
        [[DataManager shared] setFirstStartApp:NO];
        
        [self addSpinner];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    if (![self presentedViewController]) {
        [self checkForShowingData];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_loadingIndicator release];
    [super dealloc];
}

#pragma mark -
#pragma mark Interface based methods

-(void)checkForShowingData{
    if ([DataManager shared].chatPoints.count == 0 && [DataManager shared].chatMessagesIDs.count == 0) {
        [messagesTableView reloadData];
        [[BackgroundWorker instance] retrieveCachedChatDataAndRequestNewData];
        [[BackgroundWorker instance] retrieveCachedFBCheckinsAndRequestNewCheckins];
        [self addSpinner];
    }
    else{
        if ([allFriendsSwitch value] == friendsValue) {
            [self showFriends];
        }
        else
            [self showWorld];
    }
}

-(void)addSpinner{
    if (!_loadingIndicator) {
        _loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    if (![self.view viewWithTag:INDICATOR_TAG]) {
        [self.view addSubview:_loadingIndicator];
    }
    _loadingIndicator.center = self.view.center;
    [self.view bringSubviewToFront:_loadingIndicator];
    
    [_loadingIndicator startAnimating];
    [_loadingIndicator setTag:INDICATOR_TAG];
}

- (IBAction)sendMessageDidPress:(id)sender{
    
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
    
	QBLGeoData *geoData = [QBLGeoData currentGeoData];
    if(geoData.latitude == 0 && geoData.longitude == 0){
        CLLocationManager *locationManager = [[[CLLocationManager alloc] init] autorelease];
        [geoData setLatitude:locationManager.location.coordinate.latitude];
        [geoData setLongitude:locationManager.location.coordinate.longitude];
    }
	geoData.user = [DataManager shared].currentQBUser;
	
    // set body - with quote or without
	if (quoteMark){
		geoData.status = [quoteMark stringByAppendingString:messageField.text];
	}else {
		geoData.status = messageField.text;
	}

    [[BackgroundWorker instance] postGeoData:geoData];

	// send push notification if this is quote
	if (quoteMark){
        
        // search QB User by fb ID
        NSString *fbUserID = [[geoData.status substringFromIndex:6] substringToIndex:[self.quoteMark rangeOfString:nameIdentifier].location-6];
        
        [[BackgroundWorker instance] requestFriendWithFacebookID:fbUserID andMessageText:messageField.text];        
	}
    
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

- (void)allFriendsSwitchValueDidChanged:(id)sender{
    
    // switch All/Friends
    float origValue = [(CustomSwitch *)sender value];
    int stateValue;
    if(origValue >= worldValue){
        stateValue = 1;
    }else if(origValue <= friendsValue){
        stateValue = 0;
    }
    
    switch (stateValue) {
            // show Friends
        case 0:{
            if(!showAllUsers){
                [self showFriends];
                showAllUsers = YES;
            }
        }
            break;
            
            // show World
        case 1:{
            if(showAllUsers){
                [self showWorld];
                showAllUsers = NO;
            }
        }
            break;
    }
}

-(void)showWorld{
    [[DataManager shared].chatPoints removeAllObjects];
    //
    // 2. add Friends from FB
    [[DataManager shared].chatPoints addObjectsFromArray:[DataManager shared].allChatPoints];
    
    
    // add all checkins
    for(UserAnnotation *checkinAnnotatin in [DataManager shared].allCheckins){
        if(![[DataManager shared].chatPoints containsObject:checkinAnnotatin]){
            [[DataManager shared].chatPoints addObject:checkinAnnotatin];
        }
    }
    
    [self refresh];
}

-(void)showFriends{
    NSMutableArray *friendsIds = [[[DataManager shared].myFriendsAsDictionary allKeys] mutableCopy];
    [friendsIds addObject:[DataManager shared].currentFBUserId];// add me
    
    // Chat points
    //
    [[DataManager shared].chatPoints removeAllObjects];
    //
    // add only friends QB points
    for(UserAnnotation *mapAnnotation in [DataManager shared].allChatPoints){
        if([friendsIds containsObject:[mapAnnotation.fbUser objectForKey:kId]]){
            [[DataManager shared].chatPoints addObject:mapAnnotation];
        }
    }
    [friendsIds release];
    //
    // add all checkins
    for(UserAnnotation *checkinAnnotatin in [DataManager shared].allCheckins){
        if(![[DataManager shared].chatPoints containsObject:checkinAnnotatin]){
            [[DataManager shared].chatPoints addObject:checkinAnnotatin];
        }
    }
    
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

    // add new
    // sort chat messaged due to created date
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"createdAt" ascending: NO] autorelease];
	NSArray* sortedArray = [[DataManager shared].chatPoints sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

	[[DataManager shared].chatPoints removeAllObjects];
	[[DataManager shared].chatPoints addObjectsFromArray:sortedArray];
	
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
    [self showActionSheetWithTitle:annotation.userName andSubtitle:annotation.userStatus];
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
        self.selectedUserAnnotation = [[DataManager shared].chatPoints objectAtIndex:marker.tag];
    }
	
	NSString* title;
	NSString* subTitle;
	
	title = userName;
	if ([selectedUserAnnotation.userStatus length] >=6)
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

- (void)showActionSheetWithTitle:(NSString *)title andSubtitle:(NSString *)subtitle
{
    // check yourself
    if([selectedUserAnnotation.fbUserId isEqualToString:[DataManager shared].currentFBUserId]){
        return;
    }
    
    // is this friend?
    BOOL isThisFriend = YES;
    if(![[[DataManager shared].myFriendsAsDictionary allKeys] containsObject:selectedUserAnnotation.fbUserId]){
        isThisFriend = NO;
    }
    
    
    // show Action Sheet
    //
    // add "Quote" item only in Chat
    if(isThisFriend){
        userActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"Reply with quote", nil), NSLocalizedString(@"Send private FB message", nil), NSLocalizedString(@"View FB profile", nil), nil];
    }else{
        userActionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"Reply with quote", nil), NSLocalizedString(@"View FB profile", nil), nil];
    }

	UILabel* titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, 280, 15)];
	titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
	titleLabel.textAlignment = UITextAlignmentCenter;
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.textColor = [UIColor whiteColor];
	titleLabel.text = title;
	titleLabel.numberOfLines = 0;
	[userActionSheet addSubview:titleLabel];
	
	UILabel* subTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 280, 55)];
	subTitleLabel.font = [UIFont boldSystemFontOfSize:12.0];
	subTitleLabel.textAlignment = UITextAlignmentCenter;
	subTitleLabel.backgroundColor = [UIColor clearColor];
	subTitleLabel.textColor = [UIColor whiteColor];
	subTitleLabel.text = subtitle;
	subTitleLabel.numberOfLines = 0;
	[userActionSheet addSubview:subTitleLabel];
	
	[subTitleLabel release];
	[titleLabel release];
	userActionSheet.title = @"";
    
	// Show
	[userActionSheet showFromTabBar:self.tabBarController.tabBar];
	
	CGRect actionSheetRect = userActionSheet.frame;
	actionSheetRect.origin.y -= 60.0;
	actionSheetRect.size.height = 300.0;
	[userActionSheet setFrame:actionSheetRect];
	
	for (int counter = 0; counter < [[userActionSheet subviews] count]; counter++)
	{
		UIView *object = [[userActionSheet subviews] objectAtIndex:counter];
		if (![object isKindOfClass:[UILabel class]])
		{
			CGRect frame = object.frame;
			frame.origin.y = frame.origin.y + 60.0;
			object.frame = frame;
		}
	}
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
    UserAnnotation *currentAnnotation = [[DataManager shared].chatPoints objectAtIndex:[indexPath row]];
    
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
    return [DataManager shared].chatPoints.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSArray *friendsIds = [[DataManager shared].myFriendsAsDictionary allKeys];
    
    UserAnnotation *currentAnnotation = nil;
    if ([DataManager shared].chatPoints.count > [indexPath row]) {
        currentAnnotation = [[DataManager shared].chatPoints objectAtIndex:[indexPath row]];
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
		[[DataManager shared].chatPoints addObject:cell];
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

-(void)doClearCache{
    showAllUsers  = NO;
    
    [self.allFriendsSwitch setValue:1.0f];
    isDataRetrieved = NO;
    
    [self.messageField setText:nil];
    [self.messagesTableView reloadData];
}

-(void)doChatNotReceiveNewFBChatUsers{
    [(UIActivityIndicatorView*)([self.view viewWithTag:INDICATOR_TAG]) removeFromSuperview];
    [self refresh];
    
    if ([allFriendsSwitch value] == friendsValue) {
        [self showFriends];
    }
    else
        [self showWorld];

}

-(void)doWillSetAllFriendsSwitchEnabled:(NSNotification*)notification{
    BOOL enabled = [[[notification userInfo] objectForKey:@"switchEnabled"] boolValue];
    [allFriendsSwitch setEnabled:enabled];
}

-(void)doWillSetMessageFieldEnabled:(NSNotification*)notification{
    BOOL enabled = [[[notification userInfo] objectForKey:@"messageFieldEnabled"] boolValue];
    [messageField setEnabled:enabled];
}

-(void)doShowAllFriends{
    [self showWorld];
}
-(void)doSuccessfulMessageSending{
    [sendMessageActivityIndicator stopAnimating];
    messageField.rightView = nil;
    quotePhotoTop = nil;
}

-(void)doChatEndRetrievingData{
    messageField.enabled = YES;
    isDataRetrieved = YES;
            
    [allFriendsSwitch setEnabled:YES];
    [(UIActivityIndicatorView*)([self.view viewWithTag:INDICATOR_TAG]) removeFromSuperview];
    
    [self refresh];
    
    if ([allFriendsSwitch value] == friendsValue) {
        [self showFriends];
    }
    else
        [self showWorld];

}

-(void)doUpdate{
    [self refresh];
}

-(void)doScrollToTop{
    // scroll to top
    if([DataManager shared].chatPoints.count > 0){
        [messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

-(void)doClearMessageField{
    // clear text
    messageField.text = @"";
    [messageField resignFirstResponder];
}

-(void)doAddNewPointToChat:(NSNotification*) notification{
    UserAnnotation* message = [notification.userInfo objectForKey:@"newMessage"];
    BOOL toTop = [[notification.userInfo objectForKey:@"addToTop"] boolValue];
    BOOL reloadTable = [[notification.userInfo objectForKey:@"reloadTable"] boolValue];
    BOOL isFBCheckin = [[notification.userInfo objectForKey:@"isFBCheckin"] boolValue];
    self.messagesTableView.tag = tableIsUpdating;

    if(message.geoDataID != -1){
       [[DataManager shared].chatMessagesIDs addObject:[NSString stringWithFormat:@"%d", message.geoDataID]];
    }

    NSArray *friendsIds = [[DataManager shared].myFriendsAsDictionary allKeys];

    // Add to Chat
    __block BOOL addedToCurrentChatState = NO;
    
    dispatch_async( dispatch_get_main_queue(), ^{

        // New messages
        if (toTop){
            [[DataManager shared].allChatPoints insertObject:message atIndex:0];
            if([self isAllShowed] || [friendsIds containsObject:message.fbUserId] ||
               [message.fbUserId isEqualToString:[DataManager shared].currentFBUserId]){
                [[DataManager shared].chatPoints insertObject:message atIndex:0];
                addedToCurrentChatState = YES;
            }

            // old messages
        }else {
            [[DataManager shared].allChatPoints insertObject:message atIndex:[[DataManager shared].allChatPoints count] > 0 ?
                                                                            ([[DataManager shared].allChatPoints count]-1) : 0];
            if([self isAllShowed] || [friendsIds containsObject:message.fbUserId] ||
               [message.fbUserId isEqualToString:[DataManager shared].currentFBUserId]){
                [[DataManager shared].chatPoints insertObject:message atIndex:[[DataManager shared].chatPoints count] > 0 ? ([[DataManager shared].chatPoints count]-1) : 0];
                addedToCurrentChatState = YES;
            }
        }
        //
        if(addedToCurrentChatState && reloadTable){
            // on main thread

            [self.messagesTableView reloadData];

        }
    });

    // Save to cache
    //
    if(!isFBCheckin){
        [[DataManager shared] addChatMessageToStorage:message];
    }
    
    self.messagesTableView.tag = 0;

}

-(void)doRemoveLastChatPoint{
    if ([DataManager shared].chatPoints.count != 0) {
        [[DataManager shared].chatPoints removeLastObject];

    }
}

-(void)doReceiveError:(NSNotification*)notification{
    NSString* errorMessage = [notification.userInfo objectForKey:@"errorMessage"];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Errors", nil)
                                                    message:errorMessage
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
                        // remove loading indicator 
    if ([self.view viewWithTag:INDICATOR_TAG]) {
        [[self.view viewWithTag:INDICATOR_TAG] removeFromSuperview];
    }
}

-(void)doNotReceiveNewChatPoints{
    [[DataManager shared].chatPoints removeLastObject];
    [messagesTableView reloadData];
    isLoadingMoreMessages = NO;
}

-(void)doReceiveErrorLoadingNewChatPoints{
    [messagesTableView reloadData];
}

- (void)logoutDone{
    showAllUsers  = NO;
    
    [self.allFriendsSwitch setValue:1.0f];
    isDataRetrieved = NO;
    
    [self.messageField setText:nil];
    
    [[DataManager shared].allChatPoints removeAllObjects];
    [[DataManager shared].chatPoints removeAllObjects];
    [[DataManager shared].chatMessagesIDs removeAllObjects];
    
    [[DataManager shared].myFriends removeAllObjects];
    [[DataManager shared].myPopularFriends removeAllObjects];
    [[DataManager shared].myFriendsAsDictionary removeAllObjects];


    [self.messagesTableView reloadData];
}


#pragma mark -
#pragma mark Helpers
- (BOOL)isAllShowed{
    if(allFriendsSwitch.value >= worldValue){
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
                [self actionSheetViewFBProfile];
            }else{
                // Send FB message
                [self actionSheetSendPrivateFBMessage];
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
    
    [userActionSheet release];
    userActionSheet = nil;
    
    self.selectedUserAnnotation = nil;
}

- (void)actionSheetViewFBProfile{
    // View personal FB page
    
    NSString *url = [NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@",selectedUserAnnotation.fbUserId];
    
    WebViewController *webViewControleler = [[WebViewController alloc] init];
    webViewControleler.urlAdress = url;
    [self.navigationController pushViewController:webViewControleler animated:YES];
    [webViewControleler autorelease];
}

- (void) actionSheetSendPrivateFBMessage{
    NSString *selectedFriendId = selectedUserAnnotation.fbUserId;
    
    // get conversation
    Conversation *conversation = [[DataManager shared].historyConversation objectForKey:selectedFriendId];
    if(conversation == nil){
        // 1st message -> create conversation
        
        Conversation *newConversation = [[Conversation alloc] init];
        
        // add to
        NSMutableDictionary *to = [NSMutableDictionary dictionary];
        [to setObject:selectedFriendId forKey:kId];
        [to setObject:[selectedUserAnnotation.fbUser objectForKey:kName] forKey:kName];
        newConversation.to = to;
        
        // add messages
        NSMutableArray *emptryArray = [[NSMutableArray alloc] init];
        newConversation.messages = emptryArray;
        [emptryArray release];
        
        [[DataManager shared].historyConversation setObject:newConversation forKey:selectedFriendId];
        [newConversation release];
        
        conversation = newConversation;
    }
    
    // show Chat
    FBChatViewController *chatController = [[FBChatViewController alloc] initWithNibName:@"FBChatViewController" bundle:nil];
    chatController.chatHistory = conversation;
    [self.navigationController pushViewController:chatController animated:YES];
    [chatController release];
    
}


@end
