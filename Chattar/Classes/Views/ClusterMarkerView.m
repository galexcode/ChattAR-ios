//
//  ClusterMarkerView.m
//  Chattar
//
//  Created by kirill on 12/7/12.
//
//

#import "ClusterMarkerView.h"

@implementation ClusterMarkerView

#define NUMBER_MARKER_SIZE 30

-(void)setNumberOfAnnotations:(NSInteger)numberOfAnnotations{
    NSString* number = [NSString stringWithFormat:@"%d",numberOfAnnotations];
    
    CGSize stringSize = [number sizeWithFont:numberOfAnnotationsInCluster.font];
    
    CGRect newFrame = numberOfAnnotationsInCluster.frame;
    newFrame.size = stringSize;
    
    [numberOfAnnotationsInCluster setFrame:newFrame];
    
    [numberOfAnnotationsInCluster setText:[NSString stringWithFormat:@"%d",numberOfAnnotations]];
}

-(id)initWithAnnotation:(UserAnnotation*)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView* numberMarker = [[UIImageView alloc] initWithFrame:CGRectMake(90, -10, NUMBER_MARKER_SIZE, NUMBER_MARKER_SIZE)];
        [numberMarker setImage:[UIImage imageNamed:@"numberOfFriendBg.png"]];
        
        numberOfAnnotationsInCluster = [[UILabel alloc] initWithFrame:CGRectMake(8, 5, 15, 15)];
        [numberOfAnnotationsInCluster setBackgroundColor:[UIColor clearColor]];
        [numberOfAnnotationsInCluster setTextColor:[UIColor whiteColor]];
        [numberOfAnnotationsInCluster setFont:[UIFont fontWithName:@"American Typewriter" size:15]];
        
        [numberMarker addSubview:numberOfAnnotationsInCluster];
        
        [self addSubview:numberMarker];
        [numberMarker release];
        
    }
    
    return self;
}

-(void)dealloc{
    [numberOfAnnotationsInCluster release];
    [super dealloc];
}
@end
