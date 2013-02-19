//
//  SplashController.h
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 04.05.12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBServiceResultDelegate.h"
#import "MBProgressHUD.h"

@interface SplashController : UIViewController <QBActionStatusDelegate, FBServiceResultDelegate, FBSessionDelegate,QBChatDelegate>{
    IBOutlet UIActivityIndicatorView *activityIndicator;
    IBOutlet UIButton *loginButton;
    MBProgressHUD* hud;
    NSString* qbToken;
}

@property (nonatomic) BOOL openedAtStartApp;
@property (retain, nonatomic) IBOutlet UIImageView *backgroundImage;
- (IBAction)login:(id)sender;
- (void)startApplication;
- (void)showLoginButton:(BOOL)isShow;

@end
