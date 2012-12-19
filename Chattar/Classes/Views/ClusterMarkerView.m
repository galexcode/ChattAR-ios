//
//  ClusterMarkerView.m
//  Chattar
//
//  Created by kirill on 12/7/12.
//
//

#import "ClusterMarkerView.h"

@implementation ClusterMarkerView

#define NUMBER_MARKER_SIZE 35
@synthesize numberOfAnnotations = _numberOfAnnotations;
@synthesize clusterCenter = _clusterCenter;

-(void)setNumberOfAnnotations:(NSInteger)numberOfAnnotations{
    _numberOfAnnotations = numberOfAnnotations;
    
//    NSString* number = [NSString stringWithFormat:@"%d",numberOfAnnotations];
    
//    CGSize stringSize = [number sizeWithFont:numberOfAnnotationsInCluster.font];
//    
//    CGRect newFrame = numberOfAnnotationsInCluster.frame;
//    newFrame.size = stringSize;
//    
//    [numberOfAnnotationsInCluster setFrame:newFrame];
    
    [numberOfAnnotationsInCluster setText:[NSString stringWithFormat:@"%d",numberOfAnnotations]];
}

-(id)initWithAnnotation:(UserAnnotation*)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImageView* numberMarker = [[UIImageView alloc] initWithFrame:CGRectMake(80, -10, NUMBER_MARKER_SIZE, NUMBER_MARKER_SIZE)];
        
        NSArray *friendsIds =  [[DataManager shared].myFriendsAsDictionary allKeys];
        
        
                            // check for facebook clustering view
        if([friendsIds containsObject:[annotation.fbUser objectForKey:kId]]
           || [[DataManager shared].currentFBUserId isEqualToString:[annotation.fbUser objectForKey:kId]])
        {
            [numberMarker setImage:[UIImage imageNamed:@"numberOfFriendFBBg.png"]];

        }
        else
        {
            [numberMarker setImage:[UIImage imageNamed:@"numberOfFriendBg.png"]];
        }

        
        
        numberOfAnnotationsInCluster = [[UILabel alloc] initWithFrame:CGRectMake(9, 10, 17, 15)];
        [numberOfAnnotationsInCluster setBackgroundColor:[UIColor clearColor]];
        [numberOfAnnotationsInCluster setTextColor:[UIColor whiteColor]];
        [numberOfAnnotationsInCluster setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15]];
        [numberOfAnnotationsInCluster setTextAlignment:NSTextAlignmentCenter];
        [numberMarker addSubview:numberOfAnnotationsInCluster];
        
        UIImageView* backGround = [[UIImageView alloc] initWithFrame:CGRectMake(-20, -20, self.frame.size.width + 30, self.frame.size.height-35)];
        [backGround setImage:[UIImage imageNamed:@"clusterBg.png"]];
        
        [self addSubview:numberMarker];
        [self addSubview:backGround];
        [self sendSubviewToBack:backGround];
        [backGround release];
        [numberMarker release];

    }
    
    return self;
}

-(void)dealloc{
    [numberOfAnnotationsInCluster release];
    [super dealloc];
}
@end
