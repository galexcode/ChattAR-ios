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
#import "CommonViewController.h"
#import "BackgroundWorker.h"

@protocol FBDataDelegate;
@interface MapViewController : CommonViewController <MKMapViewDelegate, UIGestureRecognizerDelegate,PhotoMarkerProtocol,
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
                                                     
    BOOL isDataRetrieved;
                                                     
    BOOL isViewLoaded;
}

@property (nonatomic, assign) id delegate;
                                        // add custom map view with clusterization
@property (nonatomic, assign) OCMapView *mapView;
@property (nonatomic, retain) UIImageView *compass;

- (void)refreshWithNewPoints:(NSArray *)mapPoints;
- (void)addPoints:(NSArray *)mapPoints;
- (void)addPoint:(UserAnnotation *)mapPoint;
- (void)clear;

@end
