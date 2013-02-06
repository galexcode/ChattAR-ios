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
                        // delegates
@protocol ChatControllerDelegate <NSObject>

@optional
-(void)willUpdate;
-(void)willAddNewMessageToChat:(UserAnnotation*)annotation addToTop:(BOOL)toTop withReloadTable:(BOOL)reloadTable isFBCheckin:(BOOL)isFBCheckin;
@end

@protocol QBDataDelegate <NSObject>
@optional

-(void)didReceiveCachedChatPoints:(NSArray*)cachedChatPoints;
-(void)didReceiveCachedChatMessagesIDs:(NSArray*)cachedChatMessagesIDs;

@end

@protocol DataDelegate <NSObject>

@optional
-(void)didReceiveError;
-(void)chatEndRetrievingData;
-(void)mapEndRetrievingData;

@end


@protocol FBDataDelegate <NSObject>
@optional
-(void)didReceiveFBCheckins:(NSArray*)fbCheckins;
-(void)didReceiveNewPhotosWithlocations:(NSArray*)photosWithLocations;
-(void)didReceiveCachedPhotosWithLocations:(NSArray*)photosWithLocations;
-(void)didReceivePopularFriends:(NSMutableSet*)popFriends;
-(void)didReceiveInboxMessages:(NSDictionary*)inboxMessages;
-(void)didReceiveAllFriends:(NSArray*)allFriends;
@end

@protocol MapControllerDelegate <NSObject>

@optional
-(void) didReceiveCachedMapPoints:(NSArray*)cachedMapPoints;
-(void) didReceiveCachedMapPointsIDs:(NSArray*)cachedMapIDs;
-(void) willAddNewPoint:(UserAnnotation*)point isFBCheckin:(BOOL)isFBCheckin;
-(void) willUpdatePointStatus:(UserAnnotation*)newPoint;
-(void) willSaveMapARPoints:(NSArray*)newMapPoints;
@end




@interface BackgroundWorker : NSObject<QBActionStatusDelegate,FBRequestDelegate,FBServiceResultDelegate>{
    NSTimer* updateTimer;
    short numberOfCheckinsRetrieved;
    
    dispatch_queue_t processCheckinsQueue;
    
    dispatch_queue_t processPhotosWithLocationsQueue;
    
    NSDate *lastMessageDate;
    NSDate* lastPointDate;
    
}

@property (nonatomic, assign) id<FBDataDelegate, QBDataDelegate, MapControllerDelegate,  DataDelegate> mapDelegate;
@property (nonatomic, assign) id<FBDataDelegate, QBDataDelegate, ChatControllerDelegate, DataDelegate> chatDelegate;
@property (nonatomic, assign) id<FBDataDelegate> tabBarDelegate;
@property (nonatomic, retain) NSMutableArray* FBfriends;
@property (assign) short chatInitState; // 2 if all data(map/chat) was retrieved
@property (assign) short mapInitState;

+(BackgroundWorker*)instance;

-(void)requestFBInfo;
-(void)requestFriends;
-(void)requestPopularFriends;
-(void)retrieveCachedChatDataAndRequestNewData;
-(void)retrieveCachedMapDataAndRequestNewData;

@end
