//
//  CommonViewController.h
//  Chattar
//
//  Created by kirill on 2/19/13.
//
//

#import <UIKit/UIKit.h>
#import "CustomSwitch.h"
#import "WebViewController.h"
#import "FBChatViewController.h"

@interface CommonViewController : UIViewController<UIActionSheetDelegate>{
    BOOL showAllUsers;
}
@property (nonatomic, assign) CustomSwitch *allFriendsSwitch;
@property (nonatomic,retain) UIActivityIndicatorView* loadingIndicator;
@property (retain) UserAnnotation *selectedUserAnnotation;
@property (nonatomic, retain) UIActionSheet *userActionSheet;


- (void)showActionSheetWithTitle:(NSString *)title andSubtitle:(NSString *)subtitle;
-(void)addSpinner;
- (void)actionSheetViewFBProfile;
-(void)actionSheetSendPrivateFBMessage;
@end
