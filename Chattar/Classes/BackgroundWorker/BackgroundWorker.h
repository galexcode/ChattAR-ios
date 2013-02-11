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

                        // delegates
@protocol ChatControllerDelegate <NSObject>

@optional
-(void)willUpdate;
-(void)willAddNewMessageToChat:(UserAnnotation*)annotation addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable isFBCheckin:(BOOL)isFBCheckin;
-(void)willClearMessageField;
-(void)didSuccessfulMessageSending;
-(void)willScrollToTop;
@end

@protocol QBDataDelegate <NSObject>
@optional

@end

@protocol DataDelegate <NSObject>

@optional
-(void)didReceiveError:(NSString*)errorMessage;

-(void) didReceiveCachedMapPoints:(NSArray*)cachedMapPoints;
-(void) didReceiveCachedMapPointsIDs:(NSArray*)cachedMapIDs;
-(void) willAddNewPoint:(UserAnnotation*)point isFBCheckin:(BOOL)isFBCheckin;
-(void) willSaveMapARPoints:(NSArray*)newMapPoints;
-(void)didNotReceiveNewChatPoints;
-(void)willRemoveLastChatPoint;
-(void)didReceiveErrorLoadingNewChatPoints;
-(void)didReceiveCachedChatPoints:(NSArray*)cachedChatPoints;
-(void)didReceiveCachedChatMessagesIDs:(NSArray*)cachedChatMessagesIDs;
-(void)willShowAllFriends;

-(void)endOfRetrievingInitialData;
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
@end

@protocol ARControllerDelegate <NSObject>

@optional
-(void)willUpdateMarkersForCenterLocation;
-(void)willAddMarker;
@end




@interface BackgroundWorker : NSObject<QBActionStatusDelegate,FBRequestDelegate,FBServiceResultDelegate>{
    NSTimer* updateTimer;
    
    
    dispatch_queue_t processCheckinsQueue;
    
    dispatch_queue_t processPhotosWithLocationsQueue;
    
    dispatch_queue_t getMoreMessagesWorkQueue;

    NSDate *lastMessageDate;
    NSDate* lastPointDate;
    
    CLLocation* currentLocation;
    
}

@property (nonatomic, assign) id<FBDataDelegate,DataDelegate,QBDataDelegate,MapControllerDelegate,ChatControllerDelegate,ARControllerDelegate> tabBarDelegate;

@property (nonatomic, retain) NSMutableArray* FBfriends;
@property (assign) short initState;                 // 2 if all data(map/chat) was retrieved
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
@end
