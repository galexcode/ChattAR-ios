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
-(void)chatEndRetrievingData;
-(void)mapEndRetrievingData;

-(void) didReceiveCachedMapPoints:(NSArray*)cachedMapPoints;
-(void) didReceiveCachedMapPointsIDs:(NSArray*)cachedMapIDs;
-(void) willAddNewPoint:(UserAnnotation*)point isFBCheckin:(BOOL)isFBCheckin;
-(void) willSaveMapARPoints:(NSArray*)newMapPoints;
-(void)didNotReceiveNewChatPoints;
-(void)willRemoveLastChatPoint;
-(void)didReceiveErrorLoadingNewChatPoints;
-(void)didReceiveCachedChatPoints:(NSArray*)cachedChatPoints;
-(void)didReceiveCachedChatMessagesIDs:(NSArray*)cachedChatMessagesIDs;

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




@interface BackgroundWorker : NSObject<QBActionStatusDelegate,FBRequestDelegate,FBServiceResultDelegate>{
    NSTimer* updateTimer;
    short numberOfCheckinsRetrieved;
    
    dispatch_queue_t processCheckinsQueue;
    
    dispatch_queue_t processPhotosWithLocationsQueue;
    
    dispatch_queue_t getMoreMessagesWorkQueue;

    NSDate *lastMessageDate;
    NSDate* lastPointDate;
    
}

@property (nonatomic, assign) id<FBDataDelegate,DataDelegate,QBDataDelegate,MapControllerDelegate,ChatControllerDelegate> tabBarDelegate;

@property (nonatomic, retain) NSMutableArray* FBfriends;
@property (assign) short chatInitState;                 // 2 if all data(map/chat) was retrieved
@property (assign) short mapInitState;

+(BackgroundWorker*)instance;

-(void)requestFBHistory;
-(void)requestFriends;
-(void)requestPopularFriends;
-(void)retrieveCachedChatDataAndRequestNewData;
-(void)retrieveCachedMapDataAndRequestNewData;
-(void)retrieveMoreChatMessages:(NSInteger)page;
-(void)requestFriendWithFacebookID:(NSString*)fbID andMessageText:(NSString*)message;
-(void)postGeoData:(QBLGeoData*)geoData;
@end
