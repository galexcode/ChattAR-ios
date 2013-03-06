//
//  SplashController.m
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 04.05.12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import "SplashController.h"
#import "AppDelegate.h"
#import "NumberToLetterConverter.h"

@interface SplashController ()

@end

@implementation SplashController 

@synthesize openedAtStartApp;
#pragma mark -
#pragma mark UIViewControllers & view methods

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startApplication)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistentStorageInitEnded:) name:@"persistentStorageInitSuccess" object:nil];
    
    if(IS_HEIGHT_GTE_568){
        [self.backgroundImage setImage:[UIImage imageNamed:@"Default-568h@2x.png"]];
        CGRect loginButtonFrame = self->loginButton.frame;
        loginButtonFrame.origin.y -= 22;
        [self->loginButton setFrame:loginButtonFrame];
        
        CGRect activityIndicatorFrame = self->activityIndicator.frame;
        activityIndicatorFrame.origin.y -= 22;
        [self->activityIndicator setFrame:activityIndicatorFrame];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doGeneralDataEndRetrieving) name:kGeneralDataEndRetrieving object:nil];
}

- (void)startApplication{
    // show Login & Registrations buttons
    [activityIndicator stopAnimating];
    
    [self showLoginButton:YES];
}

-(void)viewDidAppear:(BOOL)animated{
    [self checkCoreDataInit];
}

-(void)checkCoreDataInit{
    if (![[DataManager shared] persistentStoreCoordinator]) {
        if (!hud) {
            hud = [[MBProgressHUD alloc] initWithView:self.view];
            hud.labelText = @"Please wait - your application is updating";
            [hud show:YES];
            [self.view addSubview:hud];
        }
    }
}

-(void)persistentStorageInitEnded:(NSNotification*)notification{
    [hud removeFromSuperview];
}

- (void)showLoginButton:(BOOL)isShow{
    loginButton.hidden = !isShow;
}

- (void)createSessionWithDelegate:(id)delegate{    
    // QuickBlox application authorization
    
    if(openedAtStartApp){

        [activityIndicator startAnimating];

		[NSTimer scheduledTimerWithTimeInterval:60*60*2-600 // Expiration date of access token is 2 hours. Repeat request for new token every 1 hour and 50 minutes.
                                         target:self
                                       selector:@selector(createSession)
                                       userInfo:nil
                                        repeats:YES];
    }
    
    QBASessionCreationRequest *extendedAuthRequest = [QBASessionCreationRequest request];
    extendedAuthRequest.socialProvider = @"facebook";
    extendedAuthRequest.socialProviderAccessToken = [FBService shared].facebook.accessToken;
    [QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:self];
}

- (void)createSession
{
    [self createSessionWithDelegate:nil];
}

- (void)viewDidUnload{
    activityIndicator = nil;
    loginButton = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:@"persistentStorageInitSuccess"];
    [self setBackgroundImage:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// Login action
- (IBAction)login:(id)sender{

    if (![Reachability internetConnected]) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"No internet connection."
                                                        delegate:nil
                                                cancelButtonTitle:@"Ok"
                                                otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }

    
    // Auth in FB
    NSArray *params = [[NSArray alloc] initWithObjects:@"user_checkins", @"user_location", @"friends_checkins",
                       @"friends_location", @"friends_status",@"friends_photos", @"read_mailbox",@"photo_upload",@"read_stream",
                       @"publish_stream", @"user_photos", @"xmpp_login", @"user_about_me", nil];
    [[FBService shared].facebook setSessionDelegate:self];
    [[FBService shared].facebook authorize:params];
    [params release];
}

- (void)dealloc {
    [_backgroundImage release];
    [hud release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark -
#pragma mark FBSessionDelegate

- (void)fbDidLogin {
    NSLog(@"fbDidLogin");
    
    // save FB token and expiration date
    [[DataManager shared] saveFBToken:[FBService shared].facebook.accessToken 
                              andDate:[FBService shared].facebook.expirationDate];
    
    [self createSessionWithDelegate:self];
    
    // auth in Chat
    [[FBService shared] logInChat];
    
    // get user's profile
    [[FBService shared] userProfileWithDelegate:self];
    
    [activityIndicator startAnimating];
    [self showLoginButton:NO];
}

- (void)fbDidNotLogin:(BOOL)cancelled{}
- (void)fbDidExtendToken:(NSString*)accessToken
               expiresAt:(NSDate*)expiresAt{}

- (void)fbDidLogout{
    // Clear cookies
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]){
        NSString* domainName = [cookie domain];
        NSRange domainRange = [domainName rangeOfString:@"facebook"];
        if(domainRange.length > 0){
            [storage deleteCookie:cookie];
        }
    }
}

- (void)fbSessionInvalidated{}


#pragma mark -
#pragma mark FBServiceResultDelegate

-(void)completedWithFBResult:(FBServiceResult *)result{
    
    // get User profile result
    if(result.queryType == FBQueriesTypesUserProfile){
        // save FB user
        [DataManager shared].currentFBUser = [[result.body mutableCopy] autorelease];
        [DataManager shared].currentFBUserId = [[DataManager shared].currentFBUser objectForKey:kId];
                
        [QBUsers logInWithSocialProvider:@"facebook" accessToken:[[[DataManager shared] fbUserTokenAndDate] objectForKey:FBAccessTokenKey] accessTokenSecret:nil delegate:self];
    }
}


#pragma mark -
#pragma mark QB QBActionStatusDelegate

// QuickBlox API queries delegate
-(void)completedWithResult:(Result *)result{
    
    // QuickBlox Application authorization result
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]){
        // Success result
		if(result.success){                        
            
            // restore FB cookies
            NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
            NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:FB_COOKIES];
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            for(NSHTTPCookie *cook in cookies){
                if([cook.domain rangeOfString:@"facebook.com"].location != NSNotFound){
                    [cookiesStorage setCookie:cook];
                }
            }
            
            QBAAuthSessionCreationResult* res = (QBAAuthSessionCreationResult*)result;
            
            QBUUser* user = [QBUUser user];
            user.password =  [BaseService sharedService].token;
            user.ID = res.session.userID;
            
            [[QBChat instance] setDelegate:self];
            [[QBChat instance] loginWithUser:user];
            
            // register as subscribers for receiving push notifications
            [QBMessages TRegisterSubscriptionWithDelegate:self];
        }
        else{
            // Errors
            NSString *message = [result.errors stringValue];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Errors", nil) 
                                                            message:message  
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"Ok", nil) 
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
            
            [activityIndicator stopAnimating];
        }
	
    }else if([result isKindOfClass:[QBMRegisterSubscriptionTaskResult class]]){
        
        [Flurry logEvent:FLURRY_EVENT_USER_DID_LOGIN];
        
        ((AppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.selectedIndex = 0;
        
        
        [[FBService shared].facebook setSessionDelegate:nil];
        
        
        // save FB cookies
        NSHTTPCookieStorage *cookiesStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        NSArray *cookies = [cookiesStorage cookies];
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
        [[NSUserDefaults standardUserDefaults] setObject:data forKey:FB_COOKIES];
    }    
    else {
        NSLog(@"%@",result.errors);
    }
    
}

#pragma mark -
#pragma mark Notifications Reaction
-(void)doGeneralDataEndRetrieving{
    // hide splash
    [activityIndicator stopAnimating];

    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark QBChat login
-(void)chatDidLogin{
    NSLog(@"SUCCESS LOGIN QBCHAT!");
    
    // notify tabbar to request FB info
    [[NSNotificationCenter defaultCenter] postNotificationName:kRegisterPushNotificatons object:nil];

}

-(void)chatDidNotLogin{
    NSLog(@"FAILED TO LOGIN QBCHAT!");
}
@end
