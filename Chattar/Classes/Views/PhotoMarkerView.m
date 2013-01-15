//
//  PhotoMarkerView.m
//  Chattar
//
//  Created by kirill on 1/9/13.
//
//

#import "PhotoMarkerView.h"

@implementation PhotoMarkerView
@synthesize delegate;
-(id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        
        if ([annotation isKindOfClass:[UserAnnotation class]]) {
            UserAnnotation* ann = (UserAnnotation*)annotation;            
            [self setFrame:CGRectMake(0, 0, 50, 55)];
            thumbnailPhoto = [[AsyncImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 55)];
            [thumbnailPhoto loadImageFromURL:[NSURL URLWithString:ann.thumbnailURL]];
            [self addSubview:thumbnailPhoto];
            
            UIImageView *arrow = [[UIImageView alloc] init];
            [arrow setImage:[UIImage imageNamed:@"radarMarkerArrow@2x.png"]];
            [arrow setFrame:CGRectMake(thumbnailPhoto.frame.size.width/2-6,thumbnailPhoto.frame.size.height-1, 10, 9)];
            [self addSubview:arrow];
            [arrow release];
            
            fullPhoto = [[AsyncImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 110)];
            [fullPhoto setLinkedUrl:[NSURL URLWithString:ann.fullImageURL]];
            

            
            UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFullPhoto)];
            [self setUserInteractionEnabled:YES];
            [self addGestureRecognizer:tap];
            [tap release];
        }
    }
    return self;
}

-(void)closeView{
    [fullPhoto removeFromSuperview];
}
-(void)showFullPhoto{
    if ([delegate respondsToSelector:@selector(showPhoto:)]) {
        [delegate showPhoto:fullPhoto];
    }
}

-(void)dealloc{
    [thumbnailPhoto release];
    [fullPhoto release];
    [delegate release];
    [super dealloc];
}

-(void)updateAnnotation:(UserAnnotation *)_annotation{
}


#pragma mark -
#pragma mark UIGestureRecognizer delegate methods
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
@end
