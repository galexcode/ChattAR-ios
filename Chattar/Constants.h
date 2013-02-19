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

#define kDidNotReceiveChatRooms @"kDidNotReceiveChatRooms"

#define INDICATOR_TAG 23458
// Strings
#define appName @"ChattAR"

// Flurry
#define FLURRY_API_KEY @"KMD7NSM4DF344W9JVCGN"
#define FLURRY_EVENT_USER_DID_LOGIN @"User did login"

// Tab bar indexes enum
enum TabbarIndexes {
    chatIndex = 0, mapIndex,radarIndex,dialogsIndex
};