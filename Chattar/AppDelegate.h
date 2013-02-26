//
//  AppDelegate.h
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 03.05.12.
//  Copyright (c) 2012 QuickBlox. All rights ячс reserved.
//

#import <UIKit/UIKit.h>
#import "CustomTabBarController.h"
#import "Storage.h"
#import "ChatPointsStorage.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate,UITabBarControllerDelegate>{
}
@property (retain, nonatomic) UIWindow *window;
@property (retain, nonatomic) CustomTabBarController *tabBarController;

- (void)showSplashWithAnimation:(BOOL) animated;
- (void)showSplashWithAnimation:(BOOL) animated showLoginButton:(BOOL)isShow;

@end
