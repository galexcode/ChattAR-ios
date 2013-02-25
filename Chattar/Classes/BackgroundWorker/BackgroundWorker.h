//
//  BackgroundWorker.h
//  Chattar
//
//  Created by kirill on 2/4/13.
//
//

#import <Foundation/Foundation.h>
#import "QBChatMessageModel.h"
#import "QBCheckinModel.h"
#import "FBCheckinModel.h"
#import "PhotoWithLocationModel.h"
#import "UserAnnotation.h"
#import "JSON.h"
#import "ProvisionManager.h"
#import "ChatRoom.h"

                        // delegates
@protocol ChatControllerDelegate <NSObject>

@optional
-(void)willUpdate;
-(void)willAddNewMessageToChat:(UserAnnotation*)annotation addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable isFBCheckin:(BOOL)isFBCheckin;
-(void)willClearMessageField;
-(void)didSuccessfulMessageSending;
-(void)willScrollToTop;
-(void)willSetEnabledMessageField:(BOOL)enabled;
-(void)willSetAllFriendsSwitchEnabled:(BOOL)switchEnabled;
-(void)chatEndOfRetrievingInitialData;

-(void)chatDidReceiveAllCachedData:(NSDictionary*)cachedData;
-(void)didNotReceiveNewFBChatUsers;
@end

@protocol DataDelegate <NSObject>

@optional
-(void)didReceiveError:(NSString*)errorMessage;
-(void) willAddNewPoint:(UserAnnotation*)point isFBCheckin:(BOOL)isFBCheckin;
-(void) willSaveMapARPoints:(NSArray*)newMapPoints;
-(void)didNotReceiveNewChatPoints;
-(void)willRemoveLastChatPoint;
-(void)didReceiveErrorLoadingNewChatPoints;
-(void)willShowAllFriends;

@end


@protocol FBDataDelegate <NSObject>
@optional
-(void)didReceiveNewPhotosWithlocations:(NSArray*)photosWithLocations;
-(void)didReceiveCachedPhotosWithLocations:(NSArray*)photosWithLocations;
-(void)didReceivePopularFriends:(NSMutableSet*)popFriends;
-(void)didReceiveInboxMessages:(NSDictionary*)inboxMessages andPopularFriends:(NSSet*)popFriends;
-(void)didReceiveAllFriends:(NSArray*)allFriends;
-(void)didReceiveCachedCheckins:(NSArray*)cachedCheckins;
-(void)willAddCheckin:(UserAnnotation*)checkin;
@end

@protocol MapControllerDelegate <NSObject>

@optional
-(void) willUpdatePointStatus:(UserAnnotation*)newPoint;
-(void)willSetAllFriendsSwitchEnabled:(BOOL)switchEnabled;
-(void)mapEndOfRetrievingInitialData;
-(void)mapDidReceiveAllCachedData:(NSDictionary*)allMapData;
-(void)didNotReceiveNewFBMapUsers;
@end

@protocol ARControllerDelegate <NSObject>
@optional
-(void)willUpdateMarkersForCenterLocation;
-(void)willAddMarker;
-(void)willSetEnabledDistanceSlider:(BOOL)sliderEnabled;
-(void)willSetAllFriendsSwitchEnabled:(BOOL)switchEnabled;
-(void)didNotReceiveNewARUsers;
@end

@protocol ChatRoomDataDelegate <NSObject>

@optional
-(void)didReceiveChatRooms:(NSArray*)chatRooms;
-(void)didReceiveAdditionalServerInfo:(NSArray*)additionalInfo;
-(void)didReceiveRoomsOccupantsNumber;
@end


@interface BackgroundWorker : NSObject<QBActionStatusDelegate,FBRequestDelegate,FBServiceResultDelegate, QBChatDelegate, CLLocationManagerDelegate>{
    NSTimer* updateTimer;
    
    
    dispatch_queue_t processCheckinsQueue;
    
    dispatch_queue_t processPhotosWithLocationsQueue;
    
    dispatch_queue_t getMoreMessagesWorkQueue;
        
    CLLocationManager* locationManager;
    
}

@property (nonatomic, assign) id<FBDataDelegate,DataDelegate,MapControllerDelegate,ChatControllerDelegate,ARControllerDelegate,ChatRoomDataDelegate> tabBarDelegate;

@property (nonatomic, retain) NSMutableArray* FBfriends;
@property (assign) short chatInitState;
@property (assign) short mapInitState;
@property (assign) short numberOfCheckinsRetrieved;


+(BackgroundWorker*)instance;

-(void)requestFBHistory;
-(void)requestFriends;
-(void)requestPopularFriends;
-(void)retrieveCachedChatDataAndRequestNewData;
-(void)retrieveCachedMapDataAndRequestNewData;
-(void)retrieveMoreChatMessages:(NSInteger)page;
-(void)requestFriendWithFacebookID:(NSString*)fbID andMessageText:(NSString*)message;
-(void)postGeoData:(QBLGeoData*)geoData;
- (void)retrieveCachedFBCheckinsAndRequestNewCheckins;

-(void)requestAllChatRooms;
-(void)requestAdditionalChatRoomsInfo;
-(void)createChatRoom:(NSString*)chatRoomName;
-(void)requestNumberOfUsersInRoom:(QBChatRoom*)room;

-(void)requestRoomOccupants:(NSString*)roomName;

-(void)retrieveNumberOfUsersInEachRoom;

-(void)calculateDistancesForEachRoom;
@end
