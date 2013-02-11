//
//  OCMapView.m
//  openClusterMapView
//
//  Created by Botond Kis on 14.07.11.
//

#import "OCMapView.h"

@interface OCMapView (private)
- (void)initSetUp;
@end

@implementation OCMapView
@synthesize clusteringEnabled;
@synthesize annotationsToIgnore;
@synthesize clusteringMethod;
@synthesize clusterSize;
@synthesize clusterByGroupTag;
@synthesize minLongitudeDeltaToCluster;

- (id)init
{
    self = [super init];
    if (self) {
        // call actual initializer
        [self initSetUp];
    }
    
    return self;
}

-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // call actual initializer
        [self initSetUp];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];    
    if (self) {
        // call actual initializer
        [self initSetUp];
    }
    return self;
}

- (void)initSetUp{
    allAnnotations = [[NSMutableSet alloc] init];
    annotationsToIgnore = [[NSMutableSet alloc] init];
    clusteringMethod = OCClusteringMethodBubble;
    clusterSize = 0.2;
    minLongitudeDeltaToCluster = 0;
    clusteringEnabled = YES;
    clusterByGroupTag = NO;
    backgroundClusterQueue = dispatch_queue_create("com.OCMapView.clustering", NULL);  
}

- (void)dealloc{
    [allAnnotations release];
    [annotationsToIgnore release];
    dispatch_release(backgroundClusterQueue);
    
    [super dealloc];
}

// ======================================
#pragma mark MKMapView implementation

- (void)addAnnotation:(id < MKAnnotation >)annotation{
    [allAnnotations addObject:annotation];
    [self doClustering];
}

- (void)addAnnotations:(NSArray *)annotations{
    [allAnnotations addObjectsFromArray:annotations];
    [self doClustering];
}

- (void)removeAnnotation:(id < MKAnnotation >)annotation{
    [allAnnotations removeObject:annotation];
    [self doClustering];
}

- (void)removeAnnotations:(NSArray *)annotations{
    [annotations retain];
    for (id<MKAnnotation> annotation in annotations) {
        [allAnnotations removeObject:annotation];
    }
    [annotations release];
    [self doClustering];
}


// ======================================
#pragma mark - Properties
//
// Returns, like the original method,
// all annotations in the map unclustered.
- (NSArray *)annotations{
    return [allAnnotations allObjects];
}

//
// Returns all annotations which are actually displayed on the map. (clusters)
- (NSArray *)displayedAnnotations{
    return super.annotations;    
}

//
// enable or disable clustering
- (void)setClusteringEnabled:(BOOL)enabled{
    clusteringEnabled = enabled;
    [self doClustering];
}
// ======================================
#pragma mark - Clustering
- (void)doClustering{
    
    // Remove the annotation which should be ignored
    NSMutableArray *bufferArray = [[NSMutableArray alloc] initWithArray:[allAnnotations allObjects]];
    [bufferArray removeObjectsInArray:[annotationsToIgnore allObjects]];
    
                                                    // cluster only visible annotations
    NSMutableArray *annotationsToCluster = [[NSMutableArray alloc] initWithArray:[self filterAnnotationsForVisibleMap:bufferArray]];
    [bufferArray release];
    
    MKZoomScale currentZoomScale = self.bounds.size.width / self.visibleMapRect.size.width;
    
    //calculate cluster radius
    CLLocationDistance clusterRadius = self.region.span.longitudeDelta * clusterSize;
    
    
                // if zoom level is enough for displaying all annotations
    if (fabs(currentZoomScale - (IS_IOS_6 ? MAX_ZOOM_LEVEL_IOS6 : MAX_ZOOM_LEVEL) ) <= EPSILON  || currentZoomScale > (IS_IOS_6 ? MAX_ZOOM_LEVEL_IOS6 : MAX_ZOOM_LEVEL)) {
        clusteringEnabled = NO;
    }
    else{
        clusteringEnabled = YES;
    }
    
    NSArray* clusteredAnnotations;
    
    
    // Check if clustering is enabled and map is above the minZoom
    if (clusteringEnabled && (self.region.span.longitudeDelta > minLongitudeDeltaToCluster)) {
        
        // fill newClusters
        
        switch (clusteringMethod) {
            case OCClusteringMethodBubble:{
                clusteredAnnotations = [[NSArray alloc] initWithArray:[OCAlgorithms bubbleClusteringWithAnnotations:annotationsToCluster andClusterRadius:clusterRadius grouped:self.clusterByGroupTag]];

                break;
            }
            case OCClusteringMethodGrid:{                
                clusteredAnnotations =[[NSArray alloc] initWithArray:[OCAlgorithms gridClusteringWithAnnotations:annotationsToCluster andClusterRect:MKCoordinateSpanMake(clusterRadius, clusterRadius)  grouped:self.clusterByGroupTag]];

                break;
            }
            default:{
                clusteredAnnotations = [annotationsToCluster retain];
                break;
            }
        }
    
        if ([super annotations].count != 0) {
            for (OCAnnotation* cluster in clusteredAnnotations) {
                int originalAnnNumer = 0;
                
                for (id<MKAnnotation> ann in self.displayedAnnotations) {

                    if (![self isAnnotation:cluster equalToAnotherAnnotation:ann]) {
                        originalAnnNumer++;
                    }
                }
                // if there is no equal to cluster annotation add it to map
                if (originalAnnNumer == self.displayedAnnotations.count) {
                    [super addAnnotation:cluster];
                }
            }
        }
        
        
        else{
            [super addAnnotations:clusteredAnnotations];
        }
        
        [super removeAnnotation:self.userLocation];
        
        
        // fix for flickering
        NSMutableArray *annotationsToRemove = [[NSMutableArray alloc] initWithArray:self.displayedAnnotations];
        [annotationsToRemove removeObject:self.userLocation];
        
        NSMutableArray* tmp = [[NSMutableArray alloc] init];
        
        
        for (id<MKAnnotation> ann in annotationsToRemove) {
            for (OCAnnotation* cluster in clusteredAnnotations) {
                if ([self isAnnotation:cluster equalToAnotherAnnotation:ann] ) {
                    [tmp addObject:ann];
                }
            }
        }
        
        [annotationsToRemove removeObjectsInArray: tmp];
        [tmp release];
        [clusteredAnnotations release];
        
        [super removeAnnotations:annotationsToRemove];
        [annotationsToRemove release];
        
        // add ignored annotations
        [super addAnnotations: [annotationsToIgnore allObjects]];
    }
    
    else{
        if (self.displayedAnnotations.lastObject) {
            [super removeAnnotation:self.displayedAnnotations.lastObject];
        }
        [super addAnnotations:annotationsToCluster];
    }
    
    [annotationsToCluster release];
    
}

// ======================================
#pragma mark - Helpers

- (NSArray *)filterAnnotationsForVisibleMap:(NSArray *)annotationsToFilter{
    // return array
    NSMutableArray *filteredAnnotations = [[NSMutableArray alloc] initWithCapacity:[annotationsToFilter count]];
    
    // border calculation
    CLLocationDistance a = self.region.span.latitudeDelta/2.0;
    CLLocationDistance b = self.region.span.longitudeDelta /2.0;
    CLLocationDistance radius = sqrt(a*a + b*b);
    
    for (id<MKAnnotation> annotation in annotationsToFilter) {
        // if annotation is not inside the coordinates, kick it
        if (isLocationNearToOtherLocation(annotation.coordinate, self.centerCoordinate, radius)) {
            [filteredAnnotations addObject:annotation];
        }
    }
    
    return [filteredAnnotations autorelease];
}

-(BOOL)isAnnotation:(id<MKAnnotation>)annotation equalToAnotherAnnotation:(id<MKAnnotation>) anotherAnnotation{
    if ( fabs(annotation.coordinate.longitude - anotherAnnotation.coordinate.longitude) < EPSILON &&
         fabs(annotation.coordinate.latitude - anotherAnnotation.coordinate.latitude) < EPSILON ) {
        return YES;
    }
    return NO;
}

@end
