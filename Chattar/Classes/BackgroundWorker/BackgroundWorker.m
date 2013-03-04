//
//  BackgroundWorker.m
//  Chattar
//
//  Created by kirill on 2/4/13.
//
//

#import "BackgroundWorker.h"
#import "ChatRoom.h"

#define mapSearch @"mapSearch"
#define chatSearch @"chatSearch"
#define mapFBUsers @"mapFBUsers"
#define chatFBUsers @"chatFBUsers"
#define moreChatMessages @"getMoreChatMessages"
#define chatRoomUsersProfiles @"chatRoomUsersProfiles"
#define kGetGeoDataCount 100

@implementation BackgroundWorker
@synthesize tabBarDelegate;
@synthesize FBfriends;
@synthesize chatInitState;
@synthesize mapInitState;
@synthesize numberOfCheckinsRetrieved;
@synthesize numberOfUserPicturesRetrieved;

static BackgroundWorker* instance = nil;

+ (BackgroundWorker *)instance {
	@synchronized (self) {
		if (instance == nil){
            instance = [[self alloc] init];

        }
	}
	return instance;
}

-(id)init{
    if (self = [super init]) {
        self.chatInitState = 0;
        self.mapInitState = 0;
        
        
        locationManager = [[CLLocationManager alloc] init];
        [locationManager startMonitoringSignificantLocationChanges];
        
        [locationManager setDelegate:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopRequestingNewData) name:kNotificationLogout object:nil];
        
        [[QBChat instance] setDelegate:self];
        
        
    }
    return self;
}


-(void)dealloc{
    [FBfriends release];
    dispatch_release(getMoreMessagesWorkQueue);
    [locationManager release];
    [super dealloc];
}

#pragma mark -
#pragma mark ChatRooms methods
-(void)createChatRoom:(NSString*)chatRoomName{
    [[QBChat instance] createOrJoinRoomWithName:chatRoomName membersOnly:NO persistent:YES];
}


#pragma mark -
#pragma mark Posting methods
-(void)postGeoData:(QBLGeoData*)geoData{
	[QBLocation createGeoData:geoData delegate:self];
}

-(void)postInformationWithDataStorage:(Storage*)dataStorage{
    if ([dataStorage isKindOfClass:[ChatPointsStorage class]]) {
        [self postGeoData:((ChatPointsStorage*)dataStorage).geoData];

    }
    else if ([dataStorage isKindOfClass:[ChatRoomsStorage class]]){
        [self sendMessage:((ChatRoomsStorage*)dataStorage).messageToSend.text];
    }
}

-(void)sendMessage:(NSString*)message{
    QBChatRoom* room = [[DataManager shared] findQBRoomWithName:[DataManager shared].currentChatRoom.roomName];
    [[QBChat instance] sendMessage:message toRoom:room];
}

#pragma mark -
#pragma mark Data Requests

-(void)requestUsersPictures{
    if ([DataManager shared].currentChatRoom.roomUsers.count) {
        NSMutableString* ids = [[[NSMutableString alloc] initWithString:@""] autorelease];
        
        [[DataManager shared].currentChatRoom.roomUsers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            QBUUser* user = (QBUUser*)obj;
            [ids appendString:user.facebookID];
            if (idx != [DataManager shared].currentChatRoom.roomUsers.count-1) {
                [ids appendString:@","];
            }
        }];
        
        numberOfUserPicturesRetrieved = [DataManager shared].currentChatRoom.roomUsers.count;
        [[FBService shared] usersProfilesWithIds:ids delegate:self context:chatRoomUsersProfiles];
    }
}

-(void)requestDataForDataStorage:(Storage *)dataStorage{
    if ([dataStorage isKindOfClass:[ChatPointsStorage class]]) {
        [self retrieveCachedChatDataAndRequestNewData];
        [self retrieveCachedFBCheckinsAndRequestNewCheckins];
    }
    else if([dataStorage isKindOfClass:[ChatRoomsStorage class]]){
        [self requestUsersPictures];
    }
}

-(void)requestAdditionalChatRoomsInfo{
    [QBCustomObjects objectsWithClassName:@"Room" delegate:self];
}

-(void)joinRoom:(QBChatRoom *)room{
    [[QBChat instance] joinRoom:room];
}

-(void)requestAllChatRooms{
    [[QBChat instance] requestAllRooms];
}

-(void)requestFriendWithFacebookID:(NSString*)fbUserID andMessageText:(NSString*)message{
    [QBUsers userWithFacebookID:fbUserID delegate:self context:message];
}

-(void)retrieveMoreChatMessages:(NSInteger)page{
    // get points for chat
	QBLGeoDataGetRequest *searchChatMessagesRequest = [[QBLGeoDataGetRequest alloc] init];
	searchChatMessagesRequest.perPage = 30; // Pins limit for each page
	searchChatMessagesRequest.page = page;
	searchChatMessagesRequest.status = YES;
	searchChatMessagesRequest.sortBy = GeoDataSortByKindCreatedAt;
	[QBLocation geoDataWithRequest:searchChatMessagesRequest delegate:self context:moreChatMessages];
	[searchChatMessagesRequest release];
}

-(void)requestFBHistory{
    [[FBService shared] inboxMessagesWithDelegate:self];
}

-(void)requestFriends{
    // get friends
    [[FBService shared] friendsGetWithDelegate:self];
}

-(void)requestPopularFriends{
    // need home feeds for determing popular friends IDs
    [[FBService shared] userWallWithDelegate:self];
}

- (void)retrieveNewQBData{
    if(updateTimer){
        [updateTimer invalidate];
        [updateTimer release];
    }
                    // request new data every 15 seconds
    updateTimer = [[NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(checkForNewPoints:) userInfo:nil repeats:YES] retain];
}

-(void)retrieveCachedMapDataAndRequestNewData{
    NSMutableArray* mapPoints = [[NSMutableArray alloc] init];
    NSMutableArray* mapPointsIds = [[NSMutableArray alloc] init];
    
    NSDate* lastPointDate = nil;
    // get map/ar points from cash
    NSArray *cashedMapARPoints = [[DataManager shared] mapARPointsFromStorage];
    if([cashedMapARPoints count] > 0){
        for(QBCheckinModel *mapARCashedPoint in cashedMapARPoints){
            if(lastPointDate == nil){
                lastPointDate = ((UserAnnotation *)mapARCashedPoint.body).createdAt;
            }
            [mapPoints addObject:mapARCashedPoint.body];
            [mapPointsIds addObject:[NSString stringWithFormat:@"%d", ((UserAnnotation *)mapARCashedPoint.body).geoDataID]];
        }
    }
        
    NSMutableDictionary* allMapData = [[[NSMutableDictionary alloc] init] autorelease];
    [allMapData setObject:mapPoints forKey:@"allMapPoints"];
    [allMapData setObject:mapPointsIds forKey:@"mapPointsIDs"];
    
    if ([tabBarDelegate respondsToSelector:@selector(mapDidReceiveAllCachedData:)]) {
        [tabBarDelegate mapDidReceiveAllCachedData:allMapData];
    }
    [mapPoints release];
    [mapPointsIds release];   
    
    // get points for map
	QBLGeoDataGetRequest *searchMapARPointsRequest = [[QBLGeoDataGetRequest alloc] init];
	searchMapARPointsRequest.lastOnly = YES;                                    // Only last location
	searchMapARPointsRequest.perPage = kGetGeoDataCount;                        // Pins limit for each page
	searchMapARPointsRequest.sortBy = GeoDataSortByKindCreatedAt;
    if(lastPointDate){
        searchMapARPointsRequest.minCreatedAt = lastPointDate;
    }
    
	[QBLocation geoDataWithRequest:searchMapARPointsRequest delegate:self context:mapSearch];
	[searchMapARPointsRequest release];    
}

-(void)retrieveCachedChatDataAndRequestNewData{
    // get chat messages from cash
    NSArray *cashedChatMessages = [[DataManager shared] chatMessagesFromStorage];
    
    NSMutableArray* chatPoints = [[NSMutableArray alloc] init];
    NSMutableArray* chatMessagesIDs = [[NSMutableArray alloc] init];
    
    NSDate *lastMessageDate = nil;

    
    if([cashedChatMessages count] > 0){
        for(QBChatMessageModel *chatCashedMessage in cashedChatMessages){
            if(lastMessageDate == nil){
                lastMessageDate = ((UserAnnotation *)chatCashedMessage.body).createdAt;
            }
            [chatPoints addObject:chatCashedMessage.body];
            [chatMessagesIDs addObject:[NSString stringWithFormat:@"%d", ((UserAnnotation *)chatCashedMessage.body).geoDataID]];
        }
    }
        
    NSMutableDictionary* allChatData = [[[NSMutableDictionary alloc] init] autorelease];
    [allChatData setObject:chatPoints forKey:@"allChatPoints"];
    [allChatData setObject:chatMessagesIDs forKey:@"chatMessagesIDs"];
    
    if ([tabBarDelegate respondsToSelector:@selector(chatDidReceiveAllCachedData:)]) {
        [tabBarDelegate chatDidReceiveAllCachedData:allChatData];
    }
    
    [chatPoints release];
    [chatMessagesIDs release];    
    
    // get points for chat
	QBLGeoDataGetRequest *searchChatMessagesRequest = [[QBLGeoDataGetRequest alloc] init];
	searchChatMessagesRequest.perPage = kGetGeoDataCount; // Pins limit for each page
	searchChatMessagesRequest.status = YES;
	searchChatMessagesRequest.sortBy = GeoDataSortByKindCreatedAt;
    
    if(lastMessageDate){
        searchChatMessagesRequest.minCreatedAt = lastMessageDate;
    }
        
	[QBLocation geoDataWithRequest:searchChatMessagesRequest delegate:self context:chatSearch];
	[searchChatMessagesRequest release];
    
}

- (void)retrieveCachedFBCheckinsAndRequestNewCheckins{
    // get checkins from cash
    NSArray *cashedFBCheckins = [[DataManager shared] checkinsFromStorage];
    
    if([cashedFBCheckins count] > 0){
        NSMutableArray* cachedCheckins = [[NSMutableArray alloc] init];
        
        for(FBCheckinModel *checkinCashedPoint in cashedFBCheckins){
            [cachedCheckins addObject:checkinCashedPoint.body];
        }
        
        if ([tabBarDelegate respondsToSelector:@selector(didReceiveCachedCheckins:)]) {
            [tabBarDelegate didReceiveCachedCheckins:cachedCheckins];
        }
        
        [cachedCheckins release];
        
    }
    
    if (cashedFBCheckins.count <= 0) {
        if ([tabBarDelegate respondsToSelector:@selector(willSetEnabledDistanceSlider:)]) {
            [tabBarDelegate willSetEnabledDistanceSlider:NO];
        }
    }
    
    numberOfCheckinsRetrieved = ceil([[[DataManager shared].myPopularFriends allObjects] count]/fmaxRequestsInBatch);
    
    // retrieve new
    if(numberOfCheckinsRetrieved != 0){
        [[FBService shared] performSelector:@selector(friendsCheckinsWithDelegate:) withObject:self afterDelay:1];
    }
    
}

//-(void)retrievePhotosWithLocations{
//    NSArray* popularFriendsIds = [[[DataManager shared] myPopularFriends] allObjects];
//    NSMutableArray* cachedPhotos = [[NSMutableArray alloc] init];
//
//    if (popularFriendsIds.count != 0) {
//        for (NSString* friendId in popularFriendsIds) {
//            NSArray* friendPhotos = [[DataManager shared] photosWithLocationsFromStorageFromUserWithId:[NSDecimalNumber decimalNumberWithString:friendId]];
//            [cachedPhotos addObjectsFromArray:friendPhotos];
//        }
//    }
//    else [cachedPhotos release];
//    
//    if (cachedPhotos.count > 0) {
//        
//        NSMutableArray* photosWithLocations = [[NSMutableArray alloc] init];
//        for (PhotoWithLocationModel* photo in cachedPhotos) {
//            UserAnnotation* photoAnnotation = [[UserAnnotation alloc] init];
//            [photoAnnotation setFullImageURL:photo.fullImageURL];
//            [photoAnnotation setThumbnailURL:photo.thumbnailURL];
//            [photoAnnotation setLocationId:photo.locationId];
//            [photoAnnotation setCoordinate:CLLocationCoordinate2DMake(photo.locationLatitude.doubleValue, photo.locationLongitude.doubleValue)];
//            [photoAnnotation setLocationName:photo.locationName];
//            [photoAnnotation setOwnerId:photo.ownerId];
//            [photoAnnotation setPhotoId:photo.photoId];
//            [photoAnnotation setPhotoTimeStamp:photo.photoTimeStamp];
//            [photosWithLocations addObject:photoAnnotation];
//            [photoAnnotation release];
//        }
//        [cachedPhotos release];
//        
//        if ([mapDelegate respondsToSelector:@selector(didReceiveCachedPhotosWithLocations:)]) {
//            [mapDelegate didReceiveCachedPhotosWithLocations:photosWithLocations];
//        }
//        
//    }
//                    // request new photos from FB
//    [[FBService shared] performSelector:@selector(friendsPhotosWithLocationWithDelegate:) withObject:self];
//}

- (void) checkForNewPoints:(NSTimer *) timer{
	QBLGeoDataGetRequest *searchRequest = [[QBLGeoDataGetRequest alloc] init];
	searchRequest.status = YES;
    searchRequest.sortBy = GeoDataSortByKindCreatedAt;
    searchRequest.sortAsc = 1;
    searchRequest.perPage = 50;
    searchRequest.minCreatedAt = ((UserAnnotation *)[self lastChatMessage:YES]).createdAt;
	[QBLocation geoDataWithRequest:searchRequest delegate:self];
	[searchRequest release];
}


#pragma mark - 
#pragma mark Data processing methods

- (void)processFBCheckins:(NSArray *)rawCheckins{
    if([rawCheckins isKindOfClass:NSString.class]){
        NSLog(@"rawCheckins=%@", rawCheckins);
#ifdef DEBUG
        id exc = [NSException exceptionWithName:NSInvalidArchiveOperationException
                                         reason:@"rawCheckins = NSString"
                                       userInfo:nil];
        @throw exc;
#endif
        return;
    }
    for(NSDictionary *checkinsResult in rawCheckins){
        if([checkinsResult isKindOfClass:NSNull.class]){
            continue;
        }
        
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        NSArray *checkins = [[parser objectWithString:(NSString *)([checkinsResult objectForKey:kBody])] objectForKey:kData];
        [parser release];
        
        if ([checkins count]){
            
            //
            
            CLLocationCoordinate2D coordinate;
            //
            NSString *previousPlaceID = nil;
            NSString *previousFBUserID = nil;
            
            // Collect checkins
            for(NSDictionary *checkin in checkins){
                
                NSString *ID = [checkin objectForKey:kId];
                
                NSDictionary *place = [checkin objectForKey:kPlace];
                if(place == nil){
                    continue;
                }
                
                id location = [place objectForKey:kLocation];
                if(![location isKindOfClass:NSDictionary.class]){
                    continue;
                }
                
                
                // get checkin's owner
                NSString *fbUserID = [[checkin objectForKey:kFrom] objectForKey:kId];
                
                NSDictionary *fbUser;
                if([fbUserID isEqualToString:[DataManager shared].currentFBUserId]){
                    fbUser = [DataManager shared].currentFBUser;
                }else{
                    fbUser = [[DataManager shared].myFriendsAsDictionary objectForKey:fbUserID];
                }
                
                // skip if not friend or own
                if(!fbUser){
                    continue;
                }
                
                // coordinate
                coordinate.latitude = [[[place objectForKey:kLocation] objectForKey:kLatitude] floatValue];
                coordinate.longitude = [[[place objectForKey:kLocation] objectForKey:kLongitude] floatValue];
                
                
                // if this is checkin on the same location
                if([previousPlaceID isEqualToString:[place objectForKey:kId]] && [previousFBUserID isEqualToString:fbUserID]){
                    continue;
                }
                
                
                // status
                NSString *status = nil;
                NSString* country = [location objectForKey:kCountry];
                
                
                NSString* city = [location objectForKey:kCity];
                
                NSString* name = [[checkin objectForKey:kPlace] objectForKey:kName];
                if ([country length]){
                    status = [NSString stringWithFormat:@"I'm at %@ in %@, %@.", name, country, city];
                }else {
                    status = [NSString stringWithFormat:@"I'm at %@", name];
                }
                
                // datetime
                NSString* time = [checkin objectForKey:kCreatedTime];
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                [df setLocale:[NSLocale currentLocale]];
                [df setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"];
                NSDate *createdAt = [df dateFromString:time];
                [df release];
                
                UserAnnotation *checkinAnnotation = [[UserAnnotation alloc] init];
                checkinAnnotation.geoDataID = -1;
                checkinAnnotation.coordinate = coordinate;
                checkinAnnotation.userStatus = status;
                checkinAnnotation.userName = [[checkin objectForKey:kFrom] objectForKey:kName];
                checkinAnnotation.userPhotoUrl = [fbUser objectForKey:kPicture];
                checkinAnnotation.fbUserId = [fbUser objectForKey:kId];
                checkinAnnotation.fbUser = fbUser;
                checkinAnnotation.fbCheckinID = ID;
                checkinAnnotation.fbPlaceID = [place objectForKey:kId];
                checkinAnnotation.createdAt = createdAt;
                
                                
                // add to Storage
                BOOL isAdded = [[DataManager shared] addCheckinToStorage:checkinAnnotation];
                if(!isAdded){
                    [checkinAnnotation release];
                    continue;
                }
                
                // show Point on Map/AR
                dispatch_async( dispatch_get_main_queue(), ^{
                    
                    if ([tabBarDelegate respondsToSelector:@selector(willAddNewPoint:isFBCheckin:)]) {
                        [tabBarDelegate willAddNewPoint:checkinAnnotation isFBCheckin:YES];
                    }
                    
                });
                
                // show Message on Chat
                UserAnnotation *chatAnnotation = [checkinAnnotation copy];
                
                if ([tabBarDelegate respondsToSelector:@selector(willAddNewMessageToChat:addToTop:withReloadTable:isFBCheckin:viewControllerIdentifier:)]) {
                    [tabBarDelegate willAddNewMessageToChat:chatAnnotation addToTop:NO withReloadTable:NO isFBCheckin:YES viewControllerIdentifier:chatViewControllerIdentifier];
                }
                
                previousPlaceID = [place objectForKey:kId];
                previousFBUserID = fbUserID;
                
                [[DataManager shared].allCheckins addObject:chatAnnotation];
                [checkinAnnotation release];
                [chatAnnotation release];
            }
        }
    }
    
    if(numberOfCheckinsRetrieved == 0){
        NSLog(@"Checkins have procceced");
    }
    
    // refresh chat
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([tabBarDelegate respondsToSelector:@selector(willUpdateViewControllerIdentifier:)]) {
            [tabBarDelegate willUpdateViewControllerIdentifier:chatViewControllerIdentifier];
        }
        
        if ([tabBarDelegate respondsToSelector:@selector(willUpdateMarkersForCenterLocation)]) {
            [tabBarDelegate willUpdateMarkersForCenterLocation];
        }
    });
}

-(void)processPhotosWithLocations:(NSDictionary*)responseData{
    NSLog(@"%@",responseData);
    
    
    NSArray* fqlResults = [responseData objectForKey:kData];
    
    NSArray* firstFqlResults = [(NSDictionary*)[fqlResults objectAtIndex:0] objectForKey:@"fql_result_set"];
    NSArray* secondFqlResults = [(NSDictionary*)[fqlResults objectAtIndex:1] objectForKey:@"fql_result_set"];
    NSArray* thirdFqlResults = [(NSDictionary*)[fqlResults objectAtIndex:2] objectForKey:@"fql_result_set"];
    
    NSMutableArray* photosWithLocations = [[NSMutableArray alloc] init];
    
    for (NSDictionary*fqlResult in firstFqlResults) {
        UserAnnotation* photoObject = [[UserAnnotation alloc] init];
        
        NSDecimalNumber* placeId = [fqlResult objectForKey:@"place_id"];
        NSString* thumbnailUrl = [fqlResult objectForKey:@"src_small"];
        
        [photoObject setThumbnailURL:thumbnailUrl];
        
        [photoObject setLocationId:placeId];
        
        NSString* fullPhotoUrl = [fqlResult objectForKey:@"src"];
        
        [photoObject setFullImageURL:fullPhotoUrl];
        
        NSString* photoId = [fqlResult objectForKey:@"pid"];
        [photoObject setPhotoId:photoId];
        
        NSDecimalNumber* photoTimeStamp = [fqlResult objectForKey:@"created"];
        [photoObject setPhotoTimeStamp:photoTimeStamp];
        
        NSDecimalNumber* ownerId = [fqlResult objectForKey:@"created"];
        [photoObject setOwnerId:ownerId];
        
        [photosWithLocations addObject:photoObject];
        [photoObject release];
    }
    
    NSLog(@"%@",photosWithLocations);
    
    for (NSDictionary* fqlResult in secondFqlResults) {
        NSDecimalNumber* pageID = [fqlResult objectForKey:@"page_id"];
        NSDecimalNumber* latitude = [fqlResult objectForKey:@"latitude"];
        NSDecimalNumber* longitude = [fqlResult objectForKey:@"longitude"];
        NSString* locationName = [fqlResult objectForKey:@"name"];
        
        for (UserAnnotation* photo in photosWithLocations) {
            if (fabs(photo.locationId.doubleValue - pageID.doubleValue) < 0.000001 ) {
                [photo setLocationName:locationName];
                [photo setLocationLatitude:latitude];
                [photo setLocationLongitude:longitude];
            }
        }
    }
    
    for (NSDictionary* fqlResult in thirdFqlResults) {
        NSDecimalNumber* ownerID = [fqlResult objectForKey:@"owner"];
        NSString* pid = [fqlResult objectForKey:@"pid"];
        
        for (UserAnnotation* photo in photosWithLocations) {
            if ([photo.photoId isEqualToString:pid]) {
                [photo setOwnerId:ownerID];
            }
        }
    }
        
    [[DataManager shared] addPhotosWithLocationsToStorage:photosWithLocations];
    
    
    [photosWithLocations release];
}

- (void)processQBChatMessages:(NSArray *)data{
    
    NSArray *fbUsers = [data objectAtIndex:0];
    NSArray *qbMessages = [data objectAtIndex:1];
    
    CLLocationCoordinate2D coordinate;
    int index = 0;
    
    NSMutableArray *qbMessagesMutable = [qbMessages mutableCopy];
    
    for (QBLGeoData *geodata in qbMessages){
        NSDictionary *fbUser = nil;
        for(NSDictionary *user in fbUsers){
            NSString *ID = [user objectForKey:kId];
            if([geodata.user.facebookID isEqualToString:ID]){
                fbUser = user;
                break;
            }
        }
        
        coordinate.latitude = geodata.latitude;
        coordinate.longitude = geodata.longitude;
        UserAnnotation *chatAnnotation = [[UserAnnotation alloc] init];
        chatAnnotation.geoDataID = geodata.ID;
        chatAnnotation.coordinate = coordinate;
        
        if ([geodata.status length] >= 6){
            if ([[geodata.status substringToIndex:6] isEqualToString:fbidIdentifier]){
                // add Quote
                [self addQuoteDataToAnnotation:chatAnnotation geoData:geodata];
                
            }else {
                chatAnnotation.userStatus = geodata.status;
            }
        }else {
            chatAnnotation.userStatus = geodata.status;
        }
        
        chatAnnotation.userName = [NSString stringWithFormat:@"%@ %@",
                                   [fbUser objectForKey:kFirstName], [fbUser objectForKey:kLastName]];
        chatAnnotation.userPhotoUrl = [fbUser objectForKey:kPicture];
        chatAnnotation.fbUserId = [fbUser objectForKey:kId];
        chatAnnotation.fbUser = fbUser;
        chatAnnotation.qbUserID = geodata.user.ID;
        chatAnnotation.createdAt = geodata.createdAt;
        
        
        if(chatAnnotation.coordinate.latitude == 0.0f && chatAnnotation.coordinate.longitude == 0.0f)
        {
            chatAnnotation.distance = 0;
        }
        
        [qbMessagesMutable replaceObjectAtIndex:index withObject:chatAnnotation];
        [chatAnnotation release];
        
        ++index;

        // show Message on Chat
        if ([tabBarDelegate respondsToSelector:@selector(willAddNewMessageToChat:addToTop:withReloadTable:isFBCheckin:viewControllerIdentifier:)]) {
            [tabBarDelegate willAddNewMessageToChat:chatAnnotation addToTop:NO withReloadTable:NO isFBCheckin:NO viewControllerIdentifier:chatViewControllerIdentifier];
        }
    }
    NSLog(@"CHAT INIT reloadData");
    dispatch_async(dispatch_get_main_queue(), ^{       
        if ([tabBarDelegate respondsToSelector:@selector(willUpdateViewControllerIdentifier:)]) {
            [tabBarDelegate willUpdateViewControllerIdentifier:chatViewControllerIdentifier];
        }
    });
    
    
    [qbMessagesMutable release];
    
    
    // all data was retrieved
    ++self.chatInitState;

    NSLog(@"CHAT INIT OK");
    if(self.chatInitState == 1){
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([tabBarDelegate respondsToSelector:@selector(willSetAllFriendsSwitchEnabled:InViewControllerWithIdentifier:)]) {
                [tabBarDelegate willSetAllFriendsSwitchEnabled:YES InViewControllerWithIdentifier:chatViewControllerIdentifier];
            }

            if ([tabBarDelegate respondsToSelector:@selector(chatEndOfRetrievingInitialDataInViewControllerWithIdentifier:)]) {
                [tabBarDelegate chatEndOfRetrievingInitialDataInViewControllerWithIdentifier:chatViewControllerIdentifier];
            }
        });
        self.chatInitState = 0;
    }
}


- (void)processQBCheckins:(NSArray *)data{
    
    NSArray *fbUsers = [data objectAtIndex:0];
    NSArray *qbPoints = [data objectAtIndex:1];
    
    CLLocationCoordinate2D coordinate;
    int index = 0;
    
    NSMutableArray *mapPointsMutable = [qbPoints mutableCopy];
    
    // look through array for geodatas
    for (QBLGeoData *geodata in qbPoints)
    {
        NSDictionary *fbUser = nil;
        for(NSDictionary *user in fbUsers){
            NSString *ID = [user objectForKey:kId];
            if([geodata.user.facebookID isEqualToString:ID]){
                fbUser = user;
                break;
            }
        }
        
        if ([geodata.user.facebookID isEqualToString:[DataManager shared].currentFBUserId])
        {
            coordinate.latitude = locationManager.location.coordinate.latitude;
            coordinate.longitude = locationManager.location.coordinate.longitude;
        }
        else
        {
            coordinate.latitude = geodata.latitude;
            coordinate.longitude = geodata.longitude;
        }
        
        UserAnnotation *mapAnnotation = [[UserAnnotation alloc] init];
        mapAnnotation.geoDataID = geodata.ID;
        mapAnnotation.coordinate = coordinate;
        mapAnnotation.userStatus = geodata.status;
        mapAnnotation.userName = [fbUser objectForKey:kName];
        mapAnnotation.userPhotoUrl = [fbUser objectForKey:kPicture];
        mapAnnotation.fbUserId = [fbUser objectForKey:kId];
        mapAnnotation.fbUser = fbUser;
        mapAnnotation.qbUserID = geodata.user.ID;
        mapAnnotation.createdAt = geodata.createdAt;
        [mapPointsMutable replaceObjectAtIndex:index withObject:mapAnnotation];
        [mapAnnotation release];
        
        ++index;
        
        // show Point on Map/AR
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([tabBarDelegate respondsToSelector:@selector(willAddNewPoint:isFBCheckin:)]) {
                [tabBarDelegate willAddNewPoint:mapAnnotation isFBCheckin:NO];
            }
        });
    }
    
    // update AR
    dispatch_async( dispatch_get_main_queue(), ^{
        if ([tabBarDelegate respondsToSelector:@selector(willUpdateMarkersForCenterLocation)]) {
            [tabBarDelegate willUpdateMarkersForCenterLocation];
        }
    });
    
    [[DataManager shared] addMapARPointsToStorage:mapPointsMutable];
    
    [mapPointsMutable release];
    
    // all data was retrieved
    ++self.mapInitState;
    NSLog(@"MAP INIT OK");
    if(self.mapInitState == 1){
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([tabBarDelegate respondsToSelector:@selector(willSetAllFriendsSwitchEnabled:)]) {
                [tabBarDelegate willSetAllFriendsSwitchEnabled:YES];
            }

            
            if ([tabBarDelegate respondsToSelector:@selector(mapEndOfRetrievingInitialData)]) {
                [tabBarDelegate mapEndOfRetrievingInitialData];
            }
            
        });
        self.mapInitState = 0;
    }
}


#pragma mark -
#pragma mark QB QBActionStatusDelegate

- (void)completedWithResult:(Result *)result context:(void *)contextInfo{
    // get points result
	if([result isKindOfClass:[QBLGeoDataPagedResult class]])
	{
        
        
        NSLog(@"QB completedWithResult, contextInfo=%@, class=%@", contextInfo, [result class]);
        QBLGeoDataPagedResult *geoDataSearchResult = (QBLGeoDataPagedResult *)result;
        if (result.success){
            
            // get more messages result
            if([((NSString *)contextInfo) isEqualToString:moreChatMessages])
            {
                
                QBLGeoDataPagedResult *geoDataSearchResult = (QBLGeoDataPagedResult *)result;
                
                // empty
                if([geoDataSearchResult.geodata count] == 0){
                    if ([tabBarDelegate respondsToSelector:@selector(didNotReceiveNewChatPoints)]) {
                        [tabBarDelegate didNotReceiveNewChatPointsForViewControllerWithIdentifier:chatViewControllerIdentifier];
                    }
                    return;
                }
                
                // process response
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    // get fb users info
                    NSMutableArray *fbChatUsersIds = [[NSMutableArray alloc] init];
                    for (QBLGeoData *geodata in geoDataSearchResult.geodata){
                        [fbChatUsersIds addObject:geodata.user.facebookID];
                    }
                    //
                    NSMutableString* ids = [[NSMutableString alloc] init];
                    for (NSString* userID in fbChatUsersIds)
                    {
                        [ids appendFormat:@"%@,", userID];
                    }
                    
                    if ([ids length] != 0)
                    {
                        NSString* q = [ids substringToIndex:[ids length]-1];
                        [[FBService shared] usersProfilesWithIds:q delegate:self context:geoDataSearchResult.geodata];
                    }
                    [ids release];
                    //
                    [fbChatUsersIds release];
                });
            }

            
            
            // update map
           else if([((NSString *)contextInfo) isEqualToString:mapSearch]){
                
                // get string of fb users ids
               NSMutableArray *fbMapUsersIds = [[NSMutableArray alloc] init];
               NSMutableArray *geodataProcessed = [NSMutableArray array];
               NSLog(@"%@",geoDataSearchResult.geodata);
                
               for (QBLGeoData *geodata in geoDataSearchResult.geodata){
                   // skip if already exist
                   if([[DataManager shared].mapPointsIDs containsObject:[NSString stringWithFormat:@"%d", geodata.ID]]){
                       continue;
                   }
                   
                   //add users with only nonzero coordinates
                   if(geodata.latitude != 0 && geodata.longitude != 0){
                       [fbMapUsersIds addObject:geodata.user.facebookID];
                       
                       [geodataProcessed addObject:geodata];
                   }
               }
                if([fbMapUsersIds count] == 0){
                    [fbMapUsersIds release];
                    
                    if ([[DataManager shared].currentRequestingDataControllerTitle isEqualToString:@"Map"]) {
                        if ([tabBarDelegate respondsToSelector:@selector(didNotReceiveNewFBMapUsers)]) {
                            [tabBarDelegate didNotReceiveNewFBMapUsers];
                        }

                    }
                    else if ([[DataManager shared].currentRequestingDataControllerTitle isEqualToString:@"AR"]){
                        if ([tabBarDelegate respondsToSelector:@selector(didNotReceiveNewARUsers)]) {
                            [tabBarDelegate didNotReceiveNewARUsers];
                        }
                    }
                    
                    return;
                }
                
                //
				NSMutableString* ids = [[NSMutableString alloc] init];
				for (NSString* userID in fbMapUsersIds)
				{
					[ids appendString:[NSString stringWithFormat:@"%@,", userID]];
				}
				
                NSLog(@"ids=%@", ids);
                
                NSArray *context = [NSArray arrayWithObjects:mapFBUsers, geodataProcessed, nil];
                
                
				// get FB info for obtained QB locations
				[[FBService shared] usersProfilesWithIds:[ids substringToIndex:[ids length]-1]
                                                delegate:self
                                                 context:context];
                
                [fbMapUsersIds release];
				[ids release];
                
                // update chat
            }else if([((NSString *)contextInfo) isEqualToString:chatSearch]){
                
                // get fb users info
                NSMutableSet *fbChatUsersIds = [[NSMutableSet alloc] init];
                
                NSMutableArray *geodataProcessed = [NSMutableArray array];
                
                for (QBLGeoData *geodata in geoDataSearchResult.geodata){
                    // skip if already exist
                    
                    if([[DataManager shared].mapPointsIDs containsObject:[NSString stringWithFormat:@"%d", geodata.ID]]){
                        continue;
                    }

                    [fbChatUsersIds addObject:geodata.user.facebookID];
                    
                    [geodataProcessed addObject:geodata];
                }
                if([fbChatUsersIds count] == 0){
                    if ([tabBarDelegate respondsToSelector:@selector(didNotReceiveNewFBChatUsers)]) {
                        [tabBarDelegate didNotReceiveNewFBChatUsersInViewControllerWithIdentifier:chatViewControllerIdentifier];
                    }
                    [fbChatUsersIds release];
                    return;
                }
                
                //
                NSMutableString* ids = [[NSMutableString alloc] init];
				for (NSString* userID in fbChatUsersIds)
				{
					[ids appendString:[NSString stringWithFormat:@"%@,", userID]];
				}
                
                
                NSArray *context = [NSArray arrayWithObjects:chatFBUsers, geodataProcessed, nil];
                                
                
                // get FB info for obtained QB chat messages
				[[FBService shared] usersProfilesWithIds:[ids substringToIndex:[ids length]-1]
                                                delegate:self
                                                 context:context];
                [fbChatUsersIds release];
                [ids release];
            }
            
        }
        else     // search QB user by FB ID result
            if([result isKindOfClass:QBUUserResult.class]){
                if(result.success){
                    
                    QBUUser *qbUser = ((QBUUserResult *)result).user;
                    
                    // Create push message
                    
                    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
                    NSMutableDictionary *aps = [NSMutableDictionary dictionary];
                    [aps setObject:@"default" forKey:QBMPushMessageSoundKey];
                    [aps setObject:[NSString stringWithFormat:@"%@: %@", [[DataManager shared].currentFBUser objectForKey:kName], (NSString *)contextInfo] forKey:QBMPushMessageAlertKey];
                    [payload setObject:aps forKey:QBMPushMessageApsKey];
                    //
                    QBMPushMessage *message = [[QBMPushMessage alloc] initWithPayload:payload];
                    
                    // Send push
                    [QBMessages TSendPush:message
                                  toUsers:[NSString stringWithFormat:@"%d",  qbUser.ID]
                                 delegate:self];
                    
                    [message release];
                }
            }
        
        else{
            NSString* errorMessage = [result.errors stringValue];
            if ([tabBarDelegate respondsToSelector:@selector(didReceiveError:)]) {
                [tabBarDelegate didReceiveError:errorMessage];
            }
            
        }
    }
}

- (void)completedWithResult:(Result *)result {
    NSLog(@"completedWithResult");
    
    // get points result - check for new one
	if([result isKindOfClass:[QBLGeoDataPagedResult class]])
	{
        
        if (result.success){
            QBLGeoDataPagedResult *geoDataSearchResult = (QBLGeoDataPagedResult *)result;
            
            if([geoDataSearchResult.geodata count] == 0){
                return;
            }
            
            // get fb users info
            NSMutableArray *fbChatUsersIds = nil;
            NSMutableArray *geodataProcessed = [NSMutableArray array];
            
            for (QBLGeoData *geodata in geoDataSearchResult.geodata){
                
                // skip own;
                if([DataManager shared].currentQBUser.ID == geodata.user.ID){
                    continue;
                }
                
                // collect users ids
                if(fbChatUsersIds == nil){
                    fbChatUsersIds = [[NSMutableArray alloc] init];
                }
                [fbChatUsersIds addObject:geodata.user.facebookID];
                
                [geodataProcessed addObject:geodata];
            }
            
            if(fbChatUsersIds == nil){
                return;
            }
            
            //
            [[FBService shared] usersProfilesWithIds:[fbChatUsersIds stringComaSeparatedValue] delegate:self context:geodataProcessed];
            //
            [fbChatUsersIds release];
        }
    }
    else if ([result isKindOfClass:QBLGeoDataResult.class]){
        QBLGeoDataResult *geoDataRes = (QBLGeoDataResult*)result;
        
        
        if ([tabBarDelegate respondsToSelector:@selector(willClearMessageField)]) {
            [tabBarDelegate willClearMessageFieldInViewControllerWithIdentifier:chatViewControllerIdentifier];
        }
        
        // add new Annotation to map/chat/ar
        [self createAndAddNewAnnotationToMapChatARForFBUser:[DataManager shared].currentFBUser
                                                                                 withGeoData:geoDataRes.geoData addToTop:YES withReloadTable:YES];
        
        if ([tabBarDelegate respondsToSelector:@selector(didSuccessfulMessageSending)]) {
            [tabBarDelegate didSuccessfulMessageSendingInViewControllerWithIdentifier:chatViewControllerIdentifier];
        }
        
        if ([tabBarDelegate respondsToSelector:@selector(willScrollToTop)]) {
            [tabBarDelegate willScrollToTopInViewControllerWithIdentifier:chatViewControllerIdentifier];
        }
        
    }
    else if ([result isKindOfClass:QBMSendPushTaskResult.class]){
        NSLog(@"Send Push success");
    }
    else if ([result isKindOfClass:[QBCOCustomObjectResult class]]){
        if (result.success) {
            NSLog(@"SUCCESSFUL CREATION OF OBJECT %@",((QBCOCustomObjectResult*)result).object);
        }
    }
    else if ([result isKindOfClass:[QBCOCustomObjectPagedResult class]]){
        QBCOCustomObjectPagedResult *getObjectsResult = (QBCOCustomObjectPagedResult *)result;
        if ([tabBarDelegate respondsToSelector:@selector(didReceiveAdditionalServerInfo:)]) {
            [tabBarDelegate didReceiveAdditionalServerInfo:getObjectsResult.objects ];
        }
    }
    
    else if ([result isKindOfClass:[QBCOCustomObjectResult class]]){
        QBCOCustomObjectResult* getObjectResult = (QBCOCustomObjectResult*)result;
        if ([tabBarDelegate respondsToSelector:@selector(didReceiveAdditionalServerInfo:)]) {
            [tabBarDelegate didReceiveAdditionalServerInfo:[NSArray arrayWithObject:getObjectResult.object]];
        }
    }
    else{
        NSString *message = [result.errors stringValue];
        if ([tabBarDelegate respondsToSelector:@selector(didReceiveError:)]) {
            [tabBarDelegate didReceiveError:message];
        }
    }
}


#pragma mark -
#pragma mark FBServiceResultDelegate

-(void)completedWithFBResult:(FBServiceResult *)result context:(id)context{
    
    switch (result.queryType) {
            
            // get Users profiles
        case FBQueriesTypesUsersProfiles:{
            
            NSArray *contextArray = nil;
            NSString *contextType = nil;
            NSArray *points = nil;
            if([context isKindOfClass:NSArray.class]){
                contextArray = (NSArray *)context;
                
                // basic
                if(![[contextArray lastObject] isKindOfClass:QBLGeoData.class] && [contextArray count]){
                    contextType = [contextArray objectAtIndex:0];
                    points = [contextArray objectAtIndex:1];
                }// else{
                // this is check new one
                //}
            }
            
            // Map init
            if([contextType isKindOfClass:NSString.class] && [contextType isEqualToString:mapFBUsers]){
                
                if([result.body isKindOfClass:NSDictionary.class]){
                    NSDictionary *resultError = [result.body objectForKey:kError];
                    if(resultError != nil){
                        // all data was retrieved
                        ++self.mapInitState;
                        NSLog(@"MAP INIT FB ERROR");
                        if(self.mapInitState == 1){
                            if ([tabBarDelegate respondsToSelector:@selector(willSetAllFriendsSwitchEnabled:)]) {
                                [tabBarDelegate willSetAllFriendsSwitchEnabled:YES];
                            }

                            if ([tabBarDelegate respondsToSelector:@selector(mapEndRetrievingData)]) {

                                [tabBarDelegate mapEndOfRetrievingInitialData];
                            }
                            self.mapInitState = 0;
                        }
                        return;
                    }
                    
                    // conversation
                    NSArray *data = [NSArray arrayWithObjects:[result.body allValues], points, nil];
                    if(processCheckinsQueue == NULL){
                        processCheckinsQueue = dispatch_queue_create("com.quickblox.chattar.process.checkins.queue", NULL);
                    }
                    
                    // convert checkins
                    dispatch_async(processCheckinsQueue, ^{
                        [self processQBCheckins:data];
                    });
                    
                    // Undefined format
                }else{
                    ++self.mapInitState;
                    NSLog(@"MAP INIT FB Undefined format");
                    if(self.mapInitState == 1){
                        if ([tabBarDelegate respondsToSelector:@selector(willSetAllFriendsSwitchEnabled:)]) {
                            [tabBarDelegate willSetAllFriendsSwitchEnabled:YES];
                        }

                        if ([tabBarDelegate respondsToSelector:@selector(mapEndOfRetrievingInitialData)]) {
                            [tabBarDelegate mapEndOfRetrievingInitialData];
                        }
                        self.mapInitState = 0;
                    }
                }
                
                // Chat init
            }else if([contextType isKindOfClass:NSString.class] && [contextType isEqualToString:chatFBUsers]){
                
                if([result.body isKindOfClass:NSDictionary.class]){
                    NSDictionary *resultError = [result.body objectForKey:kError];
                    if(resultError != nil){
                        // all data was retrieved
                        ++self.chatInitState;
                        NSLog(@"CHAT INIT FB ERROR");
                        if(self.chatInitState == 1){
                            if ([tabBarDelegate respondsToSelector:@selector(willSetAllFriendsSwitchEnabled:)]) {
                                [tabBarDelegate willSetAllFriendsSwitchEnabled:YES];
                            }

                            if ([tabBarDelegate respondsToSelector:@selector(chatEndOfRetrievingInitialData)]) {
                                [tabBarDelegate chatEndOfRetrievingInitialDataInViewControllerWithIdentifier:chatViewControllerIdentifier];
                            }
                            self.chatInitState = 0;
                        }
                        return;
                    }
                    
                    // conversation
                    NSArray *data = [NSArray arrayWithObjects:[result.body allValues], points, nil];
                    if(processCheckinsQueue == NULL){
                        processCheckinsQueue = dispatch_queue_create("com.quickblox.chattar.process.checkins.queue", NULL);
                    }
                    
                    // convert checkins
                    dispatch_async(processCheckinsQueue, ^{
                        [self processQBChatMessages:data];
                    });
                    
                    // Undefined format
                }else{
                    ++self.chatInitState;
                    NSLog(@"CHAT INIT FB Undefined format");
                    if(self.chatInitState == 1){
                        if ([tabBarDelegate respondsToSelector:@selector(willSetAllFriendsSwitchEnabled:)]) {
                            [tabBarDelegate willSetAllFriendsSwitchEnabled:YES];
                        }

                        if ([tabBarDelegate respondsToSelector:@selector(chatEndOfRetrievingInitialData)]) {
                            [tabBarDelegate chatEndOfRetrievingInitialDataInViewControllerWithIdentifier:chatViewControllerIdentifier];
                        }
                        self.chatInitState = 0;
                    }
                }
                
                // check new one
            }
            else if ([context isKindOfClass:[NSArray class]]){                
                if ([tabBarDelegate respondsToSelector:@selector(willRemoveLastChatPoint)]) {
                    [tabBarDelegate willRemoveLastChatPointForViewControllerWithIdentifier:chatViewControllerIdentifier];
                }
                
                if([result.body isKindOfClass:NSDictionary.class]){
                    NSDictionary *resultError = [result.body objectForKey:kError];
                    if(resultError != nil){
                        if ([tabBarDelegate respondsToSelector:@selector(didReceiveErrorLoadingNewChatPoints)]) {
                            [tabBarDelegate didReceiveErrorLoadingNewChatPointsForViewControllerWithIdentifier:chatViewControllerIdentifier];
                        }
                        
                        return;
                    }
                    
                    if(getMoreMessagesWorkQueue == NULL){
                        getMoreMessagesWorkQueue = dispatch_queue_create("com.quickblox.chattar.process.oldmessages.queue", 0);
                    }
                    dispatch_async(getMoreMessagesWorkQueue, ^{
                        
                        // nem messages
                        for (QBLGeoData *geodata in context) {
                            
                            NSDictionary *fbUser = nil;
                            for(NSDictionary *user in [result.body allValues]){
                                if([geodata.user.facebookID isEqualToString:[user objectForKey:kId]]){
                                    fbUser = user;
                                    break;
                                }
                            }
                            
                            // add point
                            [self createAndAddNewAnnotationToMapChatARForFBUser:fbUser withGeoData:geodata addToTop:NO withReloadTable:NO];
                        }
                        
                        // refresh table
                        dispatch_async(dispatch_get_main_queue(), ^{                            
                            if ([tabBarDelegate respondsToSelector:@selector(willUpdateViewControllerIdentifier:)]) {
                                [tabBarDelegate willUpdateViewControllerIdentifier:chatViewControllerIdentifier];
                            }
                        });
                    });
                    // Undefined format
                }else{
                    // ...
                }

            }
            else if ([context isEqualToString:chatRoomUsersProfiles]){
                numberOfUserPicturesRetrieved--;
                NSArray* keys = [result.body allKeys];
                
                dispatch_queue_t userPicturesQueue = dispatch_queue_create("userPicturesQueue", NULL);
                dispatch_async(userPicturesQueue, ^{
                    [keys enumerateObjectsUsingBlock:^(NSString* key, NSUInteger idx, BOOL *stop) {
                        NSDictionary* userInfo = [result.body objectForKey:key];
                        NSLog(@"%@",userInfo);
                        NSString* userFBId = [userInfo objectForKey:kId];

                        NSDictionary* pictureDict = [userInfo objectForKey:kPicture];
                        NSDictionary* pictData = [pictureDict objectForKey:kData];
                        NSString* url = [pictData objectForKey:kUrl];
                        
                        
                        if (![DataManager shared].currentChatRoom.usersPictures) {
                            [DataManager shared].currentChatRoom.usersPictures = [[NSMutableArray alloc] init];
                        }
                        
                        NSMutableDictionary* userData = [NSMutableDictionary dictionary];
                        [userData setObject:userFBId forKey:@"userFBId"];
                        [userData setObject:url forKey:@"pictureURL"];
                        
                        [[DataManager shared].currentChatRoom.usersPictures addObject:userData];
                    }];
                });
                
                dispatch_release(userPicturesQueue);
                
                                            // this should be executed in other thread
                if (numberOfUserPicturesRetrieved == 0) {
                    // notify delegate that all photos are retrieved
                    if ([tabBarDelegate respondsToSelector:@selector(didReceiveUserProfilePicturesForViewControllerWithIdentifier:)]) {
                        [tabBarDelegate didReceiveUserProfilePicturesForViewControllerWithIdentifier:chatRoomsViewControllerIdentifier];
                    }
                    
                    if ([tabBarDelegate respondsToSelector:@selector(chatEndOfRetrievingInitialDataInViewControllerWithIdentifier:)]) {
                        [tabBarDelegate chatEndOfRetrievingInitialDataInViewControllerWithIdentifier:chatRoomsViewControllerIdentifier];
                    }
                    
                }
            }
            else{
                
                if([result.body isKindOfClass:NSDictionary.class]){
                    NSDictionary *resultError = [result.body objectForKey:kError];
                    if(resultError != nil){
                        NSLog(@"check new one FB ERROR");
                        return;
                    }
                    
                    for (QBLGeoData *geoData in context) {
                        
                        // get vk user
                        NSDictionary *fbUser = nil;
                        for(NSDictionary *user in [result.body allValues]){
                            if([geoData.user.facebookID isEqualToString:[[user objectForKey:kId] description]]){
                                fbUser = user;
                                break;
                            }
                        }
                        
                        // add new Annotation to map/chat/ar
                        [self createAndAddNewAnnotationToMapChatARForFBUser:fbUser withGeoData:geoData addToTop:YES withReloadTable:YES];
                    }
                    
                    // Undefined format
                }else{
                    // ...
                }
            }
            
            break;
        }
        default:
            break;
    }
}

-(void)completedWithFBResult:(FBServiceResult *)result
{
    NSLog(@"RESULT TYPE %d",result.queryType);
    switch (result.queryType)
    {
            // Get Friends checkins
        case FBQueriesTypesFriendsGetCheckins:{
            
            --numberOfCheckinsRetrieved;
            
            NSLog(@"numberOfCheckinsRetrieved=%d", numberOfCheckinsRetrieved);
            
            // if error, return.
            // for example:
            // {
            // "error": {
            //    "message": "Invalid OAuth access token.",
            //    "type": "OAuthException",
            //    "code": 190
            // }
            if([result.body isKindOfClass:NSDictionary.class]){
                NSDictionary *resultError = [result.body objectForKey:kError];
                if(resultError != nil){
                    NSLog(@"resultError=%@", resultError);
                    return;
                }
            }
            
            if([result.body isKindOfClass:NSArray.class]){
                if(processCheckinsQueue == NULL){
                    processCheckinsQueue = dispatch_queue_create("com.quickblox.chattar.process.checkins.queue", NULL);
                }
                // convert checkins
                dispatch_async(processCheckinsQueue, ^{
                    [self processFBCheckins:(NSArray *)result.body];
                });
            }
        }
            break;
        case FBQueriesTypesGetFriendsPhotosWithLocation:{
            if ([result.body isKindOfClass:[NSDictionary class]]) {
                NSDictionary* resultError = [result.body objectForKey:kError];
                if (resultError) {
                    NSLog(@"resultError=%@",resultError);
                    return;
                }
            }
            
            if (processPhotosWithLocationsQueue == NULL) {
                processPhotosWithLocationsQueue = dispatch_queue_create("com.quickblox.chattar.process.photos.queue", NULL);
            }
            dispatch_async(processPhotosWithLocationsQueue, ^{
                [self processPhotosWithLocations:(NSDictionary*)result.body];
            });
        }
            break;
            
        case FBQueriesTypesGetInboxMessages:{
                // get inbox messages
            if(![result.body isKindOfClass:NSDictionary.class]){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                                                message:@"Something went wrong, please restart application"
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
                return;
            }
            
            NSArray *resultData = [result.body objectForKey:kData];
            NSDictionary *resultError = [result.body objectForKey:kError];
            if(resultError && !resultData){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Facebook: %@", [resultError objectForKey:@"type"]]
                                                                message:[resultError objectForKey:@"message"]
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
                
                return;
            }
            
            NSMutableDictionary* conversations = [[[NSMutableDictionary alloc] init] autorelease];
            // each inbox message
            NSMutableSet* popularFriendsIDs = [[[NSMutableSet alloc] init] autorelease];
            
            for(NSDictionary *inboxConversation in resultData)
            {
                if([inboxConversation objectForKey:kComments] == nil){
                    continue;
                }
                
                // crop own id and name
                NSMutableArray *to = [[[[inboxConversation objectForKey:kTo] objectForKey:kData] mutableCopy] autorelease];
                
                // skip multiple conversations
                if ([to count] > 2){
                    continue;
                }
                
                // remove self from 'To'
                for(int i = 0; i<[to count]; i++){
                    if([[[to objectAtIndex:i] objectForKey:kId] isEqualToString:[DataManager shared].currentFBUserId]){
                        [to removeObject:[to objectAtIndex:i]];
                    }
                }
                if([to count] == 0){
                    continue;
                }
                
                // create and add conversation
                Conversation *conersation = [[Conversation alloc] init];
                conersation.to = [to objectAtIndex:0];
                                
                [popularFriendsIDs addObject:[conersation.to objectForKey:kId]];
                
                // add comments
                if([inboxConversation objectForKey:kComments]){
                    conersation.messages = [[[[inboxConversation objectForKey:kComments] objectForKey:kData] mutableCopy] autorelease];
                }else{
                    NSMutableArray *emptryArray = [[NSMutableArray alloc] init];
                    conersation.messages = emptryArray;
                    [emptryArray release];
                }
                                
                [conversations setValue:conersation forKey:[conersation.to objectForKey:kId]];
                [conersation release];
            }
            
            if ([tabBarDelegate respondsToSelector:@selector(didReceiveInboxMessages:andPopularFriends:)]) {
                [tabBarDelegate didReceiveInboxMessages:conversations andPopularFriends:popularFriendsIDs];
            }
        }
            break;
        case FBQueriesTypesFriendsGet:{
            if(![result.body isKindOfClass:NSDictionary.class]){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                                                message:@"Something went wrong, please restart application"
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
                        
                return;
            }
                        
            if (!FBfriends) {
                FBfriends = [[NSMutableArray alloc] init];
            }
            
            [FBfriends addObjectsFromArray:[result.body objectForKey:kData]];
            
            // add online/offline & favs keys
            for (int i = 0; i < FBfriends.count; i++) {
                [[FBfriends objectAtIndex:i] setObject:kOffline forKey:kOnOffStatus];
                [[FBfriends objectAtIndex:i] setObject:[NSNumber numberWithBool:NO] forKey:kFavorites];
            }
            
            if ([tabBarDelegate respondsToSelector:@selector(didReceiveAllFriends:)]) {
                [tabBarDelegate didReceiveAllFriends:FBfriends];
            }
            

        }
            break;
        case FBQueriesTypesWall:{
            if(![result.body isKindOfClass:NSDictionary.class]){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook"
                                                                message:@"Something went wrong, please restart application"
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
                [alert release];
                
                return;
            }
            
            NSArray *feeds = [result.body objectForKey:kData];
            NSLog(@"%@",result.body);
            
            NSMutableDictionary* friendsAsDictionary = [[NSMutableDictionary alloc] init];
            for (NSDictionary* user in FBfriends){
                [friendsAsDictionary setObject:user forKey:[user objectForKey:kId]];
            }

            
            NSMutableSet* popularFriends = [[NSMutableSet alloc] init];
            
            NSArray *friendsIds = [[friendsAsDictionary allKeys] copy];
            [friendsAsDictionary release];
            NSLog(@"%@",friendsIds);
            
            
            for(NSDictionary *feed in feeds){
                NSArray *likes = [[feed objectForKey:kLikes] objectForKey:kData];
                NSDictionary *comments = [[feed objectForKey:kComments] objectForKey:kData];
                
                if(likes == nil && comments == nil){
                    continue;
                }
                
                if([popularFriends.allObjects count] > maxPopularFriends){
                    break;
                }
                
                // add likes
                if(likes != nil){
                    for(NSDictionary *like in likes){
                        NSString *userID = [like objectForKey:kId];
                        if([friendsIds containsObject:userID]){
                            // add popular friend's ID
                            [popularFriends addObject:userID];
                        }
                    }
                }
                
                // add comments
                if(comments != nil){
                    for(NSDictionary *comment in comments){
                        NSString *userID = [[comment objectForKey:kFrom] objectForKey:kId];
                        if([friendsIds containsObject:userID]){
                            // add popular friend's ID
                            [popularFriends addObject:userID];
                        }
                    }
                }
            }
            
            [friendsIds release];
            
            if ([tabBarDelegate respondsToSelector:@selector(didReceivePopularFriends:)]) {
                [tabBarDelegate didReceivePopularFriends:popularFriends];
            }
            [popularFriends release];
        }
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Adding Methods

-(void)createAndAddNewAnnotationToChatForFBUser:(NSDictionary*)fbUser withQBChatMessage:(QBChatMessage*)message addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable{
    UserAnnotation* newAnnotation = [[DataManager shared] convertQBMessageToUserAnnotation:message];
    
    if ([tabBarDelegate respondsToSelector:@selector(willAddNewMessageToChat:addToTop:withReloadTable:isFBCheckin:viewControllerIdentifier:)]) {
        [tabBarDelegate willAddNewMessageToChat:newAnnotation
                                       addToTop:toTop
                                       withReloadTable:reloadTable
                                       isFBCheckin:NO
                                       viewControllerIdentifier:chatRoomsViewControllerIdentifier];
    }

}


// Add Quote data to annotation
- (void)addQuoteDataToAnnotation:(UserAnnotation *)annotation geoData:(QBLGeoData *)geoData{
    // get quoted geodata
    annotation.userStatus = [geoData.status substringFromIndex:[geoData.status rangeOfString:quoteDelimiter].location+1];
    
    // Author FB id
    NSString* authorFBId = [[geoData.status substringFromIndex:6] substringToIndex:[geoData.status rangeOfString:nameIdentifier].location-6];
    annotation.quotedUserFBId = authorFBId;
    
    // Author name
    NSString* authorName = [[geoData.status substringFromIndex:[geoData.status rangeOfString:nameIdentifier].location+6] substringToIndex:[[geoData.status substringFromIndex:[geoData.status rangeOfString:nameIdentifier].location+6] rangeOfString:dateIdentifier].location];
    annotation.quotedUserName = authorName;
    
    // origin Message date
    NSString* date = [[geoData.status substringFromIndex:[geoData.status rangeOfString:dateIdentifier].location+6] substringToIndex:[[geoData.status substringFromIndex:[geoData.status rangeOfString:dateIdentifier].location+6] rangeOfString:photoIdentifier].location];
    //
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd HH':'mm':'ss Z"];
    annotation.quotedMessageDate = [formatter dateFromString:date];
    [formatter release];
    
    // authore photo
    NSString* photoLink = [[geoData.status substringFromIndex:[geoData.status rangeOfString:photoIdentifier].location+7] substringToIndex:[[geoData.status substringFromIndex:[geoData.status rangeOfString:photoIdentifier].location+7] rangeOfString:qbidIdentifier].location];
    annotation.quotedUserPhotoURL = photoLink;
    
    // Authore QB id
    NSString* authorQBId = [[geoData.status substringFromIndex:[geoData.status rangeOfString:qbidIdentifier].location+6] substringToIndex:[[geoData.status substringFromIndex:[geoData.status rangeOfString:qbidIdentifier].location+6] rangeOfString:messageIdentifier].location];
    annotation.quotedUserQBId = authorQBId;
    
    // origin message
    NSString* message = [[geoData.status substringFromIndex:[geoData.status rangeOfString:messageIdentifier].location+5] substringToIndex:[[geoData.status substringFromIndex:[geoData.status rangeOfString:messageIdentifier].location+5] rangeOfString:quoteDelimiter].location];
    annotation.quotedMessageText = message;
}

- (void)createAndAddNewAnnotationToMapChatARForFBUser:(NSDictionary *)fbUser withGeoData:(QBLGeoData *)geoData addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable{
    
    // create new user annotation
    UserAnnotation *newAnnotation = [[UserAnnotation alloc] init];
    newAnnotation.geoDataID = geoData.ID;
    newAnnotation.coordinate = geoData.location.coordinate;
	
	if ([geoData.status length] >= 6){
		if ([[geoData.status substringToIndex:6] isEqualToString:fbidIdentifier]){
            // add Quote
            [self addQuoteDataToAnnotation:newAnnotation geoData:geoData];
            
		}else {
			newAnnotation.userStatus = geoData.status;
		}
        
	}else {
		newAnnotation.userStatus = geoData.status;
	}
	
    newAnnotation.userName = [fbUser objectForKey:kName];
    newAnnotation.userPhotoUrl = [fbUser objectForKey:kPicture];
    newAnnotation.fbUserId = [fbUser objectForKey:kId];
    newAnnotation.fbUser = fbUser;
    newAnnotation.qbUserID = geoData.user.ID;
    if(newAnnotation.qbUserID == 0){
        newAnnotation.qbUserID = geoData.userID;
    }
	newAnnotation.createdAt = geoData.createdAt;
    
    newAnnotation.distance  = [geoData.location distanceFromLocation:locationManager.location];
    
    if(newAnnotation.coordinate.latitude == 0.0f && newAnnotation.coordinate.longitude == 0.0f)
    {
        newAnnotation.distance = 0;
    }
        
    if ([tabBarDelegate respondsToSelector:@selector(willAddNewMessageToChat:addToTop:withReloadTable:isFBCheckin:)]) {
        [tabBarDelegate willAddNewMessageToChat:newAnnotation addToTop:toTop withReloadTable:reloadTable isFBCheckin:NO viewControllerIdentifier:chatViewControllerIdentifier];
    }
       
    
    if(newAnnotation.coordinate.latitude == 0.0f && newAnnotation.coordinate.longitude == 0.0f){
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([tabBarDelegate respondsToSelector:@selector(willUpdatePointStatus:)]) {
                [tabBarDelegate willUpdatePointStatus:newAnnotation];
            }
        });
    }else{
        // Add to Map
        dispatch_async( dispatch_get_main_queue(), ^{
            if ([tabBarDelegate respondsToSelector:@selector(willAddNewPoint:isFBCheckin:)]) {
                [tabBarDelegate willAddNewPoint:[[newAnnotation copy] autorelease] isFBCheckin:NO];
            }
        });        
    }
    
	[newAnnotation release];
}

#pragma mark -
#pragma mark QBChatDelegate methods
-(void)chatDidReceiveListOfRooms:(NSArray *)rooms{
            // retain rooms
    [rooms retain];
    if ([tabBarDelegate respondsToSelector:@selector(didReceiveChatRooms:forViewControllerWithIdentifier:)]) {
        [tabBarDelegate didReceiveChatRooms:rooms forViewControllerWithIdentifier:chatRoomsViewControllerIdentifier];
    }
}

-(void)chatRoomDidReceiveMessage:(QBChatMessage *)message fromRoom:(NSString *)roomName{
    ChatRoom* room = [[DataManager shared] findRoomWithAdditionalInfo:roomName];
    if (room) {
        if (!room.messagesHistory) {
            room.messagesHistory = [[NSMutableArray alloc] init];
        }
        if (message.text.length > 0 && message.text) {
            [room.messagesHistory addObject:message];
                        
            if (room.isSendingMessage) {
                if ([tabBarDelegate respondsToSelector:@selector(willClearMessageFieldInViewControllerWithIdentifier:)]) {
                    [tabBarDelegate willClearMessageFieldInViewControllerWithIdentifier:chatRoomsViewControllerIdentifier];
                }
                
                if ([tabBarDelegate respondsToSelector:@selector(didSuccessfulMessageSendingInViewControllerWithIdentifier:)]) {
                    [tabBarDelegate didSuccessfulMessageSendingInViewControllerWithIdentifier:chatRoomsViewControllerIdentifier];
                }
                
                if ([tabBarDelegate respondsToSelector:@selector(willScrollToTopInViewControllerWithIdentifier:)]) {
                    [tabBarDelegate willScrollToTopInViewControllerWithIdentifier:chatRoomsViewControllerIdentifier];
                }
                
                [self createAndAddNewAnnotationToChatForFBUser:[DataManager shared].currentFBUser withQBChatMessage:message addToTop:YES withReloadTable:YES];
                
                room.isSendingMessage = NO;
            }
        }

    }
    
}

-(void)chatRoomDidEnter:(QBChatRoom *)room{
    NSLog(@"%@",@"ROOM ENTER OR CREATE!");
    
                        // if this is new room
    if (! [[DataManager shared] roomWithNameHasAdditionalInfo:room.roomName] ) {
        QBCOCustomObject* roomRecord = [QBCOCustomObject customObject];
        roomRecord.className = @"Room";
        
        // create object for storing room on server
        [roomRecord.fields setObject:room.roomName forKey:@"xmppName"];
        [roomRecord.fields setObject:[NSNumber numberWithDouble:locationManager.location.coordinate.latitude] forKey:@"latitude"];
        [roomRecord.fields setObject:[NSNumber numberWithDouble:locationManager.location.coordinate.longitude] forKey:@"longitude"];
        
        [QBCustomObjects createObject:roomRecord delegate:self];
        
            // add room to storage
        [[DataManager shared].qbChatRooms addObject:room];
    }
                        // join to already existing room
    else{
        NSString* nonXMPPRoomName = [Helper createTitleFromXMPPTitle:room.roomName];
        if ([[DataManager shared].currentChatRoom.roomName isEqualToString:nonXMPPRoomName]) {
            
            if (![DataManager shared].currentChatRoom.roomUsers) {
                [DataManager shared].currentChatRoom.roomUsers = [[NSMutableArray alloc] init];
            }
            
            [[DataManager shared].currentChatRoom.roomUsers addObject:[DataManager shared].currentQBUser];
        }
        
        if ([tabBarDelegate respondsToSelector:@selector(didEnterExistingRoomForViewControllerWithIdentifier:)]) {
            [tabBarDelegate didEnterExistingRoomForViewControllerWithIdentifier:chatRoomsViewControllerIdentifier];
        }
    }
}

-(void)chatRoomDidReceiveListOfUsers:(NSArray *)users room:(NSString *)roomName{
    ChatRoom* chatRoom = [[DataManager shared] findRoomWithAdditionalInfo:roomName];
    
    if (chatRoom) {
        if (!chatRoom.roomUsers) {
            chatRoom.roomUsers = [[NSMutableArray alloc] init];
        }
    
        [chatRoom.roomUsers removeAllObjects];
        [chatRoom.roomUsers addObjectsFromArray:users];
    }
    
}

#pragma mark -
#pragma mark ChatRooms helper methods

-(void)retrieveNumberOfUsersInEachRoom{
    for (QBChatRoom* room in [DataManager shared].qbChatRooms) {
        [[QBChat instance] requestRoomOnlineUsers:room];
    }
}

-(void)calculateDistancesForEachRoom{
    CLLocationCoordinate2D currentLocation = locationManager.location.coordinate;
    for (ChatRoom* room in [DataManager shared].roomsWithAdditionalInfo) {
        CLLocation* firstLocation = [[[CLLocation alloc] initWithLatitude:room.ownerLocation.latitude longitude:room.ownerLocation.longitude] autorelease];
        CLLocation* secondLocation = [[[CLLocation alloc] initWithLatitude:currentLocation.latitude longitude:currentLocation.longitude] autorelease];
        CLLocationDistance distance = [firstLocation distanceFromLocation:secondLocation];
        [room setDistanceFromUser:distance];
    }
}

#pragma mark -
#pragma mark Helpers
- (UserAnnotation *)lastChatMessage:(BOOL)ignoreOwn{
    if(ignoreOwn){
        for(UserAnnotation *chatAnnotation in [DataManager shared].chatPoints){
            if(![chatAnnotation.fbUserId isEqualToString:[DataManager shared].currentFBUserId]){
                return chatAnnotation;
            }
        }
    }else{
        return ((UserAnnotation *)[[DataManager shared].chatPoints objectAtIndex:0]);
    }
    
    return nil;
}

#pragma mark -
#pragma mark Logout
-(void)stopRequestingNewData{
    if(updateTimer){
        [updateTimer invalidate];
        [updateTimer release];
        updateTimer = nil;
    }
}


@end