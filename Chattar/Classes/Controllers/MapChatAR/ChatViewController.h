//
//  ChatViewController.h
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 3/27/12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewTouch.h"
#import "AsyncImageView.h"
#import "CustomButtonWithQuote.h"
#import "WebViewController.h"
#import "MessagesViewController.h"
#import "CustomSwitch.h"

#import "BackgroundWorker.h"

#define tableIsUpdating 1011


@interface ChatViewController : UIViewController <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, QBActionStatusDelegate, UIScrollViewDelegate, FBServiceResultDelegate, UIWebViewDelegate,FBDataDelegate,ChatControllerDelegate, DataDelegate>{
    UIImage *messageBGImage;
    UIImage *messageBGImage2;
    UIImage *distanceImage;
    UIImage *distanceImage2;
    
    ViewTouch *backView;
	int page;

	BOOL isLoadingMoreMessages;
    
    BOOL showAllUsers;
    
    BOOL isDataRetrieved;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) IBOutlet UITextField *messageField;
@property (nonatomic, retain) IBOutlet UITableView *messagesTableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *sendMessageActivityIndicator;

@property (nonatomic, retain) NSString* quoteMark;
@property (nonatomic, retain) AsyncImageView* quotePhotoTop;

@property (nonatomic, retain) UIActionSheet *userActionSheet;
@property (retain) UserAnnotation *selectedUserAnnotation;
@property (nonatomic, assign) CustomSwitch *allFriendsSwitch;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

- (IBAction)sendMessageDidPress:(id)sender;

- (void)refresh;

- (void)addQuote;

@end
