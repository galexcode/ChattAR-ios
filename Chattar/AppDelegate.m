//
//  AppDelegate.m
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 03.05.12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import "AppDelegate.h"

#import "MessagesViewController.h"
#import "ContactsController.h"
#import "SettingsController.h"
#import "SplashController.h"
#import "FBNavigationBar.h"
#import "FBChatViewController.h"
#import "NumberToLetterConverter.h"
#import "Extender.h"
#import "UserAnnotation.h"
#import "AugmentedRealityController.h"
#import "ARManager.h"
#import "ProvisionManager.h"
#import "ChatViewController.h"
#import "MapViewController.h"
#import "ChatRoomsViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (void)dealloc{
	[_window release];
	[_tabBarController release];
	
    [super dealloc];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    NSLog(@"didReceiveRemoteNotification userInfo=%@", userInfo);    
    
    // Receive push notifications
    NSString *message = [[userInfo objectForKey:QBMPushMessageApsKey] objectForKey:QBMPushMessageAlertKey];

    [NotificationManager playNotificationSoundAndVibrate];
    
    if (self.tabBarController.selectedIndex != chatIndex) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(appName, "")
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Ok", "OK")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
	[UIApplication sharedApplication].statusBarHidden = YES;
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // Flurry
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [Flurry startSession:FLURRY_API_KEY];
    
    
    // Set QuickBlox credentials
    [QBSettings setApplicationID:771];
    [QBSettings setAuthorizationKey:@"hOYSNJ8zwYhUspn"];
    [QBSettings setAuthorizationSecret:@"KcfDYJFY7x3r5HR"];
    [QBSettings setRestAPIVersion:@"0.1.1"];
#ifndef DEBUG
    [QBSettings setLogLevel:QBLogLevelNothing];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkMemory) 
                                                 name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	
	_window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
    // Settings
	SettingsController *settingsViewController = [[SettingsController alloc] initWithNibName:@"SettingsController" bundle:nil];
    UINavigationController *settingsNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
	[settingsViewController.navigationController setValue:[[[FBNavigationBar alloc]init] autorelease] forKeyPath:@"navigationBar"];
    [settingsViewController release];
    
    // Chat
    ChatViewController* chatViewController = [[ChatViewController alloc] initWithNibName:@"ChatViewController" bundle:nil];

    chatViewController.dataStorage = [[ChatPointsStorage alloc] init];
    chatViewController.controllerReuseIdentifier = [[NSString alloc] initWithString:chatViewControllerIdentifier];
    
    UINavigationController* chatNavigationController = [[UINavigationController alloc] initWithRootViewController:chatViewController];
    [chatViewController.navigationController setValue:[[[FBNavigationBar alloc]init] autorelease] forKeyPath:@"navigationBar"];
    [chatViewController release];
    
    // Map
    MapViewController* mapViewController = [[MapViewController alloc] initWithNibName:@"MapViewController" bundle:nil];
    UINavigationController* mapNavigationController = [[UINavigationController alloc] initWithRootViewController:mapViewController];
    [mapViewController.navigationController setValue:[[[FBNavigationBar alloc]init] autorelease] forKeyPath:@"navigationBar"];

    [mapViewController release];
    
    // Chat Rooms
    ChatRoomsViewController* chatRoomsController = [[ChatRoomsViewController alloc] initWithNibName:@"ChatRoomsViewController" bundle:nil];
    UINavigationController* chatRoomsNavigationController = [[UINavigationController alloc] initWithRootViewController:chatRoomsController];
    [chatRoomsController.navigationController setValue:[[[FBNavigationBar alloc]init] autorelease] forKeyPath:@"navigationBar"];

    [chatRoomsController release];
    
	// Tab Bar
	_tabBarController = [[CustomTabBarController alloc] init];
    NSArray* viewControllers;
    if ([ARManager deviceSupportsAR]) {
        // Radar
        AugmentedRealityController* arController = [[AugmentedRealityController alloc] initWithNibName:@"ARViewController" bundle:nil];
        UINavigationController* arNavigationController = [[UINavigationController alloc] initWithRootViewController:arController];
        [arController.navigationController setValue:[[[FBNavigationBar alloc]init] autorelease] forKeyPath:@"navigationBar"];

        [arController release];

        viewControllers = @[chatNavigationController,mapNavigationController,arNavigationController,chatRoomsNavigationController, settingsNavigationController];
        [arNavigationController release];
    }
    else
        viewControllers = @[chatNavigationController,mapNavigationController,chatRoomsNavigationController, settingsNavigationController];
	_tabBarController.viewControllers = viewControllers;
	
	// release controllers
	[settingsNavigationController release];
	[chatNavigationController release];
    [chatRoomsNavigationController release];
    [mapNavigationController release];
    // show window
	self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    
    
    // shpw splash
    [self showSplashWithAnimation:NO];
    
    return YES;
}
- (void) showSplashWithAnimation:(BOOL) animated showLoginButton:(BOOL)isShow{
    
    // show Splash
    SplashController *splashViewController = [[SplashController alloc] initWithNibName:@"SplashController" bundle:nil];
    splashViewController.openedAtStartApp = !animated;
    [self.tabBarController presentModalViewController:splashViewController animated:animated];
    [splashViewController release];
    
    // logout
    if(animated){
        [[FBService shared].facebook setSessionDelegate:splashViewController];
        [splashViewController showLoginButton:isShow];
    }
}


- (void)showSplashWithAnimation:(BOOL) animated{
    // show Splash
    SplashController *splashViewController = [[SplashController alloc] initWithNibName:@"SplashController" bundle:nil]; 
    splashViewController.openedAtStartApp = !animated;
    [self.tabBarController presentModalViewController:splashViewController animated:animated];
    [splashViewController release];
    
    [[FBService shared].facebook setSessionDelegate:splashViewController];
    
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBService shared].facebook handleOpenURL:url]; 
}

// Pre iOS 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [[FBService shared].facebook handleOpenURL:url]; 
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    
    if ([DataManager shared].currentQBUser)
	{
		[[FBService shared] logOutChat];
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// update access token (if it expired)
	QBASessionCreationRequest *extendedAuthRequest = [[QBASessionCreationRequest alloc] init];
    if([DataManager shared].currentFBUser){
        extendedAuthRequest.userLogin = [[NumberToLetterConverter instance] convertNumbersToLetters:[[DataManager shared].currentFBUser objectForKey:kId]];
        extendedAuthRequest.userPassword = [NSString stringWithFormat:@"%u", [[[DataManager shared].currentFBUser objectForKey:kId] hash]];
    }
	
	// QuickBlox application authorization
	[QBAuth createSessionWithExtendedRequest:extendedAuthRequest delegate:nil];
	
	[extendedAuthRequest release];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	if (![FBService shared].isChatDidConnect && [DataManager shared].currentQBUser) // if user was disconnected in chat & he was authenticated fo FB
	{
		[[FBService shared] logInChat]; // auth to chat again
	}
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) checkMemory {
    // clear image cache
    [AsyncImageView clearCache];
    
	if (printMemoryInfo() < 3) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Attention","Title of alert")
                                                        message:[NSString stringWithFormat:NSLocalizedString(@"ChattAR may crash  \n if you don't completely close \n other unused apps.", "Low memory alert"), appName]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Go on working", "Button text"), nil];
        [alert show];
        [alert release];
	} 
}


#pragma mark -
#pragma mark Flurry uncaught Exception Handler

void uncaughtExceptionHandler(NSException *exception) {
#ifndef DEBUG
    [Flurry logError:@"Uncaught" message:@"Crash!" exception:exception];
#endif
}

@end
