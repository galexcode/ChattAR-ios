//
//  MapViewController.h
//  ChattAR for Facebook
//
//  Created by QuickBlox developers on 3/27/12.
//  Copyright (c) 2012 QuickBlox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapMarkerView.h"
#import "CustomSwitch.h"
#import "OCMapView.h"
#import "OCAnnotation.h"
#import "ClusterMarkerView.h"
#import "PhotoMarkerView.h"

#import "BackgroundWorker.h"

@protocol FBDataDelegate;
@interface MapViewController : UIViewController <MKMapViewDelegate, UIGestureRecognizerDelegate,PhotoMarkerProtocol,
                                                 FBDataDelegate, MapControllerDelegate,  DataDelegate,UIActionSheetDelegate>{
    CGFloat count;
    CGFloat lastCount;
    
    CGRect mapFrameZoomOut;
    CGRect mapFrameZoomIn;
    
    BOOL canRotate;
    int annotationsViewCount;
    
    MKCoordinateRegion initialRegion;
    
    NSMutableArray* annotationsForClustering;
    MKMapRect previousRect;
    BOOL showAllUsers;
                                                     
    BOOL isDataRetrieved;
                                                     
    BOOL isViewLoaded;
}

@property (nonatomic, assign) id delegate;
@property (retain, nonatomic) UIActivityIndicatorView *loadingIndicator;
                                        // add custom map view with clusterization
@property (nonatomic, assign) OCMapView *mapView;
@property (nonatomic, retain) UIImageView *compass;
@property (assign) NSMutableArray *mapPoints;
@property (assign) NSMutableArray *mapPointsIDs;
@property (nonatomic, assign) CustomSwitch *allFriendsSwitch;
@property (nonatomic, retain) NSMutableArray* allCheckins;
@property (nonatomic, retain) UIActionSheet *userActionSheet;
@property (retain) UserAnnotation *selectedUserAnnotation;

- (void)refreshWithNewPoints:(NSArray *)mapPoints;
- (void)addPoints:(NSArray *)mapPoints;
- (void)addPoint:(UserAnnotation *)mapPoint;
- (void)clear;

@end
