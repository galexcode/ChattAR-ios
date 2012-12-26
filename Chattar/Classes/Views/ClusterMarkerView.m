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
        
    [numberOfAnnotationsInCluster setText:[NSString stringWithFormat:@"%d",numberOfAnnotations]];
}

-(id)initWithAnnotation:(UserAnnotation*)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    NSLog(@"%@",annotation.userName);
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        numberMarker = [[UIImageView alloc] initWithFrame:CGRectMake(85, -15, NUMBER_MARKER_SIZE, NUMBER_MARKER_SIZE)];
        
        NSArray *friendsIds =  [[DataManager shared].myFriendsAsDictionary allKeys];
        
        backGround = [[UIImageView alloc] initWithFrame:CGRectMake(-10, -11, self.frame.size.width + 18, self.frame.size.height-40)];

                            // check for facebook clustering view
        if([friendsIds containsObject:[annotation.fbUser objectForKey:kId]]
           || [[DataManager shared].currentFBUserId isEqualToString:[annotation.fbUser objectForKey:kId]])
        {
            [numberMarker setImage:[UIImage imageNamed:@"numberOfFriendFBBg.png"]];
            [backGround setImage:[UIImage imageNamed:@"clusterBgFB.png"]];
        }
        else
        {
            [numberMarker setImage:[UIImage imageNamed:@"numberOfFriendBg.png"]];
            [backGround setImage:[UIImage imageNamed:@"clusterBg.png"]];

        }
        
        numberOfAnnotationsInCluster = [[UILabel alloc] initWithFrame:CGRectMake(9, 11, 17, 15)];
        [numberOfAnnotationsInCluster setBackgroundColor:[UIColor clearColor]];
        [numberOfAnnotationsInCluster setTextColor:[UIColor whiteColor]];
        [numberOfAnnotationsInCluster setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15]];
        [numberOfAnnotationsInCluster setTextAlignment:NSTextAlignmentCenter];
        [numberMarker addSubview:numberOfAnnotationsInCluster];
        
        
        [self addSubview:numberMarker];
        [self addSubview:backGround];
        [self sendSubviewToBack:backGround];
        [backGround release];

    }
    
    return self;
}

-(void)updateAnnotation:(UserAnnotation *)_annotation{
    [super updateAnnotation:_annotation];
    NSArray *friendsIds =  [[DataManager shared].myFriendsAsDictionary allKeys];

    if([friendsIds containsObject:[_annotation.fbUser objectForKey:kId]]
       || [[DataManager shared].currentFBUserId isEqualToString:[_annotation.fbUser objectForKey:kId]])
    {
        [numberMarker setImage:[UIImage imageNamed:@"numberOfFriendFBBg.png"]];
        [backGround setImage:[UIImage imageNamed:@"clusterBgFB.png"]];
    }
    else
    {
        [numberMarker setImage:[UIImage imageNamed:@"numberOfFriendBg.png"]];
        [backGround setImage:[UIImage imageNamed:@"clusterBg.png"]];
        
    }

}

-(void)dealloc{
    [numberMarker release];
    [backGround release];
    [numberOfAnnotationsInCluster release];
    [super dealloc];
}
@end
