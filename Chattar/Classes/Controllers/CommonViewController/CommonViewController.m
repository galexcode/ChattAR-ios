//
//  CommonViewController.m
//  Chattar
//
//  Created by kirill on 2/19/13.
//
//

#import "CommonViewController.h"

@interface CommonViewController ()

@end

@implementation CommonViewController
@synthesize allFriendsSwitch;
@synthesize loadingIndicator = _loadingIndicator;
@synthesize selectedUserAnnotation;
@synthesize userActionSheet;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        showAllUsers = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doReceiveError:) name:kDidReceiveError object:nil ];
    }
    return self;
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [selectedUserAnnotation release];
    [_loadingIndicator release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Interface based methods

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


- (void)allFriendsSwitchValueDidChanged:(id)sender{
    float origValue = [(CustomSwitch *)sender value];
    int stateValue = 0;
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
    // subclassses should override this method
}

-(void)showFriends{
    // subclassses should override this method
}

#pragma mark - 
#pragma mark UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    // subclass should perform some actions
    [userActionSheet release];
    userActionSheet = nil;
    
    self.selectedUserAnnotation = nil;
}

- (void)actionSheetViewFBProfile{
    // View personal FB page
    NSString *url = [NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@",self.selectedUserAnnotation.fbUserId];
    
    WebViewController *webViewControleler = [[WebViewController alloc] init];
    webViewControleler.urlAdress = url;
    [self.navigationController pushViewController:webViewControleler animated:YES];
    [webViewControleler autorelease];
}

- (void) actionSheetSendPrivateFBMessage{
    NSString *selectedFriendId = self.selectedUserAnnotation.fbUserId;
    
    // get conversation
    Conversation *conversation = [[DataManager shared].historyConversation objectForKey:selectedFriendId];
    if(conversation == nil){
        // 1st message -> create conversation
        
        Conversation *newConversation = [[Conversation alloc] init];
        
        // add to
        NSMutableDictionary *to = [NSMutableDictionary dictionary];
        [to setObject:selectedFriendId forKey:kId];
        [to setObject:[self.selectedUserAnnotation.fbUser objectForKey:kName] forKey:kName];
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
#pragma mark Notifications Reactions
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

@end
