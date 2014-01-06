//
//  ChattARAppDelegate+PushNotifications.m
//  ChattAR
//
//  Created by Igor Alefirenko on 02/01/2014.
//  Copyright (c) 2014 Stefano Antonelli. All rights reserved.
//

#import "ChattARAppDelegate+PushNotifications.h"
#import "SASlideMenuRootViewController.h"
#import "FBService.h"
#import "FBStorage.h"
#import "QBService.h"
#import "QBStorage.h"

#import "DetailDialogsViewController.h"
#import "ChatRoomViewController.h"


static NSString *dialogIdentifier = @"dialogController";
static NSString *chatRoomIdentifier = @"chatRoomController";


@implementation ChattARAppDelegate (PushNotifications)

- (void)processRemoteNotification:(NSDictionary *)userInfo
{
    // Get Push notification params:
    NSDictionary *aps = userInfo[@"aps"];
    NSString *opponentID = aps[kId];
    NSString *qbOpponentID = aps[kQuickbloxID];
    NSString *roomName = aps[kRoomName];
    
    
    // Get Navigation controller & chat controller for push segue:
    UIApplication *application = [UIApplication sharedApplication];
    UIWindow *window = [[application delegate] window];
    SASlideMenuRootViewController *root =  (SASlideMenuRootViewController *)window.rootViewController;
    
    UINavigationController *navigationVC = [[root childViewControllers] lastObject];
    if (navigationVC != nil) {
        id viewController = nil;
    
        UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        if (roomName != nil) {
            viewController = [myStoryboard instantiateViewControllerWithIdentifier:chatRoomIdentifier];
            
            
            
        } else {
            // DIALOG:
            viewController = [myStoryboard instantiateViewControllerWithIdentifier:dialogIdentifier];
            if ([viewController isKindOfClass:[DetailDialogsViewController class]]) {

                __block BOOL isFacebookDialog = NO;
                NSMutableDictionary *conversation = nil;
                
                NSMutableDictionary *user = [[[FBService shared] findFriendWithID:opponentID] mutableCopy];
                if (user != nil) {
                    conversation = [FBService findFBConversationWithFriend:user];
                    isFacebookDialog = YES;
                } else {
                    user = [[QBService defaultService] findUserWithID:opponentID];
                    if (user != nil) {
                        conversation = [[QBService defaultService] findConversationWithUser:user];
                    }
                }
                // if user not found:
                if (user == nil && conversation == nil) {
                    [[FBService shared] userProfileWithID:opponentID withBlock:^(id result) {
                        ((DetailDialogsViewController *)viewController).isChatWithFacebookFriend = isFacebookDialog;
                        // load user:
                        NSMutableDictionary *opponent = (FBGraphObject *)result;
                        opponent[kQuickbloxID] = qbOpponentID;
                        NSString *urlString = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%@/picture?access_token=%@", opponentID, [FBStorage shared].accessToken];
                        opponent[kPhoto] = urlString;
                        [[QBStorage shared].otherUsers addObject:opponent];
                        ((DetailDialogsViewController *)viewController).opponent = opponent;
                        
                        // create empty conversation:
                        NSMutableArray *messages = [[NSMutableArray alloc] init];
                        NSMutableDictionary *newConversation = [[NSMutableDictionary alloc] init];
                        newConversation[kMessage] = messages;
                        ((DetailDialogsViewController *)viewController).conversation = newConversation;
                        
                        [navigationVC pushViewController:viewController animated:YES];
                    }];
                    return;
                }
                
                ((DetailDialogsViewController *)viewController).isChatWithFacebookFriend = isFacebookDialog;
                ((DetailDialogsViewController *)viewController).opponent = user;
                ((DetailDialogsViewController *)viewController).conversation = conversation;
            }
        }
        [navigationVC pushViewController:viewController animated:YES];
    }
}

@end
