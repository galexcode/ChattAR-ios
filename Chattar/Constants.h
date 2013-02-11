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
#define kCachedChatPoints @"kCachedChatPoints"
#define kCachedChatPointsIDs @"kCachedChatPointsIDs"
#define kCachedCheckins @"kCachedCheckins"

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
#define kAREndOfRetrieveInitialData @"kAREndOfRetrieveInitialData"
#define kWillShowAllFriends @"kWillShowAllFriends"
#define kDidEndRetrievingInitialData @"kDidEndRetrievingInitialData"
#define kWillSetAllFriendsSwitchEnabled @"kWillSetAllFriendsSwitchEnabled"
#define kWillSetMessageFieldEnabled @"kWillSetMessageFieldEnabled"
#define kWillSetDistanceSliderEnabled @"kWillSetDistanceSliderEnabled"
// Strings
#define appName @"ChattAR"

// Flurry
#define FLURRY_API_KEY @"KMD7NSM4DF344W9JVCGN"
#define FLURRY_EVENT_USER_DID_LOGIN @"User did login"

// Tab bar indexes enum
enum TabbarIndexes {
    chatIndex = 0, mapIndex,radarIndex,dialogsIndex
};