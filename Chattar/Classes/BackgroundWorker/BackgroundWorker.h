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
#import "Storage.h"
#import "ChatPointsStorage.h"
#import "ChatRoomsStorage.h"
                        // delegates
@protocol ChatControllerDelegate <NSObject>

@optional
-(void)willUpdateViewControllerIdentifier:(NSString*)identifier;
-(void)willAddNewMessageToChat:(UserAnnotation*)annotation
                                                addToTop:(BOOL)toTop
                                                withReloadTable:(BOOL)reloadTable
                                                isFBCheckin:(BOOL)isFBCheckin
                                                viewControllerIdentifier:(NSString*)identifier;

-(void)willClearMessageFieldInViewControllerWithIdentifier:(NSString*)identifier;
-(void)didSuccessfulMessageSendingInViewControllerWithIdentifier:(NSString*)identifier;
-(void)willScrollToTopInViewControllerWithIdentifier:(NSString*)identifier;
-(void)willSetEnabledMessageField:(BOOL)enabled viewControllerWithIdentifier:(NSString*)identifier;
-(void)willSetAllFriendsSwitchEnabled:(BOOL)switchEnabled InViewControllerWithIdentifier:(NSString*)identifier;
-(void)chatEndOfRetrievingInitialDataInViewControllerWithIdentifier:(NSString*)identifier;

-(void)didNotReceiveNewFBChatUsersInViewControllerWithIdentifier:(NSString*)identifier;
-(void)didNotReceiveNewChatPointsForViewControllerWithIdentifier:(NSString*)identifier;
-(void)willRemoveLastChatPointForViewControllerWithIdentifier:(NSString*)identifier;
-(void)didReceiveErrorLoadingNewChatPointsForViewControllerWithIdentifier:(NSString*)identifier;

@end

@protocol DataDelegate <NSObject>

@optional
-(void)chatDidReceiveAllCachedData:(NSDictionary*)cachedData;

-(void)didReceiveError:(NSString*)errorMessage;
-(void) willAddNewPoint:(UserAnnotation*)point isFBCheckin:(BOOL)isFBCheckin;
-(void) willSaveMapARPoints:(NSArray*)newMapPoints;
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
-(void)didReceiveChatRooms:(NSArray*)chatRooms forViewControllerWithIdentifier:(NSString*)identifier;
-(void)didReceiveAdditionalServerInfo:(NSArray*)additionalInfo;
-(void)didReceiveRoomsOccupantsNumberForViewControllerWithIdentifier:(NSString*)identifier;
-(void)didEnterExistingRoomForViewControllerWithIdentifier:(NSString*)identifier;
-(void)didReceiveUserProfilePicturesForViewControllerWithIdentifier:(NSString*)identifier;

-(void)didReceiveMessageForViewControllerWithIdentifier:(NSString*)identifier;
-(void)didCreateNewChatRoom:(NSString*)roomName viewControllerWithIdentifier:(NSString*)identifier;
-(void)refreshRecipientsPicturesWithControllerIdentifier:(NSString*)identifier;
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
@property (assign) NSInteger numberOfUserPicturesRetrieved;

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

-(void)retrieveNumberOfUsersInEachRoom;

-(void)calculateDistancesForEachRoom;

-(void)joinRoom:(QBChatRoom*)room;

-(void)requestUsersPictures;

-(void)requestDataForDataStorage:(Storage*)dataStorage;

-(void)postInformationWithDataStorage:(Storage*)dataStorage;

-(void)requestMessagesRecipientsPictures;

-(void)exitChatRoom:(QBChatRoom*)room;

@end
