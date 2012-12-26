//
//  ClusterMarkerView.h
//  Chattar
//
//  Created by kirill on 12/7/12.
//
//

#import "MapMarkerView.h"
#import "OCAnnotation.h"
@interface ClusterMarkerView : MapMarkerView{
    UILabel* numberOfAnnotationsInCluster;
    UIImageView* backGround;
    UIImageView* numberMarker;
}

-(void)setNumberOfAnnotations:(NSInteger)numberOfAnnotations;

@property (nonatomic, assign) NSInteger numberOfAnnotations;
@property (nonatomic,assign) CLLocationCoordinate2D clusterCenter;
@end
