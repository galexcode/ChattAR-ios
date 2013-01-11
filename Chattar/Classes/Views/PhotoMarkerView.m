//
//  PhotoMarkerView.m
//  Chattar
//
//  Created by kirill on 1/9/13.
//
//

#import "PhotoMarkerView.h"

@implementation PhotoMarkerView

-(id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        
        if ([annotation isKindOfClass:[UserAnnotation class]]) {
            UserAnnotation* ann = (UserAnnotation*)annotation;            
            // get friend name
            NSLog(@"%@",ann.ownerId);
                                                // find friend
            [self findFriendName:ann];
        
            [self.userStatus setText:ann.locationName];
            
            [self.userPhotoView loadImageFromURL:[NSURL URLWithString:ann.thumbnailURL]];
        }
    }
    return self;
}

-(void)closeView{
    [fullPhoto removeFromSuperview];
}

-(void)dealloc{
    [thumbnailPhoto release];
    [fullPhoto release];
    [super dealloc];
}

-(void)updateAnnotation:(UserAnnotation *)_annotation{
    if (![_annotation.photoId isEqualToString:self.annotation.photoId]) {
        [self.userStatus setText:_annotation.locationName];
        [self findFriendName:_annotation];
        [self.userPhotoView loadImageFromURL:[NSURL URLWithString:_annotation.thumbnailURL]];
    }
}

-(void)findFriendName:(UserAnnotation*)ann{
    for (NSDictionary* friendInfo in [[DataManager shared] myFriends]) {
        NSDecimalNumber* friendId = [friendInfo objectForKey:kId];
        if (fabs(friendId.doubleValue - ann.ownerId.doubleValue) < 0.00001) {
            NSMutableString* friendFullName = [[NSMutableString alloc] init];
            [friendFullName appendString:[friendInfo objectForKey:@"first_name"]];
            [friendFullName appendString:@" "];
            [friendFullName appendString:[friendInfo objectForKey:@"last_name"]];
            
            [self.userName setText:friendFullName];
            [friendFullName release];
            break;
        }
    }

}

#pragma mark -
#pragma mark UIGestureRecognizer delegate methods
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
@end
