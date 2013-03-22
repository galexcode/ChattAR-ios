//
//  Constants.h
//  ChattAR
//
//  Created by QuickBlox developers on 04.05.12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

// FB constants
#define FBAccessTokenKey @"FBAccessTokenKey"
#define FBExpirationDateKey @"FBExpirationDateKey"
//
// FB Chattar
#define APP_ID @"464189473609303"
#define FB_COOKIES @"FB_COOKIES"

// notifications
#define kNotificationLogout @"kNotificationLogout"
#define kNewChatMessageCome @"kNewChatMessageCome"
#define kReceivedOnlineStatus @"kReceivedOnlineStatus"

#define kCachedMapPoints @"kCachedMapPoints"
#define kCachedMapPointsIDs @"kCachedMapPoints"
#define kCachedCheckins @"kCachedCheckins"
#define kDidNotReceiveNewFBChatUsers @"kDidNotReceiveNewFBChatUsers"


#define kDidNotReceiveNewChatPoints @"kDidNotReceiveNewChatPoints"
#define kDidReceiveError @"kDidReceiveError"
#define kDidSuccessfulMessageSending @"kDidSuccessfulMessageSending"
#define kWillRemoveLastChatPoint @"kWillRemoveLastChatPoint"
#define kdidReceiveErrorLoadingNewChatPoints @"kdidReceiveErrorLoadingNewChatPoints"
#define kWillUpdate @"kWillUpdate"

#define kWillAddPointIsFBCheckin @"kWillAddPointIsFBCheckin"
#define kWillUpdatePointStatus @"kWillUpdatePointStatus"
#define kWillAddNewMessageToChat @"kWillAddNewMessageToChat"

#define kWillAddCheckin @"kWillAddCheckin"
#define kWillClearMessageField @"kWillClearMessageField"
#define kWillScrollToTop @"kWillScrollToTop"
#define kwillUpdateMarkersForCenterLocation @"kwillUpdateMarkersForCenterLocation"
#define kWillShowAllFriends @"kWillShowAllFriends"
#define kWillSetAllFriendsSwitchEnabled @"kWillSetAllFriendsSwitchEnabled"
#define kWillSetMessageFieldEnabled @"kWillSetMessageFieldEnabled"
#define kWillSetDistanceSliderEnabled @"kWillSetDistanceSliderEnabled"

#define kChatEndOfRetrievingInitialData @"kChatEndOfRetrievingInitialData"
#define kMapEndOfRetrievingInitialData @"kMapEndOfRetrievingInitialData"
#define kMapDidNotReceiveNewFBMapUsers @"kMapDidNotReceiveNewFBMapUsers"
#define kDidClearCache @"kDidClearCache"
#define kGeneralDataEndRetrieving @"kGeneralDataEndRetrieving"
#define kRegisterPushNotificatons @"kRegisterPushNotificatons"
#define kARDidNotReceiveNewUsers @"kARDidNotReceiveNewUsers"

#define kDidReceiveChatRooms @"kDidReceiveChatRooms"

#define kDataIsReadyForDisplaying @"kDataIsReadyForDisplaying"
#define kNeedToDisplayChatRoomController @"kNeedToDisplayChatRoomController"
#define kDidReceiveUserProfilePicturesURL @"kDidReceiveUserProfilePicturesURL"

#define kDidReceiveMessage @"kDidReceiveMessage"
#define kNewChatRoomCreated @"kNewChatRoomCreated"
#define kNeedToUpdateChatRoomController @"kNeedToUpdateChatRoomController"
#define kDidChangeRatingOfRoom @"kDidChangeRatingOfRoom"

#define INDICATOR_TAG 23458
#define QUOTE_IDENTIFIER @"@!/"
// Strings
#define appName @"ChattAR"

#define DLog(...)NSLog(@"%@", [NSString stringWithFormat:@"%s:%d -> %@", __PRETTY_FUNCTION__, __LINE__, __VA_ARGS__])

// Flurry
#define FLURRY_API_KEY @"KMD7NSM4DF344W9JVCGN"
#define FLURRY_EVENT_USER_DID_LOGIN @"User did login"
#define chatViewControllerIdentifier @"chatViewControllerIdentifier"
#define chatRoomsViewControllerIdentifier @"chatRoomsViewControllerIdentifier" 

// Tab bar indexes enum
enum TabbarIndexes {
    chatIndex = 0, mapIndex,radarIndex,dialogsIndex
};