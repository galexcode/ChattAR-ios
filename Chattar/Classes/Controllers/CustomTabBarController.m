
//
//  CustomTabBarController.m
//  Chattar
//
//  Created by kirill on 2/5/13.
//
//

#import "CustomTabBarController.h"
#import "AppDelegate.h"
#import "DataManager.h"

@interface CustomTabBarController ()

@end
#define INITIAL_CHATROOM_RATING 20

@implementation CustomTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestFBInfo) name:kRegisterPushNotificatons object:nil];
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

-(void)requestFBInfo{
    [[BackgroundWorker instance] setTabBarDelegate:self];
    [[BackgroundWorker instance] requestFBHistory];
    [[BackgroundWorker instance] requestFriends];
}

-(void)requestControllerData{
    [[BackgroundWorker instance] retrieveCachedChatDataAndRequestNewData];
    [[BackgroundWorker instance] retrieveCachedMapDataAndRequestNewData];
    [[BackgroundWorker instance] retrieveCachedFBCheckinsAndRequestNewCheckins];
    
    [[BackgroundWorker instance] requestAdditionalChatRoomsInfo];
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
    
    [BackgroundWorker instance].numberOfCheckinsRetrieved = ceil([[[DataManager shared].myPopularFriends allObjects] count]/fmaxRequestsInBatch);
    [[NSNotificationCenter defaultCenter] postNotificationName:kGeneralDataEndRetrieving object:nil];
    
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

-(void)chatDidReceiveAllCachedData:(NSDictionary *)cachedData{
                    
    if (![[DataManager shared] allChatPoints]) {
        [DataManager shared].allChatPoints = [[cachedData objectForKey:@"allChatPoints"] mutableCopy];
    }
    else{
        [[DataManager shared].allChatPoints addObjectsFromArray:[cachedData objectForKey:@"allChatPoints"]];
    }
    
    if (![DataManager shared].chatMessagesIDs) {
        [DataManager shared].chatMessagesIDs = [[cachedData objectForKey:@"chatMessagesIDs"] mutableCopy];
    }
    else{
        [[DataManager shared].chatMessagesIDs addObjectsFromArray:[cachedData objectForKey:@"chatMessagesIDs"]];
    }
    
    if (![DataManager shared].chatPoints) {
        [DataManager shared].chatPoints = [[NSMutableArray alloc] init];
    }
}

-(void)mapDidReceiveAllCachedData:(NSDictionary *)allMapData{
    if (![DataManager shared].allmapPoints) {
        [DataManager shared].allmapPoints = [[allMapData objectForKey:@"allMapPoints"] mutableCopy];
    }
    else
        [[DataManager shared].allmapPoints addObjectsFromArray:[allMapData objectForKey:@"allMapPoints"]];
    
    
    if (![DataManager shared].mapPointsIDs) {
        [DataManager shared].mapPointsIDs = [[allMapData objectForKey:@"mapPointsIDs"] mutableCopy];
    }
    else{
        [[DataManager shared].mapPointsIDs addObjectsFromArray:[allMapData objectForKey:@"mapPointsIDs"]];
    }
    
    if (![DataManager shared].mapPoints) {
        [DataManager shared].mapPoints = [[NSMutableArray alloc] init];
    }
    
    if (![DataManager shared].coordinates) {
        [DataManager shared].coordinates = [[NSMutableArray alloc] init];
    }
    
    if (![DataManager shared].coordinateViews) {
        [DataManager shared].coordinateViews = [[NSMutableArray alloc] init];
    }
}


-(void)didReceiveCachedCheckins:(NSArray *)cachedCheckins{
    if (![DataManager shared].allCheckins) {
        [DataManager shared].allCheckins = cachedCheckins.mutableCopy;
    }
    
    else
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

-(void)willShowAllFriends{
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillShowAllFriends object:nil];
}



#pragma mark -
#pragma mark ChatControllerDelegate Methods
-(void)didNotReceiveNewFBChatUsers{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidNotReceiveNewFBChatUsers object:nil];
}
-(void)didSuccessfulMessageSending{
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSuccessfulMessageSending object:nil];
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

-(void)willSetAllFriendsSwitchEnabled:(BOOL)switchEnabled{
    NSMutableDictionary* data = [[[NSMutableDictionary alloc] init] autorelease];
    [data setObject:[NSNumber numberWithBool:switchEnabled] forKey:@"switchEnabled"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillSetAllFriendsSwitchEnabled object:nil userInfo:data];
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

-(void)willSetEnabledMessageField:(BOOL)enabled{
    NSMutableDictionary* data = [[[NSMutableDictionary alloc] init] autorelease];
    [data setObject:[NSNumber numberWithBool:enabled] forKey:@"messageFieldEnabled"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillSetMessageFieldEnabled object:nil userInfo:data];
}

-(void)chatEndOfRetrievingInitialData{
    [[NSNotificationCenter defaultCenter] postNotificationName:kChatEndOfRetrievingInitialData object:nil];
}

#pragma mark -
#pragma mark MapControllerDelegate Methods

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

-(void)mapEndOfRetrievingInitialData{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMapEndOfRetrievingInitialData object:nil];
}

-(void)didNotReceiveNewFBMapUsers{
    [[NSNotificationCenter defaultCenter] postNotificationName:kMapDidNotReceiveNewFBMapUsers object:nil];
}


#pragma mark -
#pragma mark ARControllerDelegate Methods
-(void)willUpdateMarkersForCenterLocation{
    [[NSNotificationCenter defaultCenter] postNotificationName:kwillUpdateMarkersForCenterLocation object:nil];
}

-(void)willSetEnabledDistanceSlider:(BOOL)sliderEnabled{
    NSMutableDictionary* data = [[[NSMutableDictionary alloc] init] autorelease];
    [data setObject:[NSNumber numberWithBool:sliderEnabled] forKey:@"sliderEnabled"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillSetDistanceSliderEnabled object:nil userInfo:data];
}

-(void)didNotReceiveNewARUsers{
    [[NSNotificationCenter defaultCenter] postNotificationName:kARDidNotReceiveNewUsers object:nil userInfo:nil];
}

#pragma mark -
#pragma mark ChatRoomsDataDelegate methods

-(void)didReceiveChatRooms:(NSArray *)chatRooms{
    if (chatRooms.count) {
        if (![DataManager shared].qbChatRooms) {
            [DataManager shared].qbChatRooms = [[NSMutableArray alloc] init];
        }
                            // if we have additional info about this room save it
        for (QBChatRoom* room in chatRooms) {
            if ([[DataManager shared] roomWithNameHasAdditionalInfo:room.roomName]) {
                [[DataManager shared].qbChatRooms addObject:room];
            }
        }

        [self prepareDataForDisplaying];
    }
}

-(void)didEnterExistingRoom{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNeedToDisplayChatRoomController object:nil];
}

-(void)prepareDataForDisplaying{
    // get number of users for all rooms
    [[BackgroundWorker instance] retrieveNumberOfUsersInEachRoom];
    
    // get distances from rooms to current user location
    [[BackgroundWorker instance] calculateDistancesForEachRoom];
    
    [self retrieveNearbyRoomsStorage];
    
    // sort depending on rating value
    
    #warning TODO:implement calculating rooms ratings
    
    [self retrieveTrendingRoomsStorage];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDataIsReadyForDisplaying object:nil];
}

-(void)didReceiveRoomsOccupantsNumber{
}


-(void)didReceiveAdditionalServerInfo:(NSArray *)additionalInfo{
                // initialise storage
    if (![DataManager shared].roomsWithAdditionalInfo) {
        [DataManager shared].roomsWithAdditionalInfo = [[NSMutableArray alloc] init];
    }

    for (QBCOCustomObject* object in additionalInfo) {
        NSLog(@"%@",object);
        
        ChatRoom* roomObject = [[[ChatRoom alloc] init] autorelease];
        roomObject.createdAt = object.createdAt;
        
        double latitude = [[object.fields objectForKey:@"latitude"] doubleValue];
        double longitude = [[object.fields objectForKey:@"longitude"] doubleValue];
        
        roomObject.ownerLocation = CLLocationCoordinate2DMake(latitude, longitude);
        
        roomObject.roomID = object.ID;
        roomObject.xmppName = [object.fields objectForKey:@"xmppName"];
        roomObject.roomRating = INITIAL_CHATROOM_RATING;
        
        [[DataManager shared].roomsWithAdditionalInfo addObject:roomObject];
    }
    
    [[BackgroundWorker instance] requestAllChatRooms];
}

-(void)retrieveNearbyRoomsStorage{
    if(![DataManager shared].nearbyRooms){
        [DataManager shared].nearbyRooms = [[NSMutableArray alloc] init];
    }
    
    NSArray* sortedRooms = [Helper sortArray:[DataManager shared].roomsWithAdditionalInfo dependingOnField:@"distanceFromUser" inAscendingOrder:NO];
    
    [[DataManager shared].nearbyRooms addObjectsFromArray:sortedRooms];
}

-(void)retrieveTrendingRoomsStorage{
    if (![DataManager shared].trendingRooms) {
        [DataManager shared].trendingRooms = [[NSMutableArray alloc] init];
    }
    
    NSArray* sortedRooms = [Helper sortArray:[DataManager shared].roomsWithAdditionalInfo dependingOnField:@"roomRating" inAscendingOrder:NO];
    [[DataManager shared].trendingRooms addObjectsFromArray:sortedRooms];
}


@end
