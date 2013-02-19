//
//  MapViewController.m
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 3/27/12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import "MapViewController.h"
#import "UserAnnotation.h"
#import "AppDelegate.h"
#import "ARMarkerView.h"
#import "AugmentedRealityController.h"
#import "WebViewController.h"
#import "ChatViewController.h"

@interface MapViewController ()

@end

@implementation MapViewController

@synthesize mapView;
@synthesize delegate;
@synthesize compass;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		self.title = NSLocalizedString(@"Map", nil);
		self.tabBarItem.image = [UIImage imageNamed:@"mapTab.png"];
        
        // logout
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logoutDone) name:kNotificationLogout object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doAddNewPoint:) name:kWillAddPointIsFBCheckin object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doUpdatePointStatus:) name:kWillUpdatePointStatus object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doMapEndRetrievingData) name:kMapEndOfRetrievingInitialData object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doWillSetAllFriendsSwitchEnabled:) name:kWillSetAllFriendsSwitchEnabled object:nil ];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doMapNotReceiveNewFBMapUsers) name:kMapDidNotReceiveNewFBMapUsers object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doClearCache) name:kDidClearCache object:nil];

        isViewLoaded = NO;
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [mapView setUserInteractionEnabled:NO];
	mapView.userInteractionEnabled = YES;
    
    isViewLoaded = YES;
    
	MKCoordinateRegion region;
	//Set Zoom level using Span
	MKCoordinateSpan span;  
	region.center=mapView.region.center;
	span.latitudeDelta=150;
	span.longitudeDelta=150;
	region.span=span;
	[mapView setRegion:region animated:YES];
    
    canRotate = NO;
    
    //add rotation gesture 
    UIGestureRecognizer *rotationGestureRecognizer;
    rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(spin:)];
    [rotationGestureRecognizer setDelegate:self];
    [self.view addGestureRecognizer:rotationGestureRecognizer];
    [rotationGestureRecognizer release];
    
    
    count     = 0;
    lastCount = 0;
    
    annotationsViewCount = 0;
    
    //add frames for change zoom map
    mapFrameZoomOut.size.width  = 320.0f;
    mapFrameZoomOut.size.height = 387.0f;
    
    mapFrameZoomOut.origin.y = 0;
    mapFrameZoomOut.origin.x = 0;
    
    mapFrameZoomIn.size.width  = 503.0f;
    mapFrameZoomIn.size.height = 503.0f;
    
    mapFrameZoomIn.origin.x = -91.5f;
    mapFrameZoomIn.origin.y = -58.0f;
    
    if(IS_HEIGHT_GTE_568){
        mapFrameZoomOut.size.height = 475.0f;
        
        mapFrameZoomIn.size.height  = 573.0f;
        mapFrameZoomIn.size.width   = 573.0f;
        
        mapFrameZoomIn.origin.x = -126.5f;
        mapFrameZoomIn.origin.y = -49.0f;
    }
    
    //add compass image
    compass = [[UIImageView alloc] init];
    
    CGRect compassFrame;
    compassFrame.size.height = 40;
    compassFrame.size.width  = 40;
    
    compassFrame.origin.x = 260;
    compassFrame.origin.y = 15;
    
    initialRegion = self.mapView.region;
    
    [self.compass setImage:[UIImage imageNamed:@"Compass.png" ]];
    [self.compass setAlpha:0.0f];
    [self.compass setFrame:compassFrame];
    [self.view addSubview:compass];
    [compass release];
    
    annotationsForClustering = [[NSMutableArray alloc] init];
    
    previousRect = mapView.visibleMapRect;    
}

- (void)viewDidUnload
{
    self.mapView = nil;
    
    [self setLoadingIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewDidAppear:(BOOL)animated{
    [self checkForShowingData];
}

#pragma mark -
#pragma mark Interface based methods

-(void)checkForShowingData{
    if ([DataManager shared].mapPoints.count == 0 && [DataManager shared].mapPointsIDs.count == 0) {
        [self mapClear];
        [[BackgroundWorker instance] retrieveCachedMapDataAndRequestNewData];
        [super addSpinner];
        
        // additional request for checkins
        if ([DataManager shared].allCheckins.count == 0) {
            [[BackgroundWorker instance] retrieveCachedFBCheckinsAndRequestNewCheckins];
        }
        
        [DataManager shared].currentRequestingDataControllerTitle = @"Map";
    }
    else{
        if ([[self allFriendsSwitch] value] == friendsValue) {
            [self showFriends];
        }
        else
            [self showWorld];
    }
}

- (void)spin:(UIRotationGestureRecognizer *)gestureRecognizer {
    if(canRotate){
        if(gestureRecognizer.state == UIGestureRecognizerStateBegan){
            lastCount = 0;
        }
    
        count += gestureRecognizer.rotation - lastCount;
        lastCount = gestureRecognizer.rotation;
        [self.mapView setTransform:CGAffineTransformMakeRotation(count)];
        [self.compass setTransform:CGAffineTransformMakeRotation(count)];
        [self rotateAnnotations:(-count)];
    }
}

- (void)rotateAnnotations:(CGFloat) angle{
                        // rotate ALL annotations, all annotations are stored in displayedAnnotations array
    [[self.mapView displayedAnnotations] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
            MKAnnotationView * view = [self.mapView viewForAnnotation:obj];
            [view setTransform:CGAffineTransformMakeRotation(angle)];
        
        }];
}


- (void)refreshWithNewPoints:(NSArray *)newMapPoints{
    // remove old
	[mapView removeAnnotations:mapView.annotations];
	
    // add new
	[self addPoints:newMapPoints];
    [mapView doClustering];
}

- (void) showWorld{
    
    // Map/AR points
    //
    [[DataManager shared].mapPoints removeAllObjects];
    //
    // 1. add All from QB
    NSMutableArray *friendsIdsWhoAlreadyAdded = [NSMutableArray array];
    for(UserAnnotation *mapAnnotation in [DataManager shared].allmapPoints){
        [[DataManager shared].mapPoints addObject:mapAnnotation];
        [friendsIdsWhoAlreadyAdded addObject:mapAnnotation.fbUserId];
    }
    //
    // add checkin
    NSArray *allCheckinsCopy = [[DataManager shared].allCheckins copy];
    for (UserAnnotation* checkin in allCheckinsCopy){
        if (![friendsIdsWhoAlreadyAdded containsObject:checkin.fbUserId]){
            [[DataManager shared].mapPoints addObject:checkin];
            [friendsIdsWhoAlreadyAdded addObject:checkin.fbUserId];
        }else{
            // compare datetimes - add newest
            NSDate *newCreateDateTime = checkin.createdAt;
            
            int index = [friendsIdsWhoAlreadyAdded indexOfObject:checkin.fbUserId];
            NSDate *currentCreateDateTime = ((UserAnnotation *)[[DataManager shared].mapPoints objectAtIndex:index]).createdAt;
            
            if([newCreateDateTime compare:currentCreateDateTime] == NSOrderedDescending){ //The receiver(newCreateDateTime) is later in time than anotherDate, NSOrderedDescending
                [[DataManager shared].mapPoints replaceObjectAtIndex:index withObject:checkin];
                [friendsIdsWhoAlreadyAdded replaceObjectAtIndex:index withObject:checkin.fbUserId];
            }
        }
    }
    [allCheckinsCopy release];
        
    // notify controllers
    [self refreshWithNewPoints:[DataManager shared].mapPoints];
}

- (void) showFriends{
    NSMutableArray *friendsIds = [[[DataManager shared].myFriendsAsDictionary allKeys] mutableCopy];
    [friendsIds addObject:[DataManager shared].currentFBUserId];// add me
    
    [[DataManager shared].mapPoints removeAllObjects];
    
    //
    // add only friends QB points
    NSMutableArray *friendsIdsWhoAlreadyAdded = [NSMutableArray array];
    for(UserAnnotation *mapAnnotation in [DataManager shared].allmapPoints){
        if([friendsIds containsObject:[mapAnnotation.fbUser objectForKey:kId]]){
            [[DataManager shared].mapPoints addObject:mapAnnotation];
            
            [friendsIdsWhoAlreadyAdded addObject:[mapAnnotation.fbUser objectForKey:kId]];
        }
    }
    [friendsIds release];
    // add checkin
    NSArray *allCheckinsCopy = [[DataManager shared].allCheckins copy];
    for (UserAnnotation* checkin in allCheckinsCopy){
        if (![friendsIdsWhoAlreadyAdded containsObject:checkin.fbUserId]){
            [[DataManager shared].mapPoints addObject:checkin];
            [friendsIdsWhoAlreadyAdded addObject:checkin.fbUserId];
        }else{
            // compare datetimes - add newest
            NSDate *newCreateDateTime = checkin.createdAt;
            
            int index = [friendsIdsWhoAlreadyAdded indexOfObject:checkin.fbUserId];
            NSDate *currentCreateDateTime = ((UserAnnotation *)[[DataManager shared].mapPoints objectAtIndex:index]).createdAt;
            
            if([newCreateDateTime compare:currentCreateDateTime] == NSOrderedDescending){ //The receiver(newCreateDateTime) is later in time than anotherDate, NSOrderedDescending
                [[DataManager shared].mapPoints replaceObjectAtIndex:index withObject:checkin];
                [friendsIdsWhoAlreadyAdded replaceObjectAtIndex:index withObject:checkin.fbUserId];
            }
        }
    }
    [allCheckinsCopy release];
    
    
    [self refreshWithNewPoints:[DataManager shared].mapPoints];
}

#pragma mark -
#pragma mark Internal data methods
- (void)addPoints:(NSArray *)newMapPoints{
    // add new
    for (UserAnnotation* ann in newMapPoints) {
        // skip me
        if([ann.fbUserId isEqualToString:[DataManager shared].currentFBUserId]){
            continue;
        }
        
        [self.mapView addAnnotation:ann];
        [annotationsForClustering addObject:ann];
    }
}

- (void)addPoint:(UserAnnotation *)newMapPoint{
    
    if ([newMapPoint.fbUserId isEqualToString:[DataManager shared].currentFBUserId]) {
        return;
    }
    
    [self.mapView addAnnotation:newMapPoint];
}

-(void)mapClear{
    [mapView setUserInteractionEnabled:NO];
    [mapView removeAnnotations:mapView.annotations];
    [self.mapView setRegion:initialRegion animated:NO];
	mapView.userInteractionEnabled = YES;
}

- (void)clear{
    [self mapClear];
    [[DataManager shared].allmapPoints removeAllObjects];
    [[DataManager shared].mapPoints removeAllObjects];
    [[DataManager shared].mapPointsIDs removeAllObjects];
    [[DataManager shared].allCheckins removeAllObjects];
}

-(void)updateStatus:(UserAnnotation*)point{
    NSArray *currentMapAnnotations = [self.mapView.annotations copy];
    
    // Check for Map
    BOOL isExistPoint = NO;
    for (UserAnnotation *annotation in currentMapAnnotations)
	{
        // already exist, change status
        if([point.fbUserId isEqualToString:annotation.fbUserId])
		{
            if ([point.userStatus length] < 6 || ([point.userStatus length] >= 6 && ![[point.userStatus substringToIndex:6] isEqualToString:fbidIdentifier])){
                MapMarkerView *marker = (MapMarkerView *)[self.mapView viewForAnnotation:annotation];
                [marker updateStatus:point.userStatus];// update status
            }
            
            isExistPoint = YES;
            
            break;
        }
    }
    [currentMapAnnotations release];
    
    // Check for AR
    if(isExistPoint){
        
        NSArray *currentARMarkers = [[DataManager shared].coordinateViews copy];
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    // find AR controller
        UITabBarController *tabBarController = appDelegate.tabBarController;
        AugmentedRealityController* arViewController = nil;
        for (UIViewController* viewController in tabBarController.viewControllers) {
            UIViewController *vc = viewController;
            if ([viewController isKindOfClass:[UINavigationController class]]) {
                vc = [(UINavigationController*)viewController visibleViewController];
            }
            if ([vc isKindOfClass:[AugmentedRealityController class]]) {
                arViewController = (AugmentedRealityController*)vc;
            }
        }
        
        for (ARMarkerView *marker in currentARMarkers)
		{
            // already exist, change status
            if([point.fbUserId isEqualToString:marker.userAnnotation.fbUserId])
			{
                if ([point.userStatus length] < 6 || ([point.userStatus length] >= 6 && ![[point.userStatus substringToIndex:6] isEqualToString:fbidIdentifier])){
                    ARMarkerView *marker = (ARMarkerView *)[arViewController viewForExistAnnotation:point];
                    [marker updateStatus:point.userStatus];// update status
                }
                
                break;
            }
        }
        
        [currentARMarkers release];
    }

}

#pragma mark -
#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)_mapView viewForAnnotation:(id < MKAnnotation >)annotation{
    
                        // if this is cluster 
    if ([annotation isKindOfClass:[OCAnnotation class]]) {

        OCAnnotation* clusterAnnotation = (OCAnnotation*) annotation;
        ClusterMarkerView* clusterView = (ClusterMarkerView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"ClusterView"];
        [clusterView retain];
        
        UserAnnotation* closest = (UserAnnotation*)[OCAlgorithms calculateClusterCenter:clusterAnnotation];
       
        if (!clusterView) {
            
            // find annotation which is closest to cluster center
            clusterView = [[ClusterMarkerView alloc] initWithAnnotation:closest reuseIdentifier:@"ClusterView"];
            [clusterView setCanShowCallout:YES];

            // if it is photo
            if (closest.photoId) {
                NSString* photoOwner = [closest findAndFriendNameForPhoto:closest];
                [clusterView.userName setText:photoOwner];
                [clusterView.userPhotoView loadImageFromURL:[NSURL URLWithString:closest.thumbnailURL]];
                [clusterView.userStatus setText:closest.locationName];
            }
            
                        
            UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToZoom:)];
            [clusterView addGestureRecognizer:tap];
            
            [tap release];
        }
        
        if (IS_IOS_6) {
            [clusterView setTransform:CGAffineTransformMakeRotation(0.001)];
            if(count){
                [clusterView setTransform:CGAffineTransformMakeRotation(-count)];
            }
        }
        else{
            double delayInSeconds = 0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
                [clusterView setTransform:CGAffineTransformMakeRotation(-count)];
            });
            
        }
        
        [clusterView updateAnnotation:closest];
        
        clusterView.clusterCenter = closest.coordinate;
        
        [clusterView setNumberOfAnnotations:clusterAnnotation.annotationsInCluster.count];
      
        return [clusterView autorelease];
    }
    
    else if([annotation isKindOfClass:[UserAnnotation class]])
    {
        UserAnnotation* ann = (UserAnnotation*)annotation;
                    // if this is photo annotation
        
        
        if (ann.photoId) {
            PhotoMarkerView* photoMarker = (PhotoMarkerView*)[_mapView dequeueReusableAnnotationViewWithIdentifier:@"photoView"];
            if (!photoMarker) {
                photoMarker = [[[PhotoMarkerView alloc] initWithAnnotation:ann reuseIdentifier:@"photoView"] autorelease];
            }
            else{
                [photoMarker updateAnnotation:ann];
            }
            [photoMarker setDelegate:self];
            return photoMarker;
        }
        else
        {
            MapMarkerView *marker = (MapMarkerView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:@"pinView"];
            if(marker == nil){
                marker = [[[MapMarkerView alloc] initWithAnnotation:annotation 
                                            reuseIdentifier:@"pinView"] autorelease];
            }else{
                [marker updateAnnotation:(UserAnnotation *)annotation];
            }
            
            // set touch action
            marker.target = self;
            marker.action = @selector(touchOnMarker:);

            if (IS_IOS_6) {
                [marker setTransform:CGAffineTransformMakeRotation(0.001)];
                if(count){
                    [marker setTransform:CGAffineTransformMakeRotation(-count)];
                }
            } else{
                double delayInSeconds = 0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^{
                    [marker setTransform:CGAffineTransformMakeRotation(-count)];
                });
            }
            return marker;
        }
    }
    
    return nil;
}

-(void)tapToZoom:(UITapGestureRecognizer*) tap{
    
    ClusterMarkerView* clusterView = (ClusterMarkerView*)[tap view];
    MKCoordinateRegion region = self.mapView.region;

    region.span.longitudeDelta = self.mapView.region.span.longitudeDelta/4;
    region.span.latitudeDelta = self.mapView.region.span.latitudeDelta/4;
    
    CLLocationCoordinate2D location = clusterView.clusterCenter;
    region.center.latitude = location.latitude;
    region.center.longitude = location.longitude;
    
    region = [self.mapView regionThatFits:region];

    [self.mapView setRegion:region animated:YES];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
    float longitudeDeltaZoomOut = 255.0f;
    float longitudeDeltaZoomIn  = 353.671875f;
    
    float zoomOun = 0.38f;
    float zoomIn  = 0.43f;
    
    if(IS_HEIGHT_GTE_568){
        longitudeDeltaZoomOut = 112.5;
        longitudeDeltaZoomIn  = 180.0f;
    }
    
    if( ((self.mapView.region.span.longitudeDelta / longitudeDeltaZoomOut) < zoomOun) && !canRotate ){
        
        [self.mapView setFrame:mapFrameZoomIn];
        canRotate = YES;
        
        [self.compass setAlpha:1.0f];
    }
        
    
    // rotate map to init state
    if(((self.mapView.region.span.longitudeDelta / longitudeDeltaZoomIn) > zoomIn) && canRotate){
        
        [self.compass setAlpha:0.0f];
        
        count = 0;
        
        double delayInSeconds = 0.3;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [self.mapView setFrame:mapFrameZoomOut];
            canRotate = NO;
        });
        
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [self.mapView setTransform:CGAffineTransformMakeRotation(count)];
                             [self.compass setTransform:CGAffineTransformMakeRotation(count)];
                             [self rotateAnnotations:(count)];
                         }
         ];
    }
               
    [self.mapView doClustering];
    
}



#pragma mark -
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    
    return YES;
}

#pragma mark -
#pragma mark Photo Annotation Displaying Methods
-(void)showPhoto:(AsyncImageView*)photo{
    [photo loadImageFromURL:photo.linkedUrl];
    photo.center = self.view.center;
    [photo setTag:2008];

    UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setFrame:CGRectMake(photo.frame.size.width-18, -6, 29, 29)];
    [closeButton addTarget:self action:@selector(closeView) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setImage:[UIImage imageNamed:@"FBDialog.bundle/images/close.png"] forState:UIControlStateNormal];
    [photo bringSubviewToFront:closeButton];

    [self.view setUserInteractionEnabled:YES];
    [self.view bringSubviewToFront:photo];
    [photo addSubview:closeButton];
    [photo bringSubviewToFront:closeButton];
    
    [self.view addSubview:photo];
}

-(void)closeView{
    [[self.view viewWithTag:2008] removeFromSuperview];
}

#pragma mark -
#pragma mark Notifications Reaction

-(void)doClearCache{
    [self mapClear];
    [self.allFriendsSwitch setValue:1.0f];
}

- (void)logoutDone{
    showAllUsers  = NO;
    
    [self.allFriendsSwitch setValue:1.0f];
    
    [self clear];
}

-(void)doMapNotReceiveNewFBMapUsers{
    [(UIActivityIndicatorView*)([self.view viewWithTag:INDICATOR_TAG]) removeFromSuperview];
    if ([self.allFriendsSwitch value] == friendsValue) {
        [self showFriends];
    }
    else
        [self showWorld];
    [DataManager shared].currentRequestingDataControllerTitle = @"";
}

-(void)doWillSetAllFriendsSwitchEnabled:(NSNotification*)notification{
    BOOL enabled = [[[notification userInfo] objectForKey:@"switchEnabled"] boolValue];
    [self.allFriendsSwitch setEnabled:enabled];
}



-(void)doMapEndRetrievingData{
    [(UIActivityIndicatorView*)([self.view viewWithTag:INDICATOR_TAG]) removeFromSuperview];
   
    
    [self.allFriendsSwitch setEnabled:YES];
    
    [self refreshWithNewPoints:[DataManager shared].mapPoints];
    
    [DataManager shared].currentRequestingDataControllerTitle = @"";
}

-(void)doAddNewPoint:(NSNotification*)notification{
    UserAnnotation* newPoint = (UserAnnotation*)[notification.userInfo objectForKey:@"newPoint"];
    BOOL isFBCheckin = [[notification.userInfo objectForKey:@"isFBCheckin"] boolValue];
    
    NSArray *friendsIds = [[DataManager shared].myFriendsAsDictionary allKeys];

    NSArray *currentMapAnnotations = [self.mapView.annotations copy];

    BOOL isExistPoint = NO;
    for (UserAnnotation *annotation in currentMapAnnotations)
    {
        NSDate *newCreateDateTime = newPoint.createdAt;
        NSDate *currentCreateDateTime = annotation.createdAt;
        // already exist, change status
        if([newPoint.fbUserId isEqualToString:annotation.fbUserId])
        {
            if([newCreateDateTime compare:currentCreateDateTime] == NSOrderedDescending){
                if ([newPoint.userStatus length] < 6 || ([newPoint.userStatus length] >= 6 && ![[newPoint.userStatus substringToIndex:6] isEqualToString:fbidIdentifier])){
                    MapMarkerView *marker = (MapMarkerView *)[self.mapView viewForAnnotation:annotation];
                    [marker updateStatus:newPoint.userStatus];// update status
                    [marker updateCoordinate:newPoint.coordinate];
                }
            }

            isExistPoint = YES;

            break;
        }
    }

    [currentMapAnnotations release];
    
    if(isExistPoint){
        
        NSArray *currentARMarkers = [[DataManager shared].coordinateViews copy];
        
        for (ARMarkerView *marker in currentARMarkers)
		{
            NSDate *newCreateDateTime = newPoint.createdAt;
            NSDate *currentCreateDateTime = marker.userAnnotation.createdAt;
            // already exist, change status
            if([newPoint.fbUserId isEqualToString:marker.userAnnotation.fbUserId])
			{
                if([newCreateDateTime compare:currentCreateDateTime] == NSOrderedDescending){
                    AugmentedRealityController* ARController = nil;
                    if ([newPoint.userStatus length] < 6 ||
                        ([newPoint.userStatus length] >= 6 &&
                         ![[newPoint.userStatus substringToIndex:6] isEqualToString:fbidIdentifier])){

                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        UITabBarController *tabBarController = appDelegate.tabBarController;
                            // find needed ARController
                            
                        for (UIViewController* viewController in tabBarController.viewControllers) {
                            UIViewController *vc = viewController;
                            if ([viewController isKindOfClass:[UINavigationController class]]) {
                                vc = [(UINavigationController*)viewController visibleViewController];
                            }
                            if ([vc isKindOfClass:[AugmentedRealityController class]]) {
                                ARController = (AugmentedRealityController*)vc;
                            }
                        }
                            
                        ARMarkerView *marker = (ARMarkerView *)[ARController viewForExistAnnotation:newPoint];
                        [marker updateStatus:newPoint.userStatus];// update status
                        [marker updateCoordinate:newPoint.coordinate]; // update location
                    }
                }
                
                isExistPoint = YES;
                
                break;
            }
        }
        
        [currentARMarkers release];
    }

    if(!isExistPoint){
        BOOL addedToCurrentMapState = NO;

        
        [[DataManager shared].allmapPoints addObject:newPoint];
        
        if(newPoint.geoDataID != -1){
            [[DataManager shared].mapPointsIDs addObject:[NSString stringWithFormat:@"%d", newPoint.geoDataID]];
        }

        if([self isAllShowed] || [friendsIds containsObject:newPoint.fbUserId]){
            [[DataManager shared].mapPoints addObject:newPoint];

            addedToCurrentMapState = YES;
        }

        if(addedToCurrentMapState){
            [self addPoint:newPoint];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            UITabBarController *tabBarController = appDelegate.tabBarController;
            // find needed ARController
            AugmentedRealityController* ARController = nil;
            for (UIViewController* viewController in tabBarController.viewControllers) {
                UIViewController *vc = viewController;
                if ([viewController isKindOfClass:[UINavigationController class]]) {
                    vc = [(UINavigationController*)viewController visibleViewController];
                }
                if ([vc isKindOfClass:[AugmentedRealityController class]]) {
                    ARController = (AugmentedRealityController*)vc;
                }
            }
            [ARController addPoint:newPoint];
        }
    }

    if(!isFBCheckin){
        [[DataManager shared] addMapARPointToStorage:newPoint];
    }
}

-(void)doUpdatePointStatus:(NSNotification*)notification{
    UserAnnotation* newPoint = (UserAnnotation*)[notification.userInfo objectForKey:@"newPointStatus"];
    [self updateStatus:newPoint];
}

- (BOOL)isAllShowed{
    if(self.allFriendsSwitch.value >= worldValue){
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    int buttonsNum = actionSheet.numberOfButtons;
    
    switch (buttonIndex) {
        case 0:{
            
            [self.view bringSubviewToFront:self.allFriendsSwitch];
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            

            UITabBarController *tabBarController = appDelegate.tabBarController;
            ChatViewController* chatController = nil;
            for (UIViewController* viewController in tabBarController.viewControllers) {
                UIViewController *vc = viewController;
                if ([viewController isKindOfClass:[UINavigationController class]]) {
                    vc = [(UINavigationController*)viewController visibleViewController];
                }
                if ([vc isKindOfClass:[ChatViewController class]]) {
                    chatController = (ChatViewController*)vc;
                }
            }
            [chatController setSelectedUserAnnotation:self.selectedUserAnnotation];
            [chatController addQuote];
            [chatController.messageField becomeFirstResponder];
            
            [tabBarController setSelectedIndex:chatIndex];
            
        }
            
            break;
            
        case 1: {
            if(buttonsNum == 3){
                // View personal FB page
                [self actionSheetViewFBProfile];
            }else{
                // Send FB message
                [self actionSheetSendPrivateFBMessage];
            }
        }
            break;
            
        case 2: {
            // View personal FB page
            if(buttonsNum != 3){
                [self actionSheetViewFBProfile];
            }
        }
			
            break;
            
        default:
            break;
    }
    
    [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
}



#pragma mark - 
#pragma mark Markers
- (void)touchOnMarker:(UIView *)marker{
    // get user name & id
    NSString *userName = nil;
    if([marker isKindOfClass:MapMarkerView.class]){ 
        userName = ((MapMarkerView *)marker).userName.text;
        self.selectedUserAnnotation = ((MapMarkerView *)marker).annotation;
    }
	NSString* title;
	NSString* subTitle;
	
	title = userName;
	if ([self.selectedUserAnnotation.userStatus length] >=6)
	{
		if ([[self.selectedUserAnnotation.userStatus substringToIndex:6] isEqualToString:fbidIdentifier])
		{
			subTitle = [self.selectedUserAnnotation.userStatus substringFromIndex:[self.selectedUserAnnotation.userStatus rangeOfString:quoteDelimiter].location+1];
		}
		else
		{
			subTitle = self.selectedUserAnnotation.userStatus;
		}
	}
	else
	{
		subTitle = self.selectedUserAnnotation.userStatus;
	}
	
	subTitle = [NSString stringWithFormat:@"''%@''", subTitle];
    
    // show action sheet
    [self showActionSheetWithTitle:title andSubtitle:subTitle];
}

@end
