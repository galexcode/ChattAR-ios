//
//  DataManager.h
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 04.05.12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserAnnotation.h"
#define maxPopularFriends 40

@interface DataManager : NSObject{
    // Core Data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSMutableArray* photosWithLocations;
}

// FB access
@property (nonatomic, retain) NSString				*accessToken;
@property (nonatomic, retain) NSDate				*expirationDate;

// current User
@property (nonatomic, retain) QBUUser				*currentQBUser;
@property (nonatomic, retain) NSMutableDictionary	*currentFBUser;
@property (nonatomic, retain) NSString				*currentFBUserId;

// friends
@property (nonatomic, retain) NSMutableArray		*myFriends;
@property (nonatomic, retain) NSMutableDictionary	*myFriendsAsDictionary;
@property (nonatomic, retain) NSMutableSet		    *myPopularFriends;

// messages
@property (nonatomic, retain) NSMutableDictionary	*historyConversation;
@property (nonatomic, retain) NSMutableArray	    *historyConversationAsArray;

// Core Data
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Controllers Data
@property (nonatomic, retain) NSMutableArray* chatPoints;
@property (nonatomic, retain) NSMutableArray* allChatPoints;
@property (nonatomic, retain) NSMutableArray* chatMessagesIDs;

@property (nonatomic, retain) NSMutableArray* allCheckins;

@property (nonatomic, retain) NSMutableArray* mapPointsIDs;
@property (nonatomic, retain) NSMutableArray* allmapPoints;
@property (nonatomic, retain) NSMutableArray* mapPoints;

@property (nonatomic, retain) NSMutableArray *coordinateViews;
@property (nonatomic, retain) NSMutableArray* coordinates;

@property (nonatomic, retain) NSString* currentRequestingDataControllerTitle;

@property (nonatomic, retain) NSMutableArray* allChatRooms;
@property (nonatomic, retain) NSMutableArray* trendingChatRooms;
@property (nonatomic, retain) NSMutableArray* nearbyChatRooms;

+ (DataManager *) shared;

- (void)sortMessagesArray;

- (void)clearCache;

#pragma mark -
#pragma mark Friends

- (void)makeFriendsDictionary;
- (void)addPopularFriendID:(NSString *)friendID;

#pragma mark -
#pragma mark FB

- (void) saveFBToken:(NSString *)token andDate:(NSDate *)date;
- (void)clearFBAccess;
- (NSDictionary *) fbUserTokenAndDate;


#pragma mark -
#pragma mark Favorities friends

-(NSMutableArray *) favoritiesFriends;
-(void) addFavoriteFriend: (NSString *)_friendID;
-(void) removeFavoriteFriend: (NSString *)_friendID;
-(BOOL) friendIDInFavorities:(NSString *)_friendID;


#pragma mark -
#pragma mark First switch All/Friends

- (BOOL)isFirstStartApp;
- (void)setFirstStartApp:(BOOL)firstStartApp;


#pragma mark -
#pragma mark QuickBlox Quote

- (NSString *)originMessageFromQuote:(NSString *)quote;
- (NSString *)messageFromQuote:(NSString *)quote;


#pragma mark -
#pragma mark Core Data api

-(NSArray *)chatMessagesFromStorage;
-(void)addChatMessagesToStorage:(NSArray *)messages;
-(void)addChatMessageToStorage:(id)message;

-(NSArray *)mapARPointsFromStorage;
-(void)addMapARPointsToStorage:(NSArray *)points;
-(void)addMapARPointToStorage:(id)point; 

-(NSArray *)checkinsFromStorage;
-(void)addCheckinsToStorage:(NSArray *)checkins;
-(BOOL)addCheckinToStorage:(id)checkins;

-(void) deleteAllObjects: (NSString *) entityDescription  context:(NSManagedObjectContext *)ctx;

-(NSMutableArray*)photosWithLocationsFromStorage;
-(void)addPhotosWithLocationsToStorage:(NSArray*)photos;
-(BOOL)addPhotoWithLocationsToStorage:(id)photo;

-(NSArray*)photosWithLocationsFromStorageFromUserWithId:(NSDecimalNumber*)userId;

@end
