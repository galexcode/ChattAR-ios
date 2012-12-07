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
}

-(void)setNumberOfAnnotations:(NSInteger)numberOfAnnotations;

@property (nonatomic, assign) NSInteger numberOfAnnotations;
@end
