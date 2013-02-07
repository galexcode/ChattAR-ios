
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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Data requests

-(void)requestFBInfo:(NSNotification*) notification{
    [[BackgroundWorker instance] setTabBarDelegate:self];
    [[BackgroundWorker instance] requestFBHistory];
    [[BackgroundWorker instance] requestFriends];
}

-(void)requestControllerData{
    [[BackgroundWorker instance] retrieveCachedChatDataAndRequestNewData];
    [[BackgroundWorker instance] retrieveCachedMapDataAndRequestNewData];
}

#pragma mark - 
#pragma mark General data saving

-(void)didReceivePopularFriends:(NSMutableSet*)popFriends{
    if (![[DataManager shared] myPopularFriends]) {
        [DataManager shared].myPopularFriends = popFriends.mutableCopy;
    }
    else{
        [[DataManager shared].myPopularFriends addObjectsFromArray:popFriends.allObjects];
    }
    
    [self requestControllerData];
}

-(void)didReceiveInboxMessages:(NSDictionary *)inboxMessages andPopularFriends:(NSSet *)popFriends{
    [DataManager shared].historyConversation = inboxMessages.mutableCopy;
    [DataManager shared].historyConversationAsArray = inboxMessages.allValues.mutableCopy;
    
    if (![[DataManager shared] myPopularFriends]) {
        [DataManager shared].myPopularFriends = popFriends.mutableCopy;
    }
    else{
        [[DataManager shared].myPopularFriends addObjectsFromArray:popFriends.allObjects];
    }
}

-(void)didReceiveAllFriends:(NSArray*)allFriends{
    [DataManager shared].myFriends = [allFriends mutableCopy];
    [[DataManager shared] makeFriendsDictionary];
    
    [[BackgroundWorker instance] requestPopularFriends];
}

#pragma mark -
#pragma mark FBDataDelegate methods
-(void)willAddCheckin:(UserAnnotation *)checkin{
    if (![[DataManager shared] allCheckins]) {
        [DataManager shared].allCheckins = [[NSMutableArray alloc] init];
    }
    [[DataManager shared].allCheckins addObject:checkin];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillAddCheckin object:nil];
}

#pragma mark -
#pragma mark DataDelegate methods

-(void) didReceiveCachedMapPoints:(NSArray*)cachedMapPoints{
    if (![DataManager shared].mapPoints) {
        [DataManager shared].mapPoints = cachedMapPoints.mutableCopy;
    }
    else
        [[DataManager shared].mapPoints addObjectsFromArray:cachedMapPoints];
    
}

-(void) didReceiveCachedMapPointsIDs:(NSArray*)cachedMapIDs{
    if (![DataManager shared].mapPoints) {
        [DataManager shared].mapPoints = cachedMapIDs.mutableCopy;
    }
    [[DataManager shared].mapPoints addObjectsFromArray:cachedMapIDs];
}

-(void)didReceiveCachedChatPoints:(NSArray*)cachedChatPoints{
    if (![[DataManager shared] chatPoints]) {
        [DataManager shared].chatPoints = cachedChatPoints.mutableCopy;
    }
    else
        [[DataManager shared].chatPoints addObjectsFromArray:cachedChatPoints];
}

-(void)didReceiveCachedChatMessagesIDs:(NSArray*)cachedChatMessagesIDs{
    if (![DataManager shared].chatMessagesIDs) {
        [DataManager shared].chatMessagesIDs = cachedChatMessagesIDs.mutableCopy;
    }
    
    [[DataManager shared].chatMessagesIDs addObjectsFromArray:cachedChatMessagesIDs];
}

-(void)didReceiveCachedCheckins:(NSArray *)cachedCheckins{
    if (![DataManager shared].allCheckins) {
        [DataManager shared].allCheckins = cachedCheckins.mutableCopy;
    }
    
    [[DataManager shared].allCheckins addObjectsFromArray:cachedCheckins];
}

-(void)didNotReceiveNewChatPoints{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidNotReceiveNewChatPoints object:nil];
}

-(void)didReceiveError:(NSString *)errorMessage{
    NSMutableDictionary* error = [[[NSMutableDictionary alloc] init] autorelease];
    [error setObject:errorMessage forKey:@"errorMessage"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidReceiveError object:nil userInfo:error];
}


#pragma mark -
#pragma mark ChatControllerDelegate Methods
-(void)didSuccessfulMessageSending{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSuccessfulMessageSending object:nil];
}

-(void)chatEndRetrievingData{
    [[NSNotificationCenter defaultCenter] postNotificationName:kChatEndRetrievingData object:nil];
}

-(void)willRemoveLastChatPoint{
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillRemoveLastChatPoint object:nil];
}

-(void)didReceiveErrorLoadingNewChatPoints{
    [[NSNotificationCenter defaultCenter] postNotificationName:kdidReceiveErrorLoadingNewChatPoints object:nil];
}

-(void)willUpdate{
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillUpdate object:nil];
}

-(void)willClearMessageField{
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillClearMessageField object:nil];
}

-(void)willAddNewMessageToChat:(UserAnnotation *)annotation addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable isFBCheckin:(BOOL)isFBCheckin{
    NSMutableDictionary* newMessageData = [[[NSMutableDictionary alloc] init] autorelease];
    [newMessageData setObject:annotation forKey:@"newMessage"];
    [newMessageData setObject:[NSNumber numberWithBool:toTop] forKey:@"addToTop"];
    [newMessageData setObject:[NSNumber numberWithBool:reloadTable] forKey:@"reloadTable"];
    [newMessageData setObject:[NSNumber numberWithBool:isFBCheckin] forKey:@"isFBCheckin"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillAddNewMessageToChat object:nil userInfo:newMessageData];
}

-(void)willScrollToTop{
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillScrollToTop object:nil];
}


#pragma mark -
#pragma mark MapControllerDelegate Methods
-(void)mapEndRetrievingData{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMapEndRetrievingData object:nil];
}

-(void)willAddNewPoint:(UserAnnotation *)point isFBCheckin:(BOOL)isFBCheckin{
    NSMutableDictionary* newPointData = [[[NSMutableDictionary alloc] init] autorelease];
    [newPointData setObject:point forKey:@"newPoint"];
    [newPointData setObject:[NSNumber numberWithBool:isFBCheckin] forKey:@"isFBCheckin"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillAddPointIsFBCheckin object:nil userInfo:newPointData];
}

-(void)willUpdatePointStatus:(UserAnnotation *)newPoint{
    NSMutableDictionary* newData = [[[NSMutableDictionary alloc] init] autorelease];
    [newData setObject:newPoint forKey:@"newPointStatus"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillUpdatePointStatus object:nil userInfo:newData];
}

-(void)willSaveMapARPoints:(NSArray *)newMapPoints{
    [[DataManager shared] addMapARPointsToStorage:newMapPoints];
}


@end
