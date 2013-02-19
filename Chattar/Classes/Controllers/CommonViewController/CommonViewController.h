//
//  CommonViewController.h
//  Chattar
//
//  Created by kirill on 2/19/13.
//
//

#import <UIKit/UIKit.h>
#import "CustomSwitch.h"

@interface CommonViewController : UIViewController{
    BOOL showAllUsers;
}
@property (nonatomic, assign) CustomSwitch *allFriendsSwitch;
@property (nonatomic,retain) UIActivityIndicatorView* loadingIndicator;

-(void)addSpinner;
@end
