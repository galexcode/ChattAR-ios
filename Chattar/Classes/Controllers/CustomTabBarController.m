
//
//  CustomTabBarController.m
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import "CustomTabBarController.h"
#import "AppDelegate.h"
@interface CustomTabBarController ()

@end


@implementation CustomTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestFBInfo:) name:@"splashScreenDidHide" object:nil];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

-(void)requestFBInfo:(NSNotification*) notification{
    [[BackgroundWorker instance] setTabBarDelegate:self];
    [[BackgroundWorker instance] requestFBInfo];
}

-(void)didReceivePopularFriends:(NSMutableSet*)popFriends{
    [DataManager shared].myPopularFriends = popFriends.mutableCopy;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GeneralDataFinishLoading" object:nil];
}

-(void)didReceiveInboxMessages:(NSDictionary *)inboxMessages{
    [DataManager shared].historyConversation = inboxMessages.mutableCopy;
    [DataManager shared].historyConversationAsArray = inboxMessages.allValues.mutableCopy;
    
    [[BackgroundWorker instance] requestFriends];
}

-(void)didReceiveAllFriends:(NSArray*)allFriends{
    [DataManager shared].myFriends = [allFriends mutableCopy];
    NSLog(@"%@",[DataManager shared].myFriends);
    [[DataManager shared] makeFriendsDictionary];
    
    [[BackgroundWorker instance] requestPopularFriends];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
