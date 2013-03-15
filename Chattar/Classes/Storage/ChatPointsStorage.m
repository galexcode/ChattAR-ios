//
//  ChatPointsStorage.m
//  Chattar
//
//  Created by kirill on 2/26/13.
//
//

#import "ChatPointsStorage.h"

@implementation ChatPointsStorage
@synthesize geoData;
-(void)dealloc{
    [geoData release];
    [super dealloc];
}

-(id)init{
    if (self = [super init]) {
        self.needsCaching = YES;
    }
    return self;
}

-(void)showFriendsDataFromStorage{
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
}

-(void)showWorldDataFromStorage{
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
}

-(void)refreshDataFromStorage{
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey: @"createdAt" ascending: NO] autorelease];
	NSArray* sortedArray = [[DataManager shared].chatPoints sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
	[[DataManager shared].chatPoints removeAllObjects];
	[[DataManager shared].chatPoints addObjectsFromArray:sortedArray];
}

-(UserAnnotation*)retrieveDataFromStorageWithIndex:(NSInteger)index{
    return [[DataManager shared].chatPoints objectAtIndex:index];
}

-(NSInteger)storageCount{
    return [DataManager shared].chatPoints.count;
}

-(NSInteger)allDataCount{
    return [DataManager shared].allChatPoints.count;
}

-(void)addDataToStorage:(UserAnnotation *)newData{
    [[DataManager shared].chatPoints addObject:newData];
}

-(void)removeLastObjectFromStorage{
    if ([DataManager shared].chatPoints.count != 0) {
        [[DataManager shared].chatPoints removeLastObject];
    }
}

-(BOOL)isStorageEmpty{
    return ([DataManager shared].chatPoints.count == 0);
}

-(void)clearStorage{
    [[DataManager shared].allChatPoints removeAllObjects];
    [[DataManager shared].chatPoints removeAllObjects];
    [[DataManager shared].chatMessagesIDs removeAllObjects];
    
    [[DataManager shared].myFriends removeAllObjects];
    [[DataManager shared].myPopularFriends removeAllObjects];
    [[DataManager shared].myFriendsAsDictionary removeAllObjects];
}

-(void)insertObjectToAllData:(UserAnnotation *)object atIndex:(NSInteger)index{
    if (![DataManager shared].allChatPoints) {
        [DataManager shared].allChatPoints = [[NSMutableArray alloc] init];
    }
    
    NSString* objectID = [NSString stringWithFormat:@"%d",object.geoDataID];
    if (((index >= 0 && index < [DataManager shared].allChatPoints.count) || !index) && ![[DataManager shared].chatMessagesIDs containsObject:objectID]) {
        [[DataManager shared].allChatPoints insertObject:object atIndex:index];
    }
}

-(void)insertObjectToPartialData:(UserAnnotation *)object atIndex:(NSInteger)index{
    if (![DataManager shared].chatPoints) {
        [DataManager shared].chatPoints = [[NSMutableArray alloc] init];
    }

    NSString* objectID = [NSString stringWithFormat:@"%d",object.geoDataID];

    
    if ( (index >= 0 && index < [DataManager shared].chatPoints.count)  &&  ![[DataManager shared].chatMessagesIDs containsObject:objectID]  ) {
        [[DataManager shared].chatPoints insertObject:object atIndex:index];
    }
}

-(void)removeAllPartialData{
    [[DataManager shared].chatPoints removeAllObjects];
}

-(void)createDataInStorage:(NSDictionary *)data{
    NSString* messageText = [data objectForKey:@"messageText"];
    NSString* quoteMark = [data objectForKey:@"quoteMark"];
    
	geoData = [QBLGeoData currentGeoData];
    if(geoData.latitude == 0 && geoData.longitude == 0){
        CLLocationManager *locationManager = [[[CLLocationManager alloc] init] autorelease];
        [geoData setLatitude:locationManager.location.coordinate.latitude];
        [geoData setLongitude:locationManager.location.coordinate.longitude];
    }
	geoData.user = [DataManager shared].currentQBUser;
	
    // set body - with quote or without
	if (quoteMark){
		geoData.status = [quoteMark stringByAppendingString:messageText];
	}else {
		geoData.status = messageText;
	}
    
	if (quoteMark){

        // search QB User by fb ID
        NSString *fbUserID = [[geoData.status substringFromIndex:6] substringToIndex:[quoteMark rangeOfString:nameIdentifier].location-6];

        [[BackgroundWorker instance] requestFriendWithFacebookID:fbUserID andMessageText:messageText];
	}

}
@end
